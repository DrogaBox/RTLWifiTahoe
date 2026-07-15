# RTL Wi-Fi Tahoe — Makefile
#
# Targets:
#   dev       Compile .app (Make caches: only rebuilds when sources change)
#   release   Optimized build (-O -whole-module-optimization)
#   test      Compile + run all unit tests
#   install   Copy .app to ~/Desktop
#   clean     rm -rf build/
#
# Per-file .o incremental compilation:
#   Swift's -output-file-map flag prevents binary output in Xcode 16.0's
#   swiftc (Apple Swift 6.0, rdar-style issue).  If the toolchain is updated,
#   re-test -incremental -output-file-map for true per-file recompilation.
#   Until then, Make tracks each source file's mtime — when any source
#   changes, swiftc runs with parallel frontends (-j auto default).
#
# Parallel:   make -j$$(sysctl -n hw.ncpu) dev

DEPLOYMENT_VERSION ?= 13.0
ARCH   := $(shell uname -m)
TARGET := $(ARCH)-apple-macos$(DEPLOYMENT_VERSION)
SDK    := $(shell xcrun --sdk macosx --show-sdk-path)
SWIFTC := xcrun swiftc

ROOT    := $(shell pwd)
BUILD   := $(ROOT)/build
MODULE  := RTLWifiTahoe
APP     := $(BUILD)/$(MODULE).app
BINARY  := $(APP)/Contents/MacOS/$(MODULE)
TEST_BIN := $(BUILD)/$(MODULE)Tests

SOURCES := \
	Sources/L10n.swift \
	Sources/Theme.swift \
	Sources/SignalIcon.swift \
	Sources/SignalLevel.swift \
	Sources/RTLog.swift \
	Sources/KeychainStore.swift \
	Sources/AppNotify.swift \
	Sources/SupportAudio.swift \
	Sources/JoinOptions.swift \
	Sources/RealtekDriver.swift \
	Sources/RealtekDriverProtocol.swift \
	Sources/MockRealtekDriver.swift \
	Sources/OIDConstants.swift \
	Sources/WiFiModel.swift \
	Sources/NetworkScan.swift \
	Sources/JoinPanel.swift \
	Sources/PopoverView.swift \
	Sources/StatusTab.swift \
	Sources/ProfilesTab.swift \
	Sources/SettingsTab.swift \
	Sources/DNSSectionView.swift \
	Sources/DesignDurations.swift \
	Sources/Duration+TimeInterval.swift \
	Sources/BraceBlockParser.swift \
	Sources/AppMain.swift \
	Sources/AboutPanelView.swift \
	Sources/GitHubContributors.swift \
	Sources/EnterpriseCertStore.swift

TEST_SOURCES :=

COMMON_FLAGS   := -sdk "$(SDK)" -target "$(TARGET)"
FRAMEWORKS     := -framework SwiftUI -framework AppKit -framework Network \
                  -framework IOKit -framework SystemConfiguration \
                  -framework Combine -framework Security \
                  -framework UserNotifications
TEST_FRAMEWORKS := -framework SwiftUI -framework Foundation -framework AppKit -framework Combine \
                   -framework IOKit -framework SystemConfiguration \
                   -framework Security -framework UserNotifications \
                   -framework Network

DEV_FLAGS     := -parse-as-library
RELEASE_FLAGS := -O -whole-module-optimization -parse-as-library

# --- Directories -----------------------------------------------------------
$(APP)/Contents/MacOS $(APP)/Contents/Resources $(BUILD):
	mkdir -p $@

# --- Dev (source-timestamp cached) -----------------------------------------
.PHONY: dev
dev: $(BINARY)

# Make tracks each source file's mtime.  When any changes, swiftc runs.
# Inside swiftc, -j auto (default) uses all cores for parallel frontends.
$(BINARY): $(SOURCES) | $(APP)/Contents/MacOS $(APP)/Contents/Resources
	$(SWIFTC) $(DEV_FLAGS) $(COMMON_FLAGS) $(FRAMEWORKS) \
	  -module-name $(MODULE) -o $@ $(SOURCES)
	$(MAKE) bundle-resources

# --- Release (optimized) ---------------------------------------------------
.PHONY: release
release: $(BINARY).release

$(BINARY).release: $(SOURCES) | $(APP)/Contents/MacOS $(APP)/Contents/Resources
	$(SWIFTC) $(RELEASE_FLAGS) $(COMMON_FLAGS) $(FRAMEWORKS) \
	  -module-name $(MODULE) -o $@ $(SOURCES)
	cp $@ $(BINARY)
	$(MAKE) bundle-resources
	@echo "Optimized binary at $(BINARY)"

