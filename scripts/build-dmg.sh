#!/bin/bash
# Build a Release RealNotch.app and package it into a drag-to-install DMG.
# Requires: Xcode, create-dmg (brew install create-dmg).
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${1:-0.1.0}"
DD="build/dd"
STAGE="build/stage"
APP="$DD/Build/Products/Release/RealNotch.app"

echo "› Building Release…"
xcodebuild -scheme RealNotch -configuration Release -derivedDataPath "$DD" build >/dev/null

echo "› Staging app…"
rm -rf "$STAGE" && mkdir -p "$STAGE" dist
cp -R "$APP" "$STAGE/"

echo "› Creating DMG…"
rm -f "dist/RealNotch-$VERSION.dmg"
create-dmg \
  --volname "RealNotch" \
  --volicon "$APP/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 560 360 \
  --icon-size 128 \
  --text-size 13 \
  --icon "RealNotch.app" 150 180 \
  --hide-extension "RealNotch.app" \
  --app-drop-link 410 180 \
  --no-internet-enable \
  "dist/RealNotch-$VERSION.dmg" \
  "$STAGE/"

echo "✓ dist/RealNotch-$VERSION.dmg"
