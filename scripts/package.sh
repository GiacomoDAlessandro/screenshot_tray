#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Package only a verified standalone build, never the workspace or user settings.
app="$PWD/dist/Screenshot Tray.app"
codesign --verify --deep --strict "$app"
lipo "$app/Contents/MacOS/Screenshot Tray" -verify_arch arm64
lipo "$app/Contents/MacOS/Screenshot Tray" -verify_arch x86_64
mkdir -p build dist
stage=$(mktemp -d "$PWD/build/dmg-staging.XXXXXX")
ditto "$app" "$stage/Screenshot Tray.app"
ln -s /Applications "$stage/Applications"
cp docs/INSTALL.txt "$stage/Start Here.txt"

hdiutil create -volname "Screenshot Tray" -fs HFS+ -srcfolder "$stage" \
  -format UDZO -ov "$PWD/dist/Screenshot-Tray.dmg"
ditto -c -k --sequesterRsrc --keepParent "$app" "$PWD/dist/Screenshot-Tray.zip"
(
  cd dist
  shasum -a 256 Screenshot-Tray.dmg Screenshot-Tray.zip > SHA256SUMS
)
echo "Download artifacts: $PWD/dist/Screenshot-Tray.dmg, Screenshot-Tray.zip, SHA256SUMS"
