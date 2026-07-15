# Binary Ninja console - ULTIMATE RE: dump ALL ObjC methods from the binary
# This iterates ALL functions, finds ObjC methods by name pattern,
# decompiles unknown ones, and searches for OIDs.
#
# Paste:
#   exec(open(".../re/bn_ultimate_re.py").read(), globals())
#
# What it finds:
#   - ALL ObjC methods (not just C symbols) via view.functions
#   - GetHTinfo_BW, GetHTinfo_GI, GetHTinfo_MCS  (HT info OIDs)
#   - GetRX, GetTX  (byte counters)
#   - CmdTxPower, USBSwitch_*, SetPwrTableByLocale  (Tx/USB OIDs)
#   - Any function referencing known OIDs

import os

OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output/ultimate")
try:
    os.makedirs(OUT)
except Exception:
    pass

# Method patterns we care about (ObjC method names to search for)
TARGET_METHODS = [
    "GetHTinfo_BW", "GetHTinfo_GI", "GetHTinfo_MCS",
    "GetRX", "GetTX",
    "CmdTxPower", "CmdChannel", "CmdRssi",
    "USBSwitch_U2ToU3", "USBSwitch_U3ToU2", "USBSwitch_bNicInU3",
    "SetPwrTableByLocale", "DecryptPwrTable",
    "IsRTL8180Enabled", "GetSystemUSB3Cap",
    "GetWPSHwPBC", "GetDriverVersion",
    "GetBSSID", "GetChannel", "GetConnectionStatus",
    "getSignalStrength", "GetNetworkName",
    "GetSupportedWirelessMode",
    "GetPermanentAddress", "GetProductID", "GetVendorID",
    "SetWEPKey", "SetWPAKey", "SetNetworkName",
    "SetAppleLocale", "SetDriversIOKitClassName",
]

# Known OIDs to search for in each function's HLIL
KNOWN_OIDS = {
    "0xFF07011A": "OID_RT_SET_SCAN",
    "0xFF0101BD": "OID_RT_GET_SCAN_IN_PROGRESS",
    "0xFF010419": "OID_BSS_NUMBER",
    "0xFF070102": "OID_RT_SSID",
    "0xFF010305": "OID_RT_PASSPHRASE",
    "0xFF010194": "OID_RT_AKM",
    "0xFF01041A": "OID_RT_SHARED_KEY_FLAG",
    "0xFF01041B": "OID_RT_CONNECT",
    "0x0D010115": "OID_802_11_DISASSOCIATE",
    "0x0D010108": "OID_802_11_INFRASTRUCTURE_MODE",
    "0xFF030004": "OID_RT_ADHOC_WPA_FLAG",
    "0xFF010182": "OID_RT_CHANNEL",
    "0x0D010101": "OID_802_11_BSSID",
    "0xFF818081": "OID_RT_RF",
    "0x0D010206": "OID_RT_SIGNAL_STRENGTH",
    "0xFF818500": "OID_RT_WIRELESS_MODE",
    "0xFF010418": "OID_RT_NIC_STATUS",
    "0xFF819053": "OID_RT_LINK_FLAG",
    "0x00010114": "OID_RT_CONNECTION_STATUS",
    "0xFF819029": "OID_RT_WPS_HW_PBC",
    "0xFF81901D": "OID_RT_LINK_RATE",
    "0xFF070113": "OID_RT_WEP_KEY",
    "0xFF0101BB": "OID_RT_WIRELESS_MODE_2",  # discovered in full_autoscan
    "0xFF819048": "OID_RT_SUPPLICANT_STATUS",  # discovered in full_autoscan
}

# Classes we care about
TARGET_CLASSES = [
    "WLANClientUtilityModel",
    "WiFiStatusBarDelegate",
    "WiFiUtility",
    "WiFiProfiles",
    "WiFiPasswordEncrypt",
]

view = None
try: view = bv
except: pass
if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"):
            view = _v
            break

def safe(s):
    if s is None: return ""
    return s.encode("ascii", "replace").decode("ascii")

def decompile_func(f, label):
    """Decompile a function to HLIL text and save to file."""
    try:
        body = str(f.hlil) if f.hlil else str(f.mlil) if f.mlil else "(no IL)"
    except Exception as e:
        body = "(error: %s)" % e
    body = safe(body)
    text = "## %s\naddr: %s  name: %s\n\n```c\n%s\n```\n" % (label, hex(f.start), f.name, body)
    fname = label.replace("/", "_").replace(":", "_").replace(" ", "_")[:80]
    path = os.path.join(OUT, "%s.txt" % fname)
    with open(path, "wb") as fh:
        fh.write(text.encode("utf-8"))
    return text

def find_oids_in_body(body_str):
    """Search for known OID constants in a decompiled function body."""
    found = []
    for oid_str, oid_name in sorted(KNOWN_OIDS.items(), key=lambda x: -len(x[0])):
        # Search case-insensitive for the hex pattern
        lower = body_str.lower()
        patterns = [oid_str.lower(), oid_str.lower().lstrip("0x"), "0x%08x" % int(oid_str, 16)]
        for p in patterns:
            if p in lower:
                found.append(oid_name)
                break
    return found

if view is None:
    print("[rtl] ERROR: no bv")
    print('  exec(open(".../re/bn_ultimate_re.py").read(), globals())')
