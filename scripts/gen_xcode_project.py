#!/usr/bin/env python3
"""Generate RTLWifiTahoe.xcodeproj for SwiftUI previews."""
import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def uid(s):
    return hashlib.md5(s.encode()).hexdigest()[:24].upper()

SOURCES = [
    "Sources/L10n.swift", "Sources/Models.swift", "Sources/NetProbe.swift",
    "Sources/RealtekProfiles.swift", "Sources/LoginItemHelper.swift",
    "Sources/DesignDurations.swift",
    "Sources/Theme.swift", "Sources/SignalIcon.swift", "Sources/SignalLevel.swift",
    "Sources/RTLog.swift", "Sources/KeychainStore.swift", "Sources/AppNotify.swift",
    "Sources/SupportAudio.swift", "Sources/JoinOptions.swift",
    "Sources/RealtekDriverProtocol.swift", "Sources/RealtekDriver.swift",
    "Sources/MockRealtekDriver.swift", "Sources/WiFiModel.swift",
    "Sources/NetworkScan.swift", "Sources/JoinPanel.swift",
    "Sources/DNSSectionView.swift", "Sources/StatusTab.swift",
    "Sources/ProfilesTab.swift", "Sources/SettingsTab.swift",
    "Sources/PopoverView.swift",    "Sources/OIDConstants.swift",
    "Sources/AppMain.swift",
]

FRAMEWORKS_MAP = {
    "SwiftUI.framework": "/System/Library/Frameworks/SwiftUI.framework",
    "AppKit.framework": "/System/Library/Frameworks/AppKit.framework",
    "Network.framework": "/System/Library/Frameworks/Network.framework",
    "IOKit.framework": "/System/Library/Frameworks/IOKit.framework",
    "SystemConfiguration.framework": "/System/Library/Frameworks/SystemConfiguration.framework",
    "Combine.framework": "/System/Library/Frameworks/Combine.framework",
    "Security.framework": "/System/Library/Frameworks/Security.framework",
    "UserNotifications.framework": "/System/Library/Frameworks/UserNotifications.framework",
}

FRAMEWORK_NAMES = list(FRAMEWORKS_MAP.keys())

ROOT_OBJ = uid("root")
MAIN_GROUP = uid("main_group")
SOURCES_GROUP = uid("sources_group")
FRAMEWORKS_GROUP = uid("frameworks_group")
PRODUCTS_GROUP = uid("products_group")
PROJECT_CONF_LIST = uid("project_conf_list")
TARGET_CONF_LIST = uid("target_conf_list")
DEBUG_PROJ_CONF = uid("debug_proj")
RELEASE_PROJ_CONF = uid("release_proj")
DEBUG_TGT_CONF = uid("debug_tgt")
RELEASE_TGT_CONF = uid("release_tgt")
SOURCES_PHASE = uid("sources_phase")
FRAMEWORKS_PHASE = uid("frameworks_phase")
RESOURCES_PHASE = uid("resources_phase")
TARGET = uid("target")
PRODUCT_REF = uid("product_ref")

file_refs = {b: uid("ref_" + b) for b in SOURCES}
build_files = {b: uid("build_" + b) for b in SOURCES}
framework_file_refs = {f: uid("fw_ref_" + f) for f in FRAMEWORK_NAMES}
framework_build_files = {f: uid("fw_build_" + f) for f in FRAMEWORK_NAMES}
INFO_PLIST_REF = uid("ref_Info.plist")

lines = []
def L(s=""):
    lines.append(s)

L("// !$*UTF8*$!")
L("{")
L("\tarchiveVersion = 1;")
L("\tclasses = {")
L("\t};")
L("\tobjectVersion = 56;")
L("\tobjects = {")
L("")

# ── PBXBuildFile ──
L("/* Begin PBXBuildFile section */")
for s in SOURCES:
    fname = os.path.basename(s)
    L(f'\t\t{build_files[s]} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[s]}; }};')
for fw in FRAMEWORK_NAMES:
    fname = fw.replace(".framework", "")
    L(f'\t\t{framework_build_files[fw]} /* {fname} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {framework_file_refs[fw]}; }};')
L("/* End PBXBuildFile section */")
L("")

# ── PBXFileReference ──
L("/* Begin PBXFileReference section */")
for s in SOURCES:
    fname = os.path.basename(s)
    L(f'\t\t{file_refs[s]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{s}"; sourceTree = SOURCE_ROOT; }};')
for fw in FRAMEWORK_NAMES:
    path = FRAMEWORKS_MAP[fw]
    L(f'\t\t{framework_file_refs[fw]} /* {fw} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {fw}; path = "{path}"; sourceTree = SDKROOT; }};')
