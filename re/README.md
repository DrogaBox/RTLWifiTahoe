# RTL Wi-Fi Tahoe — Reverse Engineering

Everything extracted from the Realtek StatusBarApp driver (`/Library/Application Support/WLAN/StatusBarApp.app`).

## What's Here

### OID Reference
- **[OID_MAP.md](./OID_MAP.md)** — Complete table of discovered OIDs: connect path, NET_INFO layout, signal/RSSI, key function addresses
- **[Sources/OIDConstants.swift](../Sources/OIDConstants.swift)** — All OID constants as typed Swift constants with documentation

### Connect Protocol
- **[WIRELESS_ASSOCIATE_PROTOCOL.md](./WIRELESS_ASSOCIATE_PROTOCOL.md)** — Full OID sequence for joining a network: SSID → passphrase → AKM → SetInformation → WirelessAssociate

### Decompiled Function Output
- **[bn_gui_output/full_autoscan/](./bn_gui_output/full_autoscan/)** — Decompiled output of all 36 documented driver functions (connect, scan, radio, WPS, etc.)
- **[bn_gui_output/ultimate/](./bn_gui_output/ultimate/)** — Decompiled target methods plus all ObjC methods organized by class

## Key OID Reference

| OID | Constant | Purpose |
|-----|----------|---------|
| `0x0D010206` | `OID_RT_SIGNAL_STRENGTH` | Signal quality 0–100 |
| `0x0D010101` | `OID_802_11_BSSID` | BSSID set |
| `0x0D010108` | `OID_802_11_INFRASTRUCTURE_MODE` | Network type: 0=infra, 1=adhoc, 3=auto |
| `0x0D010115` | `OID_802_11_DISASSOCIATE` | Disconnect / leave BSS |
| `0xFF010182` | `OID_RT_CHANNEL` | Channel set/get |
| `0xFF010194` | `OID_RT_AKM` | Authentication: 0=open, 3=WPA, 6=WPA2 |
| `0xFF010305` | `OID_RT_PASSPHRASE` | Passphrase buffer (0x98 bytes) |
| `0xFF01041B` | `OID_RT_CONNECT` | Connect trigger |
| `0xFF070102` | `OID_RT_SSID` | SSID buffer (0x84 bytes) |
| `0xFF818081` | `OID_RT_RF` | Radio: 0=on, 1=off |
| `0xFF819053` | `OID_RT_LINK_FLAG` | Link status flag |
| `0xFF81901D` | `OID_RT_LINK_RATE` | Link rate in Mbps |
| `0xFF819029` | `OID_RT_WPS_HW_PBC` | WPS hardware button flag |
| `0x00010114` | `OID_RT_CONNECTION_STATUS` | Connection status |

## Driver Interface

- **IOKit matching**: `IOEthernetController` with class prefix `RtWlanU*`
- **Command buffer size**: `0x9D4` bytes
- **Selectors**: 9 = Query OID, 10 = Set OID, 0 = GetNetworkAtIndex
- **OID buffer layout**: `[0x00] OID, [0x04] data length, [0x08] returned data length, [0x0C] reserved, [0x10] data payload`
- **NET_INFO (scan result) size**: `0x640` bytes
- **Connect sequence**: RF on → disassociate → set infra mode → set SSID → set channel → set AKM → set passphrase → set connect trigger → poll link
