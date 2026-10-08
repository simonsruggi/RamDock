#!/usr/bin/env bash
# Builds ProcDock.app (universal) into ./build and, with --install, copies it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/ProcDock.app"
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/apple/Products/Release/ProcDock "$APP/Contents/MacOS/ProcDock"
cp ProcDock/Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp ProcDock/Info.plist "$APP/Contents/Info.plist"

IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application/{print $2; exit}')"
if [ -n "$IDENTITY" ]; then
    codesign --force --options runtime --timestamp=none --sign "$IDENTITY" "$APP"
else
    codesign --force --sign - "$APP"
fi
echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
    osascript -e 'quit app "ProcDock"' 2>/dev/null || true
    rm -rf /Applications/ProcDock.app
    cp -R "$APP" /Applications/ProcDock.app
    echo "Installed /Applications/ProcDock.app"
fi
