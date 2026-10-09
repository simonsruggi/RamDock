#!/usr/bin/env bash
# Builds RamDock.app (universal) into ./build and, with --install, copies it to /Applications.
# Signed with a Developer ID when one is available, ad-hoc otherwise.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/RamDock.app"
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp .build/apple/Products/Release/RamDock "$APP/Contents/MacOS/RamDock"
cp RamDock/Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp RamDock/Info.plist "$APP/Contents/Info.plist"
cp -R .build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework \
      "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/RamDock" 2>/dev/null || true

IDENTITY="${RAMDOCK_SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application/{print $2; exit}')}"
if [ -n "$IDENTITY" ]; then
    SIGN=("--options" "runtime" "--timestamp=none" "--sign" "$IDENTITY")
else
    SIGN=("--sign" "-")
fi

# Sparkle ships signed by its own team; re-sign it inside out so dyld accepts it.
FW="$APP/Contents/Frameworks/Sparkle.framework"
for nested in "$FW/Versions/B/XPCServices/Downloader.xpc" \
              "$FW/Versions/B/XPCServices/Installer.xpc" \
              "$FW/Versions/B/Updater.app" \
              "$FW/Versions/B/Autoupdate"; do
    [ -e "$nested" ] && codesign --force "${SIGN[@]}" "$nested"
done
codesign --force "${SIGN[@]}" "$FW"
codesign --force "${SIGN[@]}" "$APP"
echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
    osascript -e 'quit app "RamDock"' 2>/dev/null || true
    rm -rf /Applications/RamDock.app
    cp -R "$APP" /Applications/RamDock.app
    echo "Installed /Applications/RamDock.app"
fi
