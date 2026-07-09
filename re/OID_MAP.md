# RtWlanU / StatusBarApp — OID & function map (RE)

## UserClient
- Match: `IOEthernetController` / class `RtWlanU*`
- Struct size: `0x9d4`
- Sel **9** = Query, **10** = Set, **0** = GetNetworkAtIndex (`0x640`)

## Connect path (MacAccess CLI order)
| Step | OID | Notes |
|------|-----|--------|
| RF on | `0xFF818081` = **0** | off = **1** (byte query) |
| Soft RF file | `<mac>rfoff.rtl` | **`bRfOff`**: `"0\n"`=ON `"1\n"`=OFF (BN MenuItemRadioOnOff) |
| Disassociate | `0x0D010115` | Leave BSS (Disconnect button) |
| Infra | `0x0D010108` = **0** (adhoc=1, auto=3) | |
| BSSID | `0x0D010101` | **only real MAC** — skip scan keys with U/L bit (0e…) |
| Channel | `0xFF010182` | from NET_INFO **[0x23]** |
| AKM/Enc | `0xFF010194` | 0 open, 3 wpa-psk, 6 wpa2/aes |
| Shared flag | `0xFF01041A` | 0 normal |
| Passphrase | `0xFF010305` buf `0x98` | key@0, len@0x80 |
| SSID | `0xFF070102` buf `0x84` | ssid@0, len@0x80 |
| Connect | `0xFF01041B` = 0 | |

## NET_INFO `0x640` (GetNetworkAtIndex)
| Off | Field |
|-----|--------|
| 0 | SSID bytes |
| 0x21 | SSID length |
| **0x23** | **Channel** (7, 36, 149, 157…) |
| 0x24–0x29 | Scan-table BSSID key (often ≠ real AP MAC) |
| 0x2A | Signal 0–100 |
| later | WPS IE; real MAC after `0xFE` |
| later | Beacon/probe IEs: HT Cap `0x2D` (Wi‑Fi 4), VHT Cap `0xBF` (Wi‑Fi 5), HE Cap ext `35` (Wi‑Fi 6), EHT ext `108` (Wi‑Fi 7) |

## Private FF819* (from NicIFLinkStatusWatchdog) — live query sample
| OID | Sample | Guess |
|-----|--------|--------|
| `0xFF819053` | 0 | **link / assoc flag** (watchdog checks byte ≠ 0) |
| `0xFF819048` | 4 | status code? |
| `0xFF819055` | 1 | flag |
| `0xFF81901D` | 867 | **link rate Mbps** (live when associated) |
| `0xFF81902B` | 867 | same / alt link rate |
| `0xFF818081` | 0 | RF on |

## Signal / RSSI (confirmed BN + live)
| OID | Role |
|-----|------|
| **`0x0D010206`** | **Signal strength 0…100** — `-[WLANClientUtilityModel getSignalStrength]` + MacAccess `-rssi` (`RSSI: %d`). Live e.g. `100` when strong. |
| `0x0D010106` | Does **not** return useful RSSI on this stack (often 0). |
| NET_INFO `[0x2A]` | Per-BSS signal in scan list (same 0…100 scale). |

## Key functions (jump in BN with `g`)
| Address | Name |
|---------|------|
| `0x100014c90` | `ApplyTheProfileAndTryToConnect` |
| `0x100012790` | `MenuItemClickToJoinNetwork:` |
| `0x10001c7f0` | `WirelessAssociate:` |
| `0x10001df30` | `SetWPAKey:` |
| `0x10000d650` | `NicIFLinkStatusWatchdog` ← OID `0xFF819053` |
| `0x100002400` | `ifconfig:` (sudo ifconfig up/down) |
| `0x100012200` | `MenuItemRadioOnOff:` |
| `0x10001d530` | `turnRfOn` |
| `0x10003d900` | `openAdapter` |
| `0x100011080` | `UpdateAssociatedNetwork` |
| `0x1000179a0` | `startWpaSupplicant` (enterprise/WPA3) |

## WPA3 / SAE — WIP (deferred)

**Status:** Not implemented in Tahoe. **Do only if a real WPA3-only AP is needed.**

- StatusBarApp path: `profile1x.rtl` + `wpa_supplicant` (not pure OID passphrase).
- Tahoe today: WPA2-PSK OIDs — enough for WPA2 and most mixed APs.
- Details / decision log: **`re/WIP.md`**

## BN script
```
exec(open("/Users/droga/Desktop/RTLWifiTahoe/re/bn_deep_connect.py").read(), globals())
```
Output: `~/Desktop/RTLWifiTahoe/re/bn_gui_output/deep_connect_hlil.txt`

## Known join failure mode (our logs)
All connect OIDs return OK, kext SSID set, but:
- `IOLinkSpeed=0`, media inactive, `rssi=0`, `0xFF819053=0`
- Wrong channel (e.g. 80) or pinning scan-key BSSID (`0e84…` vs real `0c84…`) makes this worse
