#!/usr/bin/env bash
#
# Builds Endeavour.app — a menu-bar (LSUIElement) agent bundle.
#
# Usage:
#   Scripts/build-app.sh            # arm64 (Apple Silicon) release
#   Scripts/build-app.sh universal  # universal arm64 + x86_64 binary
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Endeavour"
EXEC_NAME="Endeavour"
BUNDLE_ID="dev.holway.endeavour"
VERSION="2.0.0"
MIN_MACOS="13.0"

ARCH_ARGS=(--arch arm64)
if [[ "${1:-}" == "universal" ]]; then
    ARCH_ARGS=(--arch arm64 --arch x86_64)
fi

echo "==> Building release binary (${ARCH_ARGS[*]})"
swift build -c release "${ARCH_ARGS[@]}"

BIN_PATH="$(swift build -c release "${ARCH_ARGS[@]}" --show-bin-path)/${EXEC_NAME}"

APP_DIR="build/${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
echo "==> Assembling ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${CONTENTS}/MacOS" "${CONTENTS}/Resources"

cp "${BIN_PATH}" "${CONTENTS}/MacOS/${EXEC_NAME}"

if [[ -f "Resources/AppIcon.icns" ]]; then
    cp "Resources/AppIcon.icns" "${CONTENTS}/Resources/AppIcon.icns"
fi

cat > "${CONTENTS}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${EXEC_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Endeavour needs Automation access to open your commands in Terminal or iTerm.</string>
    <key>NSHumanReadableCopyright</key>
    <string>MIT licensed. Originally created by Trevor Fitzgerald and contributors.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "${APP_DIR}"

echo "==> Done: ${APP_DIR}"
echo "    Install with:  cp -R \"${APP_DIR}\" /Applications/"