# --- Test -------------------------------------------------------------------
.PHONY: test
test: $(TEST_BIN)
	$(TEST_BIN)

$(TEST_BIN): $(TEST_SOURCES) | $(BUILD)
	$(SWIFTC) $(COMMON_FLAGS) $(TEST_FRAMEWORKS) -o $@ $(TEST_SOURCES)
	codesign --force --sign - $@

# --- Resource bundling -----------------------------------------------------
.PHONY: bundle-resources
bundle-resources: $(APP)/Contents/Info.plist $(APP)/Contents/PkgInfo
	@if [ -f Resources/AppIcon.icns ]; then \
	  cp Resources/AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns; \
	fi
	@if [ -f Resources/bravo.mp3 ]; then \
	  cp Resources/bravo.mp3 $(APP)/Contents/Resources/bravo.mp3; \
	fi
	@for lproj in Resources/*.lproj; do \
	  [ -d "$$lproj" ] || continue; \
	  name=$$(basename "$$lproj"); \
	  mkdir -p $(APP)/Contents/Resources/$$name; \
	  cp -R "$$lproj/"* $(APP)/Contents/Resources/$$name/ 2>/dev/null || true; \
	done
	@codesign --force --deep --sign - "$(APP)" 2>/dev/null || true
	@xattr -cr "$(APP)" 2>/dev/null || true
	@echo "Resources bundled."

$(APP)/Contents/Info.plist: | $(APP)/Contents/Resources
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
<plist version="1.0"><dict>\n\
  <key>CFBundleDevelopmentRegion</key><string>en</string>\n\
  <key>CFBundleLocalizations</key><array><string>en</string><string>es</string></array>\n\
  <key>CFBundleExecutable</key><string>$(MODULE)</string>\n\
  <key>CFBundleIdentifier</key><string>com.drogabox.rtlwifitahoe</string>\n\
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>\n\
  <key>CFBundleName</key><string>RTL Wi-Fi Tahoe</string>\n\
  <key>CFBundleIconFile</key><string>AppIcon</string>\n\
  <key>CFBundlePackageType</key><string>APPL</string>\n\
  <key>CFBundleShortVersionString</key><string>1.1.1</string>\n\
  <key>CFBundleVersion</key><string>8</string>\n\
  <key>LSMinimumSystemVersion</key><string>13.0</string>\n\
  <key>LSUIElement</key><true/>\n\
  <key>NSHighResolutionCapable</key><true/>\n\
  <key>NSPrincipalClass</key><string>NSApplication</string>\n\
  <key>NSAppleEventsUsageDescription</key><string>RTL Wi-Fi Tahoe uses \
AppleScript to apply DNS changes that require administrator privileges \
when standard permissions are insufficient.</string>\n\
</dict></plist>' > $@

$(APP)/Contents/PkgInfo:
	printf 'APPL????' > $@

# --- Install ---------------------------------------------------------------
.PHONY: install
install: dev
	cp -R "$(APP)" "$(HOME)/Desktop/"
	@echo "Installed to ~/Desktop/$(MODULE).app"

# --- Clean -----------------------------------------------------------------
.PHONY: clean
clean:
	rm -rf "$(BUILD)"

# --- Info ------------------------------------------------------------------
.PHONY: info
info:
	@echo "ARCH:   $(ARCH)"
	@echo "TARGET: $(TARGET)"
	@echo "SDK:    $(SDK)"
	@echo "SWIFT:  $(shell $(SWIFTC) --version 2>&1 | head -1)"
	@echo "SOURCES: $(words $(SOURCES)) files"
	@echo "TESTS:   $(words $(TEST_SOURCES)) files"

# --- Help ------------------------------------------------------------------
.PHONY: help
help:
	@echo 'RTL Wi-Fi Tahoe -- Makefile'
	@echo ''
	@echo 'Targets:'
	@echo '  make dev       compile .app (cached via source mtime)'
	@echo '  make release   optimized (-O -whole-module-optimization)'
	@echo '  make test      compile + run all unit tests'
	@echo '  make install   copy .app to ~/Desktop'
	@echo '  make clean     rm -rf build/'
	@echo '  make info      show arch, SDK, version'
	@echo ''
	@echo 'Parallel:  make -j$$(sysctl -n hw.ncpu) dev'
