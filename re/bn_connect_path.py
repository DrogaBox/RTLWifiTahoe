# Binary Ninja UI Python Console - run with:
#   exec(open("/Users/droga/Desktop/RTLWifiTahoe/re/bn_connect_path.py").read(), globals())
#
# Needs active tab = StatusBarApp so console global "bv" exists.

import os

OUT = os.path.expanduser("~/Desktop/RTLWifiTahoe/re/bn_gui_output")
try:
    os.makedirs(OUT)
except Exception:
    pass

TARGETS = [
    ("WirelessAssociate", 0x10001C7F0),
    ("SetInformation_Buffer_Length", 0x10001E770),
    ("CmdSsid", 0x10003AE40),
    ("CmdSetInformation", 0x10003C1E0),
    ("CmdAkm", 0x10003C770),
    ("CmdPassphrase", 0x10003CE10),
    ("CmdScan", 0x10003D190),
    ("SetInformationBuffer", 0x10003EDA0),
    ("SetInformationValue", 0x10003EF70),
]

KNOWN = """
OID map (StatusBarApp -> RtWlanU UserClient sel 9=Query, 10=Set, struct 0x9d4):

  0xFF07011A  SET scan start
  0xFF0101BD  GET scan in progress
  0xFF010419  GET BSS count
  0xFF070102  GET/SET SSID   buffer 0x84 (ssid@0, len@0x80)
  0xFF010305  SET passphrase buffer 0x98 (key@0, len@0x80, pad@0x84=0)
  0xFF010194  SET/GET AKM    0=open, 3=wpa-psk, 6=wpa2-psk
  0xFF01041A  SET sharedkey flag  0=normal, 1=sharedkey
  0xFF01041B  SET connect/link trigger (value 0)
  0x0D010115  SET disassociate
  0x0D010108  SET infrastructure mode
  0xFF030004  SET (WEP/special path in WirelessAssociate)
"""

# Resolve BinaryView from console
view = None
try:
    view = bv  # noqa: F821  - injected by BN console
except Exception:
    pass
if view is None:
    for _k, _v in list(globals().items()):
        if type(_v).__name__ in ("BinaryView", "MachoView", "CoreBinaryView"):
            view = _v
            break

if view is None:
    print("[rtl] ERROR: no bv. Click the StatusBarApp tab, then:")
    print('  exec(open("/Users/droga/Desktop/RTLWifiTahoe/re/bn_connect_path.py").read(), globals())')
else:
    print("[rtl] view =", view)
    try:
        print("[rtl] file =", view.file.filename)
    except Exception:
        pass

    def decompile_one(name, addr):
        f = view.get_function_at(addr)
        if f is None:
            try:
                fs = view.get_functions_containing(addr)
                f = fs[0] if fs else None
            except Exception:
                f = None
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
                if f.mlil is not None:
                    body = str(f.mlil)
            except Exception as e:
                body = "(mlil error: %s)" % e
        if body is None:
            body = "(no IL)"
        try:
            body.encode("ascii")
        except Exception:
            body = body.encode("ascii", "replace").decode("ascii")
        return "## %s\naddr: %s  name: %s\n\n```c\n%s\n```\n" % (
            name, hex(f.start), f.name, body
        )

    chunks = [KNOWN, "file: %s\n" % getattr(getattr(view, "file", None), "filename", "?")]
    for name, addr in TARGETS:
        print("[rtl]", name, "@", hex(addr))
        text = decompile_one(name, addr)
        chunks.append(text)
        path = os.path.join(OUT, "%s.txt" % name.replace(":", "_"))
        with open(path, "w") as fh:
            fh.write(text)
    out_path = os.path.join(OUT, "connect_path_hlil.txt")
    with open(out_path, "w") as fh:
        fh.write("\n\n".join(chunks))
    print("[rtl] DONE wrote", out_path)
