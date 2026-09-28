#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
APP=build/WorkWife.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/WorkWife" "$APP/Contents/MacOS/WorkWife"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp WorkWife-Apple-Icon-Bundle/macOS/WorkWife.icns "$APP/Contents/Resources/AppIcon.icns"
cp tindeck_1.mp3 "$APP/Contents/Resources/tindeck_1.mp3"

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/{print $2; exit}')}"
codesign --force --sign "$IDENTITY" "$APP"

if [[ "${1:-}" == "install" ]]; then
    pkill -x WorkWife || true
    rm -rf /Applications/WorkWife.app
    ditto "$APP" /Applications/WorkWife.app
    open /Applications/WorkWife.app
fi
