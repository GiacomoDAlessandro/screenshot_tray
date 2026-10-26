import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("publish_release", Path(__file__).parents[1] / "publish-release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseValidationTests(unittest.TestCase):
    def test_rejects_existing_tag_at_different_commit(self):
        with self.assertRaises(RuntimeError):
            release.verify_tag_target({"object": {"type": "commit", "sha": "old"}}, "new", lambda _: None)

    def test_peels_annotated_tag_and_checks_commit(self):
        reference = {"object": {"type": "tag", "sha": "annotation"}}
        loaded = {"object": {"type": "commit", "sha": "expected"}}
        release.verify_tag_target(reference, "expected", lambda _: loaded)
        with self.assertRaises(RuntimeError):
            release.verify_tag_target(reference, "other", lambda _: loaded)

    def test_rejects_tag_cycle(self):
        reference = {"object": {"type": "tag", "sha": "cycle"}}
        with self.assertRaises(RuntimeError):
            release.verify_tag_target(reference, "expected", lambda _: reference)

    def test_rejects_unexpected_draft_assets(self):
        with self.assertRaises(RuntimeError):
            release.verify_assets([{"name": "personal-settings.json"}], {"Screenshot-Tray.dmg": b"abc"})

    def test_checks_uploaded_digest_size_and_state(self):
        asset = {"name": "Screenshot-Tray.dmg", "size": 3, "state": "uploaded",
                 "digest": "sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"}
        release.verify_assets([asset], {"Screenshot-Tray.dmg": b"abc"})
        for change in [{"digest": "wrong"}, {"size": 5}, {"state": "starter"}]:
            with self.assertRaises(RuntimeError):
                release.verify_assets([{**asset, **change}], {"Screenshot-Tray.dmg": b"abc"})

    def test_rejects_missing_asset(self):
        with self.assertRaises(RuntimeError):
            release.verify_assets([], {"Screenshot-Tray.dmg": b"abc"})


if __name__ == "__main__":
    unittest.main()
