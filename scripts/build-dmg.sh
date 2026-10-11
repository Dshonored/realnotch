#!/bin/bash
# Build a Release RealNotch.app and package it into a drag-to-install DMG.
# Requires: Xcode, create-dmg (brew install create-dmg).
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${1:?usage: $0 <version>  e.g. $0 0.9.0 (no leading v)}"
VERSION="${VERSION#v}"
DD="build/dd"
STAGE="build/stage"
APP="$DD/Build/Products/Release/RealNotch.app"

echo "› Building Release…"
# Stamp the release version into the bundle — the in-app updater compares
# CFBundleShortVersionString against the GitHub tag (vX.Y.Z).
xcodebuild -scheme RealNotch -configuration Release -derivedDataPath "$DD" \
  MARKETING_VERSION="$VERSION" build >/dev/null

BUILT=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
[ "$BUILT" = "$VERSION" ] || { echo "✗ built version $BUILT != $VERSION"; exit 1; }

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
