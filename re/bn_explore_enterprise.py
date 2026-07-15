# Binary Ninja console - Enterprise 802.1X + wpa_supplicant RE
# FIXED: use bv.strings instead of bv.find_text() (older BN API compat)
# Paste:
#   exec(open(".../re/bn_explore_enterprise.py").read(), globals())
#
# Targets:
#   startWpaSupplicant @ 0x1000179A0
#   stopWpaSupplicant  @ 0x100018070
#   CreateWpaSupplicantConf:
#   eapAuthentication:
#   certificateContentFrom*:
#   Init8021XField / fieldGen_8021x*

import os
OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output")
try: os.makedirs(OUT)
except: pass

TARGETS = [
    ("startWpaSupplicant", 0x1000179A0),
    ("stopWpaSupplicant", 0x100018070),
]

SEARCH = [
    "eapAuthentication:", "startWpaSupplicant", "CreateWpaSupplicantConf:",
    "Init8021XField", "supplicantSocketDataReceived:",
    "profile1x.rtl", "sae_password", "key_mgmt=SAE", "key_mgmt=WPA-EAP",
    "ca_cert", "client_cert", "private_key", "identity=", "eap=PEAP",
    "eap=TLS", "eap=TTLS", "phase2=",
    "/var/tmp", "com.realtek.utility.statusbar.socket",
]

view = None
try: view = bv
except: pass
if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"): view = _v

if view is None:
    print("[rtl] ERROR: no bv")
else:
    # Decompile known addrs
    for name, addr in TARGETS:
        f = view.get_function_at(addr)
        if f is None:
            fs = view.get_functions_containing(addr)
            f = fs[0] if fs else None
        if f:
            body = str(f.hlil or f.mlil or "(no IL)")
            path = os.path.join(OUT, "enterprise_%s.txt" % name)
            with open(path, "wb") as fh:
                fh.write(body.encode("utf-8"))
            print("  %-40s decompiled (%d bytes)" % (name, len(body)))
        else:
            print("  %-40s NO FUNCTION" % name)

    # String search via bv.strings (compatible with all BN versions)
    print("\n--- String search ---")
    try:
        all_strings = list(view.strings)
    except Exception:
        # Fallback: try get_strings
        all_strings = list(view.get_strings()) if hasattr(view, 'get_strings') else []

    for s in SEARCH:
        found = False
        for sr in all_strings:
            val = str(sr.value) if hasattr(sr, 'value') else str(sr)
            if s in val:
                addr = hex(sr.address) if hasattr(sr, 'address') else "?"
                ctx = val[:80]
                print("  %-35s @ %s  %s" % (s, addr, ctx))
                found = True
                break
        if not found:
            print("  %-35s NOT FOUND" % s)

    print("\n[DONE]")
