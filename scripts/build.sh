#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/RTL Wi-Fi Tahoe.app"
SDK="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SOURCES=(
  "$ROOT/Sources/L10n.swift"
  "$ROOT/Sources/Theme.swift"
  "$ROOT/Sources/SignalIcon.swift"
  "$ROOT/Sources/RTLog.swift"
  "$ROOT/Sources/KeychainStore.swift"
  "$ROOT/Sources/AppNotify.swift"
  "$ROOT/Sources/SupportAudio.swift"
  "$ROOT/Sources/JoinOptions.swift"
  "$ROOT/Sources/RealtekDriver.swift"
  "$ROOT/Sources/WiFiModel.swift"
  "$ROOT/Sources/NetworkScan.swift"
  "$ROOT/Sources/JoinPanel.swift"
  "$ROOT/Sources/PopoverView.swift"
  "$ROOT/Sources/AppMain.swift"
)

echo "Compiling…"
# Prefer native arch of this Mac
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  TARGET="arm64-apple-macos13.0"
else
  TARGET="x86_64-apple-macos13.0"
fi
echo "Target: $TARGET"

xcrun swiftc -O -parse-as-library \
  -sdk "$SDK" \
  -target "$TARGET" \
  -framework SwiftUI \
  -framework AppKit \
  -framework Network \
  -framework IOKit \
  -framework SystemConfiguration \
  -framework Combine \
  -framework Security \
  -framework UserNotifications \
  "${SOURCES[@]}" \
  -o "$APP/Contents/MacOS/RTLWifiTahoe"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>en</string>
    <string>es</string>
  </array>
  <key>CFBundleExecutable</key>
  <string>RTLWifiTahoe</string>
  <key>CFBundleIdentifier</key>
  <string>com.drogabox.rtlwifitahoe</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>RTL Wi-Fi Tahoe</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.4</string>
  <key>CFBundleVersion</key>
  <string>5</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>RTL Wi-Fi Tahoe needs Accessibility to read the Realtek driver network list and join without opening the classic menu.</string>
</dict>
</plist>
PLIST

# App icon
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  echo "Icon: AppIcon.icns"
fi

# Support audio (same applause clip as AMD Power Gadget)
if [[ -f "$ROOT/Resources/bravo.mp3" ]]; then
  cp "$ROOT/Resources/bravo.mp3" "$APP/Contents/Resources/bravo.mp3"
  echo "Audio: bravo.mp3"
fi

# Localizations (en.lproj, es.lproj, …) for Crowdin / Bundle.main
for lproj in "$ROOT"/Resources/*.lproj; do
  if [[ -d "$lproj" ]]; then
    name="$(basename "$lproj")"
    mkdir -p "$APP/Contents/Resources/$name"
    cp -R "$lproj/"* "$APP/Contents/Resources/$name/" 2>/dev/null || true
    echo "L10n: $name"
  fi
done

# PkgInfo
echo -n "APPL????" > "$APP/Contents/PkgInfo"

# Ad-hoc sign for local run
codesign --force --deep --sign - "$APP" 2>/dev/null || true
xattr -cr "$APP" 2>/dev/null || true

echo "Built: $APP"
ls -la "$APP/Contents/MacOS/" "$APP/Contents/Resources/" 2>/dev/null || true
