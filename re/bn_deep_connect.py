# Binary Ninja console - deep connect / radio RE (ASCII only)
# Paste:
#   exec(open("/Users/droga/Desktop/RTLWifiTahoe/re/bn_deep_connect.py").read(), globals())

import os

OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output")
try:
    os.makedirs(OUT)
except Exception:
    pass

TARGETS = [
    ("ApplyTheProfileAndTryToConnect", 0x100014C90),
    ("MenuItemClickToJoinNetwork", 0x100012790),
    ("setApplyProfileInfo", 0x100013B40),
    ("WirelessAssociate", 0x10001C7F0),
    ("SetWPAKey", 0x10001DF30),
    ("SetWEPKey", 0x10001D5D0),
    ("turnRfOn", 0x10001D530),
    ("turnRfOff", 0x10001D580),
    ("IsRfOff", 0x10001DCC0),
    ("MenuItemRadioOnOff", 0x100012200),
    ("CheckSoftRF", 0x1000083F0),
    ("NicIFLinkStatusWatchdog", 0x10000D650),
    ("ifconfig", 0x100002400),
    ("UpdateAssociatedNetwork", 0x100011080),
    ("startWpaSupplicant", 0x1000179A0),
    ("CmdPassphrase", 0x10003CE10),
    ("CmdAkm", 0x10003C770),
    ("CmdEnc", 0x10003CAA0),
    ("CmdSsid", 0x10003AE40),
    ("CmdScan", 0x10003D190),
    ("SetInformationBuffer", 0x10003EDA0),
    ("SetInformationValue", 0x10003EF70),
    ("openAdapter", 0x10003D900),
]


def decomp(view, name, addr):
    f = view.get_function_at(addr)
    if f is None:
        fs = view.get_functions_containing(addr)
        f = fs[0] if fs else None
    if f is None:
        return "## %s @ %s\nNO FUNCTION\n" % (name, hex(addr))
    body = None
    try:
        if f.hlil is not None:
            body = str(f.hlil)
    except Exception as e:
        body = "(hlil error: %s)" % e
    if body is None:
        try:
            body = str(f.mlil) if f.mlil else "(no il)"
        except Exception as e:
            body = "(mlil error: %s)" % e
    try:
        body.encode("ascii")
    except Exception:
        body = body.encode("ascii", "replace").decode("ascii")
    return "## %s\naddr: %s  bn_name: %s\n\n```c\n%s\n```\n" % (
        name, hex(f.start), f.name, body
    )


view = None
try:
    view = bv  # BN console injects bv
except Exception:
    pass

if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"):
            view = _v
            break

if view is None:
    print("[rtl] ERROR: no bv - click StatusBarApp tab, then:")
    print('  exec(open("/Users/droga/Desktop/RTLWifiTahoe/re/bn_deep_connect.py").read(), globals())')
else:
    print("[rtl] deep RE on", view.file.filename)
    chunks = []
    for name, addr in TARGETS:
        print("[rtl]", name, hex(addr))
        text = decomp(view, name, addr)
        chunks.append(text)
        path = os.path.join(OUT, "deep_%s.txt" % name)
        with open(path, "w") as fh:
            fh.write(text)
    out = os.path.join(OUT, "deep_connect_hlil.txt")
    with open(out, "w") as fh:
        fh.write("\n\n".join(chunks))
    print("[rtl] DONE", out)
    print("[rtl] Jump with g:")
    for name, addr in TARGETS[:10]:
        print(" ", hex(addr), name)
