#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"

DEPLOYMENT_VERSION="13.0"
if [[ "$ARCH" == "arm64" ]]; then
  TARGET="arm64-apple-macos$DEPLOYMENT_VERSION"
else
  TARGET="x86_64-apple-macos$DEPLOYMENT_VERSION"
fi

BUILD="$ROOT/build"
mkdir -p "$BUILD"

echo "Compiling test target ($TARGET)…"

SOURCES=(
  "$ROOT/Sources/L10n.swift"
  "$ROOT/Sources/Models.swift"
  "$ROOT/Sources/RealtekProfiles.swift"
  "$ROOT/Sources/RTLog.swift"
  "$ROOT/Sources/KeychainStore.swift"
  "$ROOT/Sources/JoinOptions.swift"
  "$ROOT/Sources/SignalLevel.swift"
  # Theme.swift and SignalIcon.swift omitted — they import SwiftUI which
  # is not needed for WiFiModel unit tests.
  "$ROOT/Sources/NetworkScan.swift"
  "$ROOT/Sources/NetProbe.swift"
  "$ROOT/Sources/RealtekDriverProtocol.swift"
  "$ROOT/Sources/OIDConstants.swift"
  "$ROOT/Sources/RealtekDriver.swift"
  "$ROOT/Sources/MockRealtekDriver.swift"
  "$ROOT/Sources/DesignDurations.swift"
  "$ROOT/Sources/Duration+TimeInterval.swift"
  "$ROOT/Sources/LoginItemHelper.swift"
  "$ROOT/Sources/SupportAudio.swift"
  "$ROOT/Sources/AppNotify.swift"
  "$ROOT/Sources/WiFiModel.swift"
  "$ROOT/Tests/MiniTest.swift"
  "$ROOT/Tests/WiFiModelTests.swift"
)

xcrun swiftc \
  -sdk "$SDK" \
  -target "$TARGET" \
  -framework Foundation \
  -framework AppKit \
  -framework Combine \
  -framework IOKit \
  -framework SystemConfiguration \
  -framework Security \
  -framework UserNotifications \
  -framework Network \
  "${SOURCES[@]}" \
  -o "$BUILD/WiFiModelTests"

echo "Ad-hoc signing test binary…"
# Ad-hoc sign so SecItem* calls don't hang on an unsigned binary.
# Without a valid code signature, Security.framework may block waiting
# for a user-facing keychain permission dialog that never appears in a
# headless test runner. The `-` identity means ad-hoc (no real cert).
codesign --force --sign - "$BUILD/WiFiModelTests"

echo "Running tests…"
"$BUILD/WiFiModelTests"
