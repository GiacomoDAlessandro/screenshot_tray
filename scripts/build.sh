#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project ScreenshotTray.xcodeproj -scheme ScreenshotTray \
  -configuration Release -derivedDataPath build/DerivedData \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" build
mkdir -p dist
ditto "build/DerivedData/Build/Products/Release/Screenshot Tray.app" "dist/Screenshot Tray.app"
codesign --verify --deep --strict --verbose=2 "dist/Screenshot Tray.app"
echo "Standalone app: $PWD/dist/Screenshot Tray.app"
