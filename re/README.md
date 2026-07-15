# RTL Wi-Fi Tahoe — Reverse Engineering

Everything extracted from the Realtek StatusBarApp (`/Library/Application Support/WLAN/StatusBarApp.app`).

## Contents

### OID Map
- **[OID_MAP.md](./OID_MAP.md)** — Complete OID table: connect path, NET_INFO layout, signal/RSSI, key function addresses
- **[Sources/OIDConstants.swift](../Sources/OIDConstants.swift)** — All OID constants with inline RE notes (source of truth for the app)

### Connect Protocol
- **[WIRELESS_ASSOCIATE_PROTOCOL.md](./WIRELESS_ASSOCIATE_PROTOCOL.md)** — Full OID sequence for joining a network: SSID → passphrase → AKM → SetInformation → WirelessAssociate
- **[all_connect.asm](./all_connect.asm)** — Combined annotated IDA/BH disassembly of the entire driver connect path (CmdSsid → CmdPassphrase → CmdAkm → CmdEnc → CmdScan → SetInformation → WirelessAssociate)

### Individual Function ASM (standalone)
| File | Function | Address |
|------|----------|---------|
| [CmdSsid.asm](./CmdSsid.asm) | `-[WLANClientUtilityModel CmdSsid]` | `0x10003ae40` |
| [CmdPassphrase.asm](./CmdPassphrase.asm) | `-[WLANClientUtilityModel CmdPassphrase]` | `0x10003ce10` |
| [CmdAkm.asm](./CmdAkm.asm) | `-[WLANClientUtilityModel CmdAkm]` | `0x10003c770` |
| [CmdScan.asm](./CmdScan.asm) | `-[WLANClientUtilityModel CmdScan]` | `0x10003d190` |
| [CmdSetInformation.asm](./CmdSetInformation.asm) | `-[WLANClientUtilityModel CmdSetInformation]` | `0x10003eda0` |
| [WirelessAssociate.asm](./WirelessAssociate.asm) | `-[WLANClientUtilityModel WirelessAssociate:]` | `0x10001c7f0` |
| [SetInformationBuffer.asm](./SetInformationBuffer.asm) | SetInformation with buffer (OID + raw data) | `0x10003eda0` |
| [SetInformationValue.asm](./SetInformationValue.asm) | SetInformation with UInt32 value | `0x10003ef70` |
| [SetInformation_Buffer_Length.asm](./SetInformation_Buffer_Length.asm) | SetInformation helper (buffer variant) | `0x10001e770` |
| [SetInformation_Value.asm](./SetInformation_Value.asm) | SetInformation helper (value variant) | `0x10001e420` |

### Binary Ninja Scripts

Run from BN Python console:
```python
exec(open("/path/to/repo/re/SCRIPT.py").read(), globals())
```

| Script | Purpose |
|--------|---------|
| [bn_full_autoscan.py](./bn_full_autoscan.py) | Decompile all 36 known functions, scan for OID references, auto-discover unknown Cmd\* methods |
| [bn_ultimate_re.py](./bn_ultimate_re.py) | Full binary analysis: categorize all 4462 functions, decompile 28 target methods, list all ObjC methods per class, scan for OIDs in every target |
| [bn_connect_path.py](./bn_connect_path.py) | Deep-dive into the connect path: WirelessAssociate, CmdSsid, CmdPassphrase, CmdAkm |
| [bn_deep_connect.py](./bn_deep_connect.py) | HLIL decompile + OID scanning of connect-path functions |
| [bn_explore_enterprise.py](./bn_explore_enterprise.py) | WPA-Enterprise / wpa_supplicant integration: startWpaSupplicant, CreateWpaSupplicantConf, 802.1X field initialization, socket server |
| [bn_explore_htinfo.py](./bn_explore_htinfo.py) | HT info (BW/GI/MCS), channel, wireless mode, TX/RX counters, TX power, USB switch — string search + OID references |
| [bn_explore_txpower_usb.py](./bn_explore_txpower_usb.py) | Cmd\* function discovery, USB switch (U2/U3), power table, locale, WPS hardware button |

### Decompiled Output
- **[bn_gui_output/full_autoscan/](./bn_gui_output/full_autoscan/)** — Individual HLIL decompilations of all 36 known functions + combined text
- **[bn_gui_output/ultimate/](./bn_gui_output/ultimate/)** — Decompiled target methods + all ObjC methods organized by class

### WIP / Notes
- **[WIP.md](./WIP.md)** — Deferred features and technical notes (WPA3/SAE, full WSC, etc.)

## Source Implementation

The app implementation derived from this RE is in:
- **[Sources/OIDConstants.swift](../Sources/OIDConstants.swift)** — All discovered OIDs as typed Swift constants with documentation
- **[Sources/RealtekDriver.swift](../Sources/RealtekDriver.swift)** — Driver communication: open/close, OID query/set, connect, scan, radio control, WPS, NET_INFO parser

## Key OID Reference

| OID | Constant | Purpose |
|-----|----------|---------|
| `0x0D010206` | `OID_RT_SIGNAL_STRENGTH` | Signal quality 0–100 (getSignalStrength) |
| `0x0D010101` | `OID_802_11_BSSID` | BSSID set |
| `0x0D010108` | `OID_802_11_INFRASTRUCTURE_MODE` | Network type: 0=infra, 1=adhoc, 3=auto |
| `0x0D010115` | `OID_802_11_DISASSOCIATE` | Disconnect / leave BSS |
| `0xFF010182` | `OID_RT_CHANNEL` | Channel set/get |
| `0xFF010194` | `OID_RT_AKM` | Authentication: 0=open, 3=WPA, 6=WPA2 |
| `0xFF010305` | `OID_RT_PASSPHRASE` | Passphrase buffer (0x98 bytes) |
| `0xFF01041B` | `OID_RT_CONNECT` | Connect trigger (write 0) |
| `0xFF070102` | `OID_RT_SSID` | SSID buffer (0x84 bytes) |
| `0xFF818081` | `OID_RT_RF` | Radio: 0=on, 1=off |
| `0xFF819053` | `OID_RT_LINK_FLAG` | Link status flag (non-zero = linked) |
| `0xFF81901D` | `OID_RT_LINK_RATE` | Link rate in Mbps |
| `0xFF819029` | `OID_RT_WPS_HW_PBC` | WPS hardware button flag |
| `0x00010114` | `OID_RT_CONNECTION_STATUS` | Connection status (0=disconnected, 1=connected) |

## Driver Interface

- **IOKit matching**: `IOEthernetController` with class prefix `RtWlanU*`
- **Command buffer size**: `0x9D4` bytes
- **Selectors**: 9 = Query OID, 10 = Set OID, 0 = GetNetworkAtIndex
- **OID buffer layout**: `[0x00] OID, [0x04] data length, [0x08] returned data length, [0x0C] reserved, [0x10] data payload`
- **NET_INFO (scan result) size**: `0x640` bytes
- **Connect sequence**: RF on → disassociate → set infra mode → set SSID → set channel → set AKM → set passphrase → set connect trigger → poll link
