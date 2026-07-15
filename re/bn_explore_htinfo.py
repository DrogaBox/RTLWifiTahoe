# Binary Ninja console - HT Info RE
# FIXED: use view.symbols + view.strings (older BN API compat)
# Paste:
#   exec(open(".../re/bn_explore_htinfo.py").read(), globals())
#
# Targets:
#   GetHTinfo_BW    -> BW (20/40/80/160 MHz)
#   GetHTinfo_GI    -> Guard Interval (long/short)
#   GetHTinfo_MCS   -> MCS index (0-31)
#   GetRX / GetTX   -> Byte counters
#   CmdChannel      -> Channel set OID
#   CmdWirelessMode -> Wireless mode OID

import os

OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output")
try:
    os.makedirs(OUT)
except Exception:
    pass

SEARCH_SYMBOLS = [
    "GetHTinfo_BW", "GetHTinfo_GI", "GetHTinfo_MCS",
    "GetRX", "GetTX",
    "CmdChannel", "CmdWirelessMode", "CmdTxPower",
]

SELECTORS = [
    "GetHTinfo_BW", "GetHTinfo_GI", "GetHTinfo_MCS",
    "GetRX", "GetTX", "CmdTxPower", "CmdChannel", "CmdWirelessMode",
]

OIDS_TO_FIND = [0xFF818500, 0xFF010182, 0xFF81901D, 0xFF819024, 0xFF819025, 0xFF819026]

view = None
try: view = bv
except: pass
if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"):
            view = _v
            break

if view is None:
    print("[rtl] ERROR: no bv")
    print('  exec(open(".../re/bn_explore_htinfo.py").read(), globals())')
else:
    print("[rtl] Scanning for HT info and cmd symbols...")

    # Search by symbol name in view.symbols
    for sym_name in SEARCH_SYMBOLS:
        found = False
        for sym in view.symbols:
            if isinstance(sym, str):
                continue
            if not hasattr(sym, 'name') or not hasattr(sym, 'address'):
                continue
            if sym.name == sym_name or sym.name == "_" + sym_name:
                print("  %-25s @ %s  type=%s" % (sym_name, hex(sym.address), getattr(sym, 'type', '?')))
                f = view.get_function_at(sym.address)
                if f:
                    body = ""
                    if f.hlil:
                        body = str(f.hlil)
                    elif f.mlil:
                        body = str(f.mlil)
                    body_safe = body.encode("ascii", "replace").decode("ascii")
                    out_path = os.path.join(OUT, "sym_%s.txt" % sym_name)
                    with open(out_path, "wb") as fh:
                        fh.write(body_safe.encode("utf-8"))
                    print("           HLIL written (%d bytes)" % len(body_safe))
                else:
                    print("           No function")
                found = True
                break
        if not found:
            print("  %-25s NOT FOUND in symbols (searching strings...)" % sym_name)

    # String search via view.strings
    print("\n--- String search for selectors ---")
    all_strings = list(view.strings)
    for sel in SELECTORS:
        found = False
        for sr in all_strings:
            val = str(sr.value) if hasattr(sr, 'value') else str(sr)
            if sel in val:
                addr = hex(sr.address) if hasattr(sr, 'address') else "?"
                ctx = val[:80]
                print("  %-25s @ %s  %s" % (sel, addr, ctx))
                found = True
                break
        if not found:
            print("  %-25s NOT FOUND" % sel)

    # OID reference search
    print("\n--- OID references ---")
    for oid in OIDS_TO_FIND:
        hex_str = "0x%X" % oid
        count = 0
        first_addr = None
        for sr in all_strings:
            val = str(sr.value) if hasattr(sr, 'value') else str(sr)
            if hex_str in val or str(oid) in val:
                count += 1
                if first_addr is None:
                    first_addr = hex(sr.address) if hasattr(sr, 'address') else "?"
        extra = "  (first @ %s)" % first_addr if count > 0 else ""
        print("  %-20s found at %d string locations%s" % ("0x%08X" % oid, count, extra))

    print("\n[DONE] Check:", OUT)
