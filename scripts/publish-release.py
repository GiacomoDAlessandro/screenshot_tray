#!/usr/bin/env python3
"""Publish verified installer artifacts using existing Git credentials; never stores tokens."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

REPOSITORY = "GiacomoDAlessandro/screenshot_tray"
API = f"https://api.github.com/repos/{REPOSITORY}"
ARTIFACTS = {
    "Screenshot-Tray.dmg": "application/x-apple-diskimage",
    "Screenshot-Tray.zip": "application/zip",
    "SHA256SUMS": "text/plain",
}


def verify_tag_target(reference, expected_sha, load_tag):
    if reference is None:
        return
    target = reference["object"]
    visited = set()
    while target["type"] == "tag":
        if target["sha"] in visited or len(visited) >= 10:
            raise RuntimeError("Cannot safely resolve the existing annotated tag")
        visited.add(target["sha"])
        target = load_tag(target["sha"])["object"]
    if target["type"] != "commit" or target["sha"] != expected_sha:
        raise RuntimeError("The existing version tag points to a different source commit")


def verify_assets(assets, files):
    by_name = {asset["name"]: asset for asset in assets}
    if set(by_name) != set(files) or len(assets) != len(files):
        raise RuntimeError("Draft contains missing, duplicate, or unexpected assets; it will not be published")
    for name, data in files.items():
        asset = by_name[name]
        digest = "sha256:" + hashlib.sha256(data).hexdigest()
        if asset.get("size") != len(data) or asset.get("digest") != digest or asset.get("state") != "uploaded":
            raise RuntimeError(f"Uploaded asset verification failed: {name}; draft kept unpublished")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--notes", type=Path, required=True)
    parser.add_argument("--publish", action="store_true", help="Publish after all uploaded hashes verify; otherwise leave a draft")
    args = parser.parse_args()
    os.chdir(Path(__file__).resolve().parent.parent)
    if not re.fullmatch(r"v[0-9]+(?:\.[0-9]+){1,2}", args.tag):
        raise RuntimeError("Use a numeric version tag such as v1.2")
    if not re.fullmatch(r"[0-9a-f]{40}", args.commit):
        raise RuntimeError("An exact full commit SHA is required")
    if subprocess.check_output(["git", "status", "--porcelain"], text=True).strip():
        raise RuntimeError("Commit the release source and documentation first")
    if subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip() != args.commit:
        raise RuntimeError("Release commit must match this checkout")
    notes = args.notes.read_text()
    files = {name: (Path("dist") / name).read_bytes() for name in ARTIFACTS}
    hashes = {name: "sha256:" + hashlib.sha256(data).hexdigest() for name, data in files.items()}
    expected_manifest = "".join(f"{hashes[name][7:]}  {name}\n" for name in list(ARTIFACTS)[:2])
    if files["SHA256SUMS"].decode() != expected_manifest:
        raise RuntimeError("SHA256SUMS does not match the packages")

    credential = subprocess.run(["git", "credential", "fill"],
        input="protocol=https\nhost=github.com\n\n", text=True, capture_output=True,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"}, check=True)
    values = dict(line.split("=", 1) for line in credential.stdout.splitlines() if "=" in line)
    token = values.get("password")
    if not token:
        raise RuntimeError("No existing GitHub Git credential is available")

    def request(url, method="GET", data=None, content_type=None, allow_missing=False):
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "https" or parsed.hostname not in {"api.github.com", "uploads.github.com"}:
            raise RuntimeError("Refusing to send credentials to an unexpected host")
        if isinstance(data, dict):
            data = json.dumps(data).encode()
            content_type = "application/json"
        headers = {"Accept": "application/vnd.github+json", "User-Agent": "Screenshot-Tray-release",
                   "X-GitHub-Api-Version": "2026-03-10"}
        if content_type:
            headers["Content-Type"] = content_type
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        # Never forward the credential if GitHub redirects to another host.
        req.add_unredirected_header("Authorization", "Bearer " + token)
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if allow_missing and error.code == 404:
                return None
            raise RuntimeError(f"GitHub {method} request failed with HTTP {error.code}") from None

    repo = request(API)
    if repo["private"] or not repo.get("permissions", {}).get("push"):
        raise RuntimeError("Expected the existing public repository with push access; permissions will not be changed")
    request(API + "/commits/" + args.commit)  # Must already exist on GitHub.
    tag_url = API + "/git/ref/tags/" + urllib.parse.quote(args.tag, safe="")
    load_tag = lambda sha: request(API + "/git/tags/" + sha)
    verify_tag_target(request(tag_url, allow_missing=True), args.commit, load_tag)
    releases = request(API + "/releases?per_page=100")
    release = next((item for item in releases if item["tag_name"] == args.tag), None)
    if release and (not release["draft"] or release["target_commitish"] != args.commit):
        raise RuntimeError("An existing published or different-source release will not be overwritten")
    if release is None:
        release = request(API + "/releases", "POST", {
            "tag_name": args.tag, "target_commitish": args.commit,
            "name": "Screenshot Tray " + args.tag[1:], "body": notes,
            "draft": True, "prerelease": False,
        })
    release_url = API + "/releases/" + str(release["id"])
    assets = {item["name"]: item for item in request(release_url + "/assets")}
    if set(assets) - set(ARTIFACTS):
        raise RuntimeError("Draft contains unexpected assets; it will not be published")
    for name, content_type in ARTIFACTS.items():
        asset = assets.get(name)
        if asset is None:
            upload = release["upload_url"].split("{", 1)[0]
            asset = request(upload + "?" + urllib.parse.urlencode({"name": name}),
                            "POST", files[name], content_type)
        if asset.get("size") != len(files[name]) or asset.get("digest") != hashes[name] or asset.get("state") != "uploaded":
            raise RuntimeError(f"Uploaded asset verification failed: {name}; draft kept unpublished")
        print("Verified uploaded asset:", name, hashes[name])
    verify_assets(request(release_url + "/assets"), files)
    verify_tag_target(request(tag_url, allow_missing=True), args.commit, load_tag)
    if args.publish:
        release = request(release_url, "PATCH", {"draft": False, "body": notes, "make_latest": "true"})
        print("Published:", release["html_url"])
    else:
        print("Draft prepared:", release["html_url"])


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        # Avoid dumping subprocess stdout or request headers, which can contain credentials.
        print("Release stopped:", str(error), file=sys.stderr)
        sys.exit(1)
