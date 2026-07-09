# RTL Wi-Fi Tahoe

Menu bar client for **Realtek USB Wi-Fi** on macOS (`RtWlanU.kext`).  
Talks to the driver through its IOKit UserClient—no dependency on the classic StatusBarApp for day-to-day scan and join.

<p align="center">
  <img src="docs/screenshot-status.png" alt="RTL Wi-Fi Tahoe — Status panel" width="320" />
</p>

---

## Overview

| | |
|---|---|
| **Platform** | macOS 13+ |
| **UI** | Menu bar accessory (`LSUIElement`), SwiftUI popover |
| **Driver** | `RtWlanU` (third-party USB stack; kext must be loaded) |
| **Connect path** | Native OIDs (WPA2-PSK / open) via reverse-engineered UserClient |
| **Author** | [DrogaBox](https://github.com/DrogaBox) |

---

## Features

**Status**

- Live SSID, IPv4, netmask (CIDR), gateway, DNS, internet reachability  
- Signal quality from driver OID `0x0D010206` (0–100%), link rate, channel  
- Router identification (OUI + lightweight HTTP fingerprint)  
- Nearby network list with band (2.4 / 5 GHz) and generation (Wi-Fi 4–7)  
- Disconnect, copy IP, join panel  

**Profiles**

- Saved Realtek profiles (`ProfilesList.plist`)  
- Forget network (clears password + `profile1x.rtl` SAE file + last network)  
- DNS presets: DHCP, Cloudflare, Google, Quad9, AdGuard, OpenDNS  

**Pro**

- UI themes (Power Gadget–aligned palette, Tahoe Cyan, Midnight, Ember, Matrix, Rose)  
- Auto-reconnect after wake / link loss  
- Nearby scan toggle, launch at login, quit classic StatusBarApp  

**Localization**

- English source + Spanish; Crowdin-ready (`crowdin.yml`, `Resources/*.lproj`)

---

## Requirements

1. macOS 13 or later  
2. Realtek USB Wi-Fi adapter with **`RtWlanU.kext` loaded**  
3. No need for StatusBarApp as a login item for normal use  

WPA3-only (SAE) networks are **not** implemented yet; see `re/WIP.md`.

---

## Build

```bash
./scripts/build.sh
cp -R "build/RTL Wi-Fi Tahoe.app" /Applications/
open -a "RTL Wi-Fi Tahoe"
```

Produces an ad-hoc signed app bundle under `build/`.

---

## Project layout

```
Sources/           SwiftUI app + RealtekDriver UserClient
Resources/         AppIcon, en.lproj / es.lproj
scripts/build.sh   Compile + bundle
re/                OID map, reverse-engineering notes, WIP
docs/              Screenshots
crowdin.yml        Localization pipeline
```

---

## Reverse engineering notes

Driver protocol and deferred work:

- [`re/OID_MAP.md`](re/OID_MAP.md) — UserClient selectors, OIDs, NET_INFO layout  
- [`re/WIP.md`](re/WIP.md) — WPA3 / WPS deferred scope  
- [`Resources/Localization.md`](Resources/Localization.md) — Crowdin workflow  

---

## Privacy

Passwords stay in Realtek’s profile store formats. They are never shown in the UI.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Disclaimer

This project interfaces with a third-party kernel extension. Use at your own risk.  
It is not affiliated with Realtek Semiconductor Corp. or Apple Inc.
