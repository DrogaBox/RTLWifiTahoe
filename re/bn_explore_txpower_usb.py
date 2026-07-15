# Binary Ninja console - Tx Power, USB 2.0/3.0 Switch, Channel List RE
# FIXED: use view.symbols (with type guard) + view.strings (older BN API compat)
# Paste: exec(open(".../re/bn_explore_txpower_usb.py").read(), globals())
# Targets:
#   CmdTxPower        -> Tx power OID + range
#   SetPwrTableByLocale -> Country-specific power tables
#   USBSwitch_U2ToU3: -> USB 2.0->3.0 switch OID
#   USBSwitch_U3ToU2  -> USB 3.0->2.0 switch OID
#   IsRTL8180Enabled  -> Chip detection
#   CmdChannel         -> Channel set OID
#   GetWPSHwPBC        -> WPS hardware button OID (already implemented)

import os
OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output")
try: os.makedirs(OUT)
except: pass

view = None
try: view = bv
except: pass
if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"):
            view = _v
            break

if view is None:
    print("[rtl] ERROR: no bv. Click StatusBarApp tab, then paste again.")
else:
    print("[rtl] Scanning for Cmd* functions (MacAccess CLI handlers)...")

    # 1) Find ALL Cmd* symbols and their addresses (via view.symbols with type guard)
    for sym in view.symbols:
        if isinstance(sym, str):
            continue
        if not hasattr(sym, 'name') or not hasattr(sym, 'address'):
            continue
        name = sym.name
        if not (name.startswith("Cmd") or name.startswith("_Cmd")):
            continue
        display_name = name.replace("_", "")
        addr = sym.address
        print("  %-30s @ %s type=%s" % (display_name, hex(addr), getattr(sym, 'type', '?')))
        f = view.get_function_at(addr)
        if f:
            body = str(f.hlil) if f.hlil else str(f.mlil) if f.mlil else "(no IL)"
            path = os.path.join(OUT, "sym_%s.txt" % name.replace(":", ""))
            with open(path, "w") as fh:
                fh.write("## %s @ %s\n\n```c\n%s\n```\n" % (name, hex(addr), body))

    # 2) Also find class-dump symbols for USB switch (via view.symbols search)
    print("\n[rtl] Searching for USB switch symbols...")
    feature_symbols = ["USBSwitch_U2ToU3", "USBSwitch_U3ToU2", "USBSwitch_bNicInU3",
                       "IsRTL8180Enabled", "GetWPSHwPBC", "SetPwrTableByLocale",
                       "DecryptPwrTable", "GetSystemUSB3Cap",
                       "CmdTxPower", "CmdChannel"]

    # First pass: look in view.symbols
    found_in_symbols = set()
    for sym in view.symbols:
        if isinstance(sym, str):
            continue
        if not hasattr(sym, 'name') or not hasattr(sym, 'address'):
            continue
        for fs in feature_symbols:
            if sym.name == fs or sym.name == "_" + fs:
                addr = sym.address
                print("  %-30s @ %s" % (fs, hex(addr)))
                found_in_symbols.add(fs)
                f = view.get_function_at(addr)
                if f:
                    body = str(f.hlil) if f.hlil else str(f.mlil) if f.mlil else "(no IL)"
                    path = os.path.join(OUT, "feature_%s.txt" % fs)
                    with open(path, "w") as fh:
                        fh.write("## %s @ %s\n\n```c\n%s\n```\n" % (fs, hex(addr), body))

    # Second pass: find remaining via view.strings
    not_found = [s for s in feature_symbols if s not in found_in_symbols]
    if not_found:
        print("\n[rtl] Searching for remaining via strings...")
        for sr in view.strings:
            val = str(sr.value) if hasattr(sr, 'value') else str(sr)
            for fs in list(not_found):  # iterate over copy
                if fs in val:
                    addr = hex(sr.address) if hasattr(sr, 'address') else "?"
                    print("  '%s' found in strings @ %s" % (fs, addr))
                    not_found.remove(fs)

        for fs in not_found:
            print("  '%s' NOT FOUND" % fs)

    print("\n[DONE] Results in", OUT)
