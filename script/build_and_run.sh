#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="HabitBar"
BUNDLE_ID="com.georgetsouvaltzis.HabitBar"
MIN_SYSTEM_VERSION="14.0"
BUILD_FLAGS=()
OPEN_ARGS=()
BUILD_CONFIGURATION="debug"

case "$MODE" in
  --release|release|--prod|prod)
    BUILD_CONFIGURATION="release"
    MODE="run"
    ;;
  --verify-release|verify-release|--verify-prod|verify-prod)
    BUILD_CONFIGURATION="release"
    MODE="--verify"
    ;;
esac

if [[ "$MODE" == "--verify-ui" || "$MODE" == "verify-ui" || "$MODE" == "--ui-smoke" || "$MODE" == "ui-smoke" ]]; then
  BUILD_FLAGS=(-Xswiftc -DUI_TESTING)
  OPEN_ARGS=(--args --ui-testing)
fi

if [[ "$BUILD_CONFIGURATION" == "release" ]]; then
  BUILD_FLAGS=(-c release "${BUILD_FLAGS[@]}")
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_SOURCE="$ROOT_DIR/Sources/HabitBar/Resources/AppIcon.icns"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ ${#BUILD_FLAGS[@]} -gt 0 ]]; then
  swift build "${BUILD_FLAGS[@]}"
  BUILD_BINARY="$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)/$APP_NAME"
else
  swift build
  BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -f "$APP_ICON_SOURCE" ]]; then
  cp "$APP_ICON_SOURCE" "$APP_RESOURCES/AppIcon.icns"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>Habit Bar</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSUserNotificationAlertStyle</key>
  <string>banner</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

open_app() {
  if [[ ${#OPEN_ARGS[@]} -gt 0 ]]; then
    /usr/bin/open -n "$APP_BUNDLE" "${OPEN_ARGS[@]}"
  else
    /usr/bin/open -n "$APP_BUNDLE"
  fi
}

cleanup_app() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    trap cleanup_app EXIT
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --verify-ui|verify-ui)
    trap cleanup_app EXIT
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --ui-smoke|ui-smoke)
    trap cleanup_app EXIT
    open_app
    sleep 1
    swift run HabitBarUITestRunner
    ;;
  *)
    echo "usage: $0 [run|--release|--debug|--logs|--telemetry|--verify|--verify-release|--verify-ui|--ui-smoke]" >&2
    exit 2
    ;;
esac