L(f'\t\t{PRODUCT_REF} /* RTLWifiTahoe.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = RTLWifiTahoe.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
L(f'\t\t{INFO_PLIST_REF} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
L("/* End PBXFileReference section */")
L("")

# ── PBXFrameworksBuildPhase ──
L("/* Begin PBXFrameworksBuildPhase section */")
L(f'\t\t{FRAMEWORKS_PHASE} = {{')
L('\t\t\tisa = PBXFrameworksBuildPhase;')
L('\t\t\tbuildActionMask = 2147483647;')
L('\t\t\tfiles = (')
for fw in FRAMEWORK_NAMES:
    fname = fw.replace(".framework", "")
    L(f'\t\t\t\t{framework_build_files[fw]} /* {fname} in Frameworks */,')
L('\t\t\t);')
L('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
L('\t\t};')
L("/* End PBXFrameworksBuildPhase section */")
L("")

# ── PBXGroup ──
L("/* Begin PBXGroup section */")
L(f'\t\t{MAIN_GROUP} = {{')
L('\t\t\tisa = PBXGroup;')
L('\t\t\tchildren = (')
L(f'\t\t\t\t{SOURCES_GROUP},')
L(f'\t\t\t\t{FRAMEWORKS_GROUP},')
L(f'\t\t\t\t{PRODUCTS_GROUP},')
L(f'\t\t\t\t{INFO_PLIST_REF},')
L('\t\t\t);')
L('\t\t\tsourceTree = "<group>";')
L('\t\t};')
for gid, gname, gchildren in [
    (SOURCES_GROUP, "Sources", [file_refs[s] for s in SOURCES]),
    (FRAMEWORKS_GROUP, "Frameworks", [framework_file_refs[f] for f in FRAMEWORK_NAMES]),
    (PRODUCTS_GROUP, "Products", [PRODUCT_REF]),
]:
    L(f'\t\t{gid} = {{')
    L('\t\t\tisa = PBXGroup;')
    L('\t\t\tchildren = (')
    for c in gchildren:
        L(f'\t\t\t\t{c},')
    L('\t\t\t);')
    L(f'\t\t\tname = {gname};')
    L('\t\t\tsourceTree = "<group>";' if gname != "Sources" else '\t\t\tpath = "";\n\t\t\tsourceTree = SOURCE_ROOT;')
    L('\t\t};')
L("/* End PBXGroup section */")
L("")

# ── PBXNativeTarget ──
L("/* Begin PBXNativeTarget section */")
L(f'\t\t{TARGET} = {{')
L('\t\t\tisa = PBXNativeTarget;')
L(f'\t\t\tbuildConfigurationList = {TARGET_CONF_LIST};')
L('\t\t\tbuildPhases = (')
L(f'\t\t\t\t{SOURCES_PHASE},')
L(f'\t\t\t\t{FRAMEWORKS_PHASE},')
L(f'\t\t\t\t{RESOURCES_PHASE},')
L('\t\t\t);')
L('\t\t\tbuildRules = ();')
L('\t\t\tdependencies = ();')
L('\t\t\tname = RTLWifiTahoe;')
L('\t\t\tproductName = RTLWifiTahoe;')
L(f'\t\t\tproductReference = {PRODUCT_REF};')
L('\t\t\tproductType = "com.apple.product-type.application";')
L('\t\t};')
L("/* End PBXNativeTarget section */")
L("")

# ── PBXProject ──
L("/* Begin PBXProject section */")
L(f'\t\t{ROOT_OBJ} = {{')
L('\t\t\tisa = PBXProject;')
L('\t\t\tattributes = {')
L('\t\t\t\tBuildIndependentTargetsInParallel = 1;')
L('\t\t\t\tLastSwiftUpdateCheck = 1500;')
L('\t\t\t\tLastUpgradeCheck = 1500;')
L('\t\t\t};')
L(f'\t\t\tbuildConfigurationList = {PROJECT_CONF_LIST};')
L('\t\t\tcompatibilityVersion = "Xcode 14.0";')
L('\t\t\tdevelopmentRegion = en;')
L('\t\t\thasScannedForEncodings = 0;')
L('\t\t\tknownRegions = (en, es, Base);')
L(f'\t\t\tmainGroup = {MAIN_GROUP};')
L(f'\t\t\tproductRefGroup = {PRODUCTS_GROUP};')
L('\t\t\tprojectDirPath = "";')
L('\t\t\tprojectRoot = "";')
L('\t\t\ttargets = (')
L(f'\t\t\t\t{TARGET},')
L('\t\t\t);')
L('\t\t};')
L("/* End PBXProject section */")
L("")

# ── PBXResourcesBuildPhase ──
L("/* Begin PBXResourcesBuildPhase section */")
L(f'\t\t{RESOURCES_PHASE} = {{')
L('\t\t\tisa = PBXResourcesBuildPhase;')
L('\t\t\tbuildActionMask = 2147483647;')
L('\t\t\tfiles = ();')
L('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
L('\t\t};')
L("/* End PBXResourcesBuildPhase section */")
L("")

# ── PBXSourcesBuildPhase ──
L("/* Begin PBXSourcesBuildPhase section */")
L(f'\t\t{SOURCES_PHASE} = {{')
L('\t\t\tisa = PBXSourcesBuildPhase;')
L('\t\t\tbuildActionMask = 2147483647;')
L('\t\t\tfiles = (')
for s in SOURCES:
    fname = os.path.basename(s)
    L(f'\t\t\t\t{build_files[s]} /* {fname} in Sources */,')
L('\t\t\t);')
L('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
L('\t\t};')
L("/* End PBXSourcesBuildPhase section */")
L("")

# ── XCBuildConfiguration ──
def config_line(key, val, indent=4):
    return '\t' * indent + key + ' = ' + val + ';'

L("/* Begin XCBuildConfiguration section */")
# Project configs
for name, settings in [
    ("Debug", {"SWIFT_OPTIMIZATION_LEVEL": '"-Onone"', "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG"}),
    ("Release", {"SWIFT_OPTIMIZATION_LEVEL": '"-O"', "SWIFT_COMPILATION_MODE": "wholemodule"}),
]:
    uid_val = DEBUG_PROJ_CONF if name == "Debug" else RELEASE_PROJ_CONF
    L(f'\t\t{uid_val} = {{')
    L('\t\t\tisa = XCBuildConfiguration;')
    L('\t\t\tbuildSettings = {')
    for k, v in settings.items():
        L(config_line(k, v, 4))
    for k in ["ALWAYS_SEARCH_USER_PATHS", "CLANG_ENABLE_MODULES", "CLANG_ENABLE_OBJC_ARC", "COMBINE_HIDPI_IMAGES", "GCC_NO_COMMON_BLOCKS"]:
        L(config_line(k, "YES", 4))
    L(config_line("MACOSX_DEPLOYMENT_TARGET", "13.0", 4))
    L(config_line("SDKROOT", "macosx", 4))
    if name == "Debug":
        L(config_line("ONLY_ACTIVE_ARCH", "YES", 4))
    L(config_line("SWIFT_VERSION", "5.0", 4))
    L('\t\t\t};')
    L(f'\t\t\tname = {name};')
    L('\t\t};')

# Target configs
TARGET_SETTINGS = [
    'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;',
    'CODE_SIGN_IDENTITY = "-";',
    'CODE_SIGN_STYLE = Manual;',
    'COMBINE_HIDPI_IMAGES = YES;',
    'INFOPLIST_FILE = Info.plist;',
    'MACOSX_DEPLOYMENT_TARGET = 13.0;',
    'PRODUCT_BUNDLE_IDENTIFIER = com.drogabox.rtlwifitahoe;',
    'PRODUCT_NAME = "RTL Wi-Fi Tahoe";',
    'SDKROOT = macosx;',
    'SWIFT_EMIT_LOC_STRINGS = YES;',
    'SWIFT_VERSION = 5.0;',
]
for name, uid_val in [("Debug", DEBUG_TGT_CONF), ("Release", RELEASE_TGT_CONF)]:
    L(f'\t\t{uid_val} = {{')
    L('\t\t\tisa = XCBuildConfiguration;')
    L('\t\t\tbuildSettings = {')
    for s in TARGET_SETTINGS:
        L('\t\t\t\t' + s)
    L('\t\t\t};')
    L(f'\t\t\tname = {name};')
    L('\t\t};')

L("/* End XCBuildConfiguration section */")
L("")

# ── XCConfigurationList ──
L("/* Begin XCConfigurationList section */")
for name, uid_val, confs in [
    ("project", PROJECT_CONF_LIST, [DEBUG_PROJ_CONF, RELEASE_PROJ_CONF]),
    ("target", TARGET_CONF_LIST, [DEBUG_TGT_CONF, RELEASE_TGT_CONF]),
]:
    L(f'\t\t{uid_val} = {{')
    L('\t\t\tisa = XCConfigurationList;')
    L('\t\t\tbuildConfigurations = (')
    for c in confs:
        L(f'\t\t\t\t{c},')
    L('\t\t\t);')
    L('\t\t\tdefaultConfigurationIsVisible = 0;')
    L('\t\t\tdefaultConfigurationName = Release;')
    L('\t\t};')
L("/* End XCConfigurationList section */")
L("")

L("\t};")
L(f'\trootObject = {ROOT_OBJ};')
L("}")

PROJECT_DIR = os.path.join(ROOT, "RTLWifiTahoe.xcodeproj")
os.makedirs(PROJECT_DIR, exist_ok=True)
with open(os.path.join(PROJECT_DIR, "project.pbxproj"), "w") as f:
    f.write("\n".join(lines))
print(f"Written: {os.path.join(PROJECT_DIR, 'project.pbxproj')}")

info_plist = '''<?xml version="1.0" encoding="UTF-8"?>
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
  <string>1.0.5</string>
  <key>CFBundleVersion</key>
  <string>6</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>RTL Wi-Fi Tahoe uses AppleScript to apply DNS changes that require administrator privileges when standard permissions are insufficient.</string>
</dict>
</plist>'''
with open(os.path.join(ROOT, "Info.plist"), "w") as f:
    f.write(info_plist)
print(f"Written: {os.path.join(ROOT, 'Info.plist')}")
