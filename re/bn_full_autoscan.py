# Binary Ninja console - Full auto-scan
# Paste: exec(open(".../re/bn_full_autoscan.py").read(), globals())
#
# Fixes:
#   - view.symbols can yield strings not Symbol objects (guard with hasattr)
#   - BN HLIL formats hex as 0x1BFFFFFF instead of 0x00FFFFFF (substring search)

import os

OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output/full_autoscan")
try:
    os.makedirs(OUT)
except Exception:
    pass

# -- KNOWN addresses from previous RE (OID_MAP.md + all_connect.asm) --
KNOWN = [
    # Core connect path
    ("WirelessAssociate",           0x10001C7F0),
    ("SetWPAKey",                   0x10001DF30),
    ("SetWEPKey",                   0x10001D5D0),
    ("SetInformation_Buffer_Length",0x10001E770),
    ("SetInformation_Value",        0x10001E420),
    ("CmdSsid",                     0x10003AE40),
    ("CmdPassphrase",               0x10003CE10),
    ("CmdAkm",                      0x10003C770),
    ("CmdEnc",                      0x10003CAA0),
    ("CmdScan",                     0x10003D190),
    ("SetInformationBuffer",        0x10003EDA0),
    ("SetInformationValue",         0x10003EF70),

    # Radio / power
    ("turnRfOn",                    0x10001D530),
    ("turnRfOff",                   0x10001D580),
    ("IsRfOff",                     0x10001DCC0),
    ("MenuItemRadioOnOff",          0x100012200),
    ("CheckSoftRF",                 0x1000083F0),
    ("ifconfig",                    0x100002400),

    # Link / status
    ("NicIFLinkStatusWatchdog",     0x10000D650),
    ("UpdateAssociatedNetwork",     0x100011080),
    ("UpdateDeassociatedNetwork",   0x1000113A0),
    ("MenuItemDeleteProfile",       0x100012860),

    # WPS
    ("MenuItemWPS",                 0x100012950),
    ("WpsCtrl_PollingHwPBC",        0x100017390),
    ("WpsWinCtrl_Update_WPS_Scan_List", 0x100017A50),

    # Supplicant
    ("startWpaSupplicant",          0x1000179A0),

    # Menu
    ("MenuItemClickToJoinNetwork",  0x100012790),
    ("MenuItemDiagnosticsTool",     0x100013C70),
    ("MenuItemEditPreferredNetworks",0x100013D00),
    ("MenuItemUninstall",           0x100013DD0),

    # App
    ("openAdapter",                 0x10003D900),
    ("DriverServiceOpen",           0x10003D810),
    ("DriverServiceClose",          0x10003D870),

    # Apply profile
    ("ApplyTheProfileAndTryToConnect", 0x100014C90),
    ("setApplyProfileInfo",         0x100013B40),
    ("DoDefaultProfilesApply",      0x100014B10),
]

# -- KNOWN OIDs to search for (search as BOTH exact and partial hex) --
# BN HLIL typically formats 32-bit hex as 0xAABBCCDD (no leading zeros).
# We search for both the exact string and a "fuzzy" version (last 6 hex digits).
OID_SEARCH = [
    ("OID_RT_SET_SCAN",         0xFF07011A),
    ("OID_RT_GET_SCAN_IN_PROGRESS", 0xFF0101BD),
    ("OID_BSS_NUMBER",          0xFF010419),
    ("OID_RT_SSID",             0xFF070102),
    ("OID_RT_PASSPHRASE",       0xFF010305),
    ("OID_RT_AKM",              0xFF010194),
    ("OID_RT_SHARED_KEY_FLAG",  0xFF01041A),
    ("OID_RT_CONNECT",          0xFF01041B),
    ("OID_802_11_DISASSOCIATE", 0x0D010115),
    ("OID_802_11_INFRASTRUCTURE_MODE", 0x0D010108),
    ("OID_RT_ADHOC_WPA_FLAG",   0xFF030004),
    ("OID_RT_CHANNEL",          0xFF010182),
    ("OID_802_11_BSSID",        0x0D010101),
    ("OID_RT_RF",               0xFF818081),
    ("OID_RT_SIGNAL_STRENGTH",  0x0D010206),
    ("OID_RT_WIRELESS_MODE",    0xFF818500),
    ("OID_RT_NIC_STATUS",       0xFF010418),
    ("OID_RT_LINK_FLAG",        0xFF819053),
    ("OID_RT_CONNECTION_STATUS",0x00010114),
    ("OID_RT_WPS_HW_PBC",       0xFF819029),
    ("OID_RT_LINK_RATE",        0xFF81901D),
    ("OID_RT_WEP_KEY",          0xFF070113),
]

def oid_hex_strings(oid_val):
    """Return possible hex string representations of an OID."""
    results = []
    results.append("0x%X" % oid_val)               # compact: 0xFF818081
    results.append("0x%08X" % oid_val)              # zero-padded: 0x0D010206
    results.append(hex(oid_val))                    # python default: 0xff818081
    # Also try with leading 0x00... patterns BN sometimes uses
    results.append("0x%04X" % oid_val)
    return results

