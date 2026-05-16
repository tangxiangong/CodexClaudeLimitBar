#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CodexClaudeLimitBar"
BUNDLE_ID="com.xiaoyu.CodexClaudeLimitBar"
MIN_SYSTEM_VERSION="14.0"
BUILD_CONFIGURATION="release"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_RESOURCE_SOURCE="$ROOT_DIR/Sources/CodexClaudeLimitBar/Resources"
APP_ICON_SOURCE="$ROOT_DIR/icon.png"
APP_ICON_NAME="AppIcon"
APP_ICON_FILE="$APP_RESOURCES/$APP_ICON_NAME.icns"

build_app_icon() {
  local iconset_dir="$APP_RESOURCES/$APP_ICON_NAME.iconset"

  rm -rf "$iconset_dir"
  mkdir -p "$iconset_dir"

  /usr/bin/sips -z 16 16 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_16x16.png" >/dev/null
  /usr/bin/sips -z 32 32 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
  /usr/bin/sips -z 32 32 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_32x32.png" >/dev/null
  /usr/bin/sips -z 64 64 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
  /usr/bin/sips -z 128 128 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_128x128.png" >/dev/null
  /usr/bin/sips -z 256 256 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
  /usr/bin/sips -z 256 256 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_256x256.png" >/dev/null
  /usr/bin/sips -z 512 512 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
  /usr/bin/sips -z 512 512 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_512x512.png" >/dev/null
  /usr/bin/sips -z 1024 1024 "$APP_ICON_SOURCE" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null

  /usr/bin/iconutil -c icns "$iconset_dir" -o "$APP_ICON_FILE"
  rm -rf "$iconset_dir"
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build -c "$BUILD_CONFIGURATION"
BUILD_BIN_DIR="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BUILD_BIN_DIR/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -d "$APP_RESOURCE_SOURCE" ]]; then
  cp -R "$APP_RESOURCE_SOURCE"/. "$APP_RESOURCES/"
fi

if [[ -f "$APP_ICON_SOURCE" ]]; then
  build_app_icon
else
  echo "warning: icon.png not found; app bundle will use the default macOS app icon" >&2
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --sign - "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  package|--package)
    echo "Packaged $APP_BUNDLE"
    ;;
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
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [package|run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