else:
    print("[rtl] === ULTIMATE RE ===")
    print("[rtl] view:", view.file.filename if hasattr(view, 'file') else "?")
    print("[rtl] Total functions:", len(list(view.functions)))

    # ================================================================
    # PHASE 1: Categorize ALL functions
    # ================================================================
    print("\n[rtl] PHASE 1: Categorizing all %d functions..." % len(list(view.functions)))

    objc_methods = []     # (name, address, function)
    c_functions = []      # (name, address, function)
    target_hits = []      # (name, address, function, matched_pattern)
    other_functions = []  # (name, address)

    for f in view.functions:
        name = f.name
        addr = f.start
        # ObjC methods have the pattern "-[ClassName methodName:]" or "+[ClassName methodName:]"
        if name.startswith("-") or name.startswith("+"):
            objc_methods.append((name, addr, f))
            # Check if this is one of our target classes
            is_target = False
            for cls in TARGET_CLASSES:
                if cls in name:
                    is_target = True
                    break
            if is_target:
                # Check if it matches any of our target method patterns
                for pat in TARGET_METHODS:
                    if pat in name:
                        target_hits.append((name, addr, f, pat))
                        break
                else:
                    # It's a target class method but not in our patterns - still interesting
                    pass
        else:
            c_functions.append((name, addr, f))

    print("  ObjC methods: %d" % len(objc_methods))
    print("  C functions:  %d" % len(c_functions))
    print("  Target hits:  %d" % len(target_hits))

    # ================================================================
    # PHASE 2: Decompile ALL target hits (GetHTinfo_, CmdTxPower, etc.)
    # ================================================================
    print("\n[rtl] PHASE 2: Decompiling %d target function hits..." % len(target_hits))
    all_target_texts = []
    for name, addr, f, pat in target_hits:
        text = decompile_func(f, "%s_%s" % (pat, name.replace(":", "")))
        all_target_texts.append(text)
        print("  [HIT] %-60s %s  (matched: %s)" % (name[:60], hex(addr), pat))

    # Write combined target file
    combined_path = os.path.join(OUT, "all_targets_combined.txt")
    with open(combined_path, "wb") as fh:
        fh.write("\n\n".join(all_target_texts).encode("utf-8"))
    print("\n[rtl] Target methods written to", combined_path)

    # ================================================================
    # PHASE 3: List ALL ObjC methods organized by class
    # ================================================================
    print("\n[rtl] PHASE 3: ALL ObjC methods by class...")
    by_class = {}
    for name, addr, f in objc_methods:
        # Extract class name: "-[ClassName methodName:]" -> "ClassName"
        try:
            if name.startswith("-["):
                cls = name[2:].split(" ")[0]
            elif name.startswith("+["):
                cls = name[2:].split(" ")[0]
            else:
                cls = "(unknown)"
        except:
            cls = "(parse_error)"
        if cls not in by_class:
            by_class[cls] = []
        by_class[cls].append((name, addr))

    # Write class-organized listing
    listing = []
    for cls in sorted(by_class.keys()):
        methods = by_class[cls]
        listing.append("=== %s (%d methods) ===" % (cls, len(methods)))
        for name, addr in sorted(methods, key=lambda x: x[1]):
            listing.append("  %-8s  %s" % (hex(addr), name))
        listing.append("")

    listing_path = os.path.join(OUT, "all_objc_methods.txt")
    with open(listing_path, "wb") as fh:
        fh.write("\n".join(listing).encode("utf-8"))
    print("  Written to", listing_path)

    # Print target class methods
    for cls in sorted(by_class.keys()):
        if any(tc in cls for tc in TARGET_CLASSES):
            print("\n  --- %s ---" % cls)
            for name, addr in sorted(by_class[cls], key=lambda x: x[1]):
                print("    %-8s  %s" % (hex(addr), name))

    # ================================================================
    # PHASE 4: Scan target class functions for OIDs
    # ================================================================
    print("\n[rtl] PHASE 4: Scanning target class functions for OIDs...")
    oid_found_any = False
    for cls in sorted(by_class.keys()):
        if not any(tc in cls for tc in TARGET_CLASSES):
            continue
        for name, addr in sorted(by_class[cls], key=lambda x: x[1]):
            f = view.get_function_at(addr)
            if f is None:
                continue
            il = f.hlil or f.mlil
            if il is None:
                continue
            body_str = str(il)
            found = find_oids_in_body(body_str)
            if found:
                oid_found_any = True
                print("  %-60s -> %s" % (name[:60], ", ".join(found)))
    if not oid_found_any:
        print("  (no OID constants found - they may be passed as variables)")

    # ================================================================
    # PHASE 5: Also scan C functions in WLANClient section
    # ================================================================
    print("\n[rtl] PHASE 5: Scanning C functions for OIDs...")
    c_oid_any = False
    for name, addr, f in c_functions:
        if not any(kw in name for kw in ["Cmd", "Get", "Set", "Query", "_open", "_close"]):
            continue
        il = f.hlil or f.mlil
        if il is None:
            continue
        body_str = str(il)
        found = find_oids_in_body(body_str)
        if found:
            c_oid_any = True
            print("  %-50s -> %s" % (name[:50], ", ".join(found)))
    if not c_oid_any:
        print("  (no OID constants found in C functions)")

    # ================================================================
    # PHASE 6: Summary
    # ================================================================
    print("\n[rtl] PHASE 6: Summary")
    print("  Total functions:  %d" % len(list(view.functions)))
    print("  ObjC methods:     %d" % len(objc_methods))
    print("  C functions:      %d" % len(c_functions))
    print("  Target classes:   %s" % ", ".join(TARGET_CLASSES))
    print("  Target hits:      %d" % len(target_hits))
    print("  Output dir:       %s" % OUT)
    print("\n[rtl] DONE.")