view = None
try: view = bv
except: pass
if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"):
            view = _v
            break

def decompile_and_save(view_obj, name, addr):
    """Try to get HLIL (or MLIL) for a function and save to file."""
    f = view_obj.get_function_at(addr)
    if f is None:
        fs = view_obj.get_functions_containing(addr)
        f = fs[0] if fs else None
    if f is None:
        return "## %s @ %s\nNO FUNCTION FOUND\n" % (name, hex(addr))
    try:
        if f.hlil:
            body = str(f.hlil)
        elif f.mlil:
            body = str(f.mlil)
        else:
            body = "(no IL)"
    except Exception as e:
        body = "(error: %s)" % e
    text = "## %s\naddr: %s  bn_name: %s\n\n```c\n%s\n```\n" % (name, hex(f.start), f.name, body)
    path = os.path.join(OUT, "%s.txt" % name.replace("/", "_").replace(":", ""))
    with open(path, "w") as fh:
        fh.write(text)
    return text

def find_oids_in_body(body_str):
    """Search body_str for any known OID hex representations."""
    found = []
    for oid_name, oid_val in OID_SEARCH:
        for h in oid_hex_strings(oid_val):
            if h in body_str:
                found.append(oid_name)
                break
    return found

if view is None:
    print("[rtl] ERROR: no bv - click StatusBarApp tab, then paste again.")
    print('  exec(open(".../re/bn_full_autoscan.py").read(), globals())')
else:
    print("[rtl] === FULL AUTOSCAN ===")
    print("[rtl] view:", view.file.filename if hasattr(view, 'file') else "?")
    print("[rtl] Known functions:", len(KNOWN))

    # ============ PHASE 1: Decompile ALL known targets ============
    print("\n[rtl] PHASE 1: Decompiling %d known functions..." % len(KNOWN))
    all_chunks = []
    for name, addr in KNOWN:
        text = decompile_and_save(view, name, addr)
        all_chunks.append(text)
        print("  %-45s %s" % (name, hex(addr)))

    combined_path = os.path.join(OUT, "full_autoscan_combined.txt")
    with open(combined_path, "w") as fh:
        fh.write("\n\n".join(all_chunks))
    print("\n[rtl] Combined written to", combined_path)

    # ============ PHASE 2: Find OID references in each function ============
    print("\n[rtl] PHASE 2: Scanning functions for known OIDs...")
    oid_any = False
    for name, addr in KNOWN:
        f = view.get_function_at(addr)
        if f is None:
            continue
        il = f.hlil or f.mlil
        if il is None:
            continue
        body_str = str(il)
        found_oids = find_oids_in_body(body_str)
        if found_oids:
            oid_any = True
            print("  %-45s -> %s" % (name, ", ".join(found_oids)))
    if not oid_any:
        print("  (no OID constants found in HLIL - this is normal if args are passed as variables)")

    # ============ PHASE 3: Auto-discover NEW functions via symbols ============
    print("\n[rtl] PHASE 3: Auto-discovering unknown Cmd* and ObjC methods...")
    known_addrs = set(addr for _, addr in KNOWN)
    discovered = 0
    keywords = ["Cmd", "WPS", "WSC", "MenuItem", "Apply", "GetHT",
                "GetBSSID", "GetConnection", "WlanCLI",
                "GetRX", "GetTX", "GetChannel", "GetDriver",
                "SetPwr", "PowerTable", "USBSwitch",
                "DisableCmd", "EnableCmd", "GetNetworkName",
                "GetSupported", "GetWPS"]

    # view.symbols can yield Symbol objects OR bare strings depending on BN version
    raw_symbols = []
    try:
        raw_symbols = list(view.symbols)
    except Exception:
        print("  (could not iterate view.symbols)")

    for sym in raw_symbols:
        # Guard: sym might be a bare string in some BN API versions
        if isinstance(sym, str):
            continue
        if not hasattr(sym, 'address') or not hasattr(sym, 'name'):
            continue
        if sym.address in known_addrs:
            continue
        name = sym.name
        # Skip standard library symbols
        if name.startswith("_") and not name.startswith("_Cmd") and not name.startswith("_WPS") and not name.startswith("_WSC"):
            continue
        # Check if name contains any of our keywords
        match = False
        for kw in keywords:
            if kw in name:
                match = True
                break
        if not match:
            continue
        # Check symbol type
        sym_type = getattr(sym, 'type', None)
        if sym_type not in ("FunctionSymbol", "ImportedFunctionSymbol", None):
            continue
        if isinstance(sym.address, int) and sym.address > 0 and sym.address < 0x200000:
            f = view.get_function_at(sym.address)
            if f:
                text = decompile_and_save(view, name, sym.address)
                discovered += 1
                print("  [NEW] %-50s %s" % (name[:50], hex(sym.address)))

    print("\n[rtl] Discovered %d new functions" % discovered)
    print("[rtl] ALL DONE. Results in:", OUT)
