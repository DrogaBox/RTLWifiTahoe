import Foundation

// MARK: - OID constants for RtWlanU UserClient protocol
//
// Reverse-engineered from StatusBarApp binaries using Binary Ninja.
// Each section documents the source function, its address, the OID value,
// buffer layout, and relevant string constants from the ASM.
//
// UserClient selectors:
//   sel 9  = IOConnectCallStructMethod — Query OID
//   sel 10 = IOConnectCallStructMethod — Set OID (CmdSetInformation/SetInformationBuffer/SetInformationValue)
//   sel 0  = IOConnectCallMethod — GetNetworkAtIndex (NET_INFO 0x640)
//
// Struct size: 0x9D4 (CmdSetInformation @ 0x10003c1e0)
//   +0x00: OID (dword)
//   +0x04: infoBufLen (dword)
//   +0x08: dataLen (dword)
//   +0x0C: reserved
//   +0x10: data payload (up to 0x9C4 bytes)
//
// Primary RE files:
//   re/CmdSsid.asm, re/CmdPassphrase.asm, re/CmdAkm.asm, re/CmdScan.asm,
//   re/CmdSetInformation.asm, re/SetInformationBuffer.asm,
//   re/SetInformation_Value.asm, re/SetInformation_Buffer_Length.asm,
//   re/WirelessAssociate.asm, re/all_connect.asm
// Secondary: re/OID_MAP.md, re/WIP.md, re/WIRELESS_ASSOCIATE_PROTOCOL.md

// MARK: - Buffer layout & selector constants

/// Total buffer size for Query/Set struct methods (0x9D4).
///
/// Source: CmdSetInformation @ 0x10003c1e0
///   0x10003c206: `mov qword ptr [rbp - 0xa08], 0x9d4`
///   Also used in SetInformationBuffer @ 0x10003eda0 (0x10003edd3)
///   and SetInformationValue @ 0x10001e420 / 0x10003ef70 (0x10003ef95)
///   and SetInformation_Buffer_Length @ 0x10001e770 / 0x10001e8f0
let kOIDBufSize: Int = 0x9D4

/// Maximum data payload within the buffer (0x9C4).
///
/// Source: CmdSetInformation @ 0x10003c1e0
///   0x10003c21f: `mov dword ptr [rbp - 0x9dc], 0x9c4`
///   Set to `InformationBufferLength` before the `IOConnectCallStructMethod` call.
///   `mov esi, dword ptr [rbp - 0x9dc]` → "CmdSetInformation::setOid.InformationBufferLength= %d"
let kOIDDataMax: Int = 0x9C4

/// Offset from buffer start where the data payload begins (0x10).
///
/// Layout:
///   +0x00: OID (dword)          → `SetInformationBuffer` writes OID at [rbp-0x9e0]
///   +0x04: infoBufLen (dword)   → `SetInformationValue` writes 0x9C4
///   +0x08: dataLen (dword)      → returned data length, checked `cmp [rbp-0x9d8], 0`
///   +0x0C: reserved
///   +0x10: data…                → `lea rax, [rbp-0x9e0]; add rax, 0x10`
let kOIDDataOff: Int = 0x10

/// Buffer size for GetNetworkAtIndex BSS enumeration (0x640 = NETWORK_INFORMATION).
///
/// Source: CmdScan @ 0x10003d190
///   0x10003d28f: `mov qword ptr [rbp - 0xc8040], 0x640`
///   Each BSS entry is 0x640 bytes, indexed via `imul rdx, [rbp-0x28], 0x640`.
///   Fields: +0x00 SSID bytes, +0x21 SSID length, +0x23 channel,
///           +0x24 BSSID key, +0x2A signal 0-100, later WPS IE, later beacon IEs.
///
///   Reference: re/OID_MAP.md "NET_INFO 0x640 (GetNetworkAtIndex)"
let kNetInfoSize: Int = 0x640

/// UserClient selector 9 — Query OID value (IOConnectCallStructMethod).
///
/// Used by SetInformation_Buffer_Length (0x10001e8f0 variant).
///   0x10001e9c1: `mov esi, 9` — the selector passed as the second argument.
let kSelQuery: UInt32 = 9

/// UserClient selector 10 — Set OID value (IOConnectCallStructMethod).
///
/// Source: CmdSetInformation @ 0x10003c1e0
///   0x10003c316: `mov eax, 0xa` selects IOConnectCallStructMethod.
///   Also SetInformationBuffer @ 0x10003eda0 uses selector 10.
///   Also SetInformationValue @ 0x10003ef70 / 0x10001e420 uses selector 10.
///   All three functions follow the same pattern: open adapter, call structMethod(a, 0xa, …).
let kSelSet: UInt32 = 10

/// UserClient selector 0 — Get BSS entry at index (IOConnectCallMethod, buf 0x640).
///
/// Source: CmdScan @ 0x10003d190
///   0x10003d360: `call 0x10013c77c` (IOConnectCallMethod with selector 0).
///   Arguments: open port handle, buf 0x640 per entry, index in rdx.
let kSelGetNetworkAtIndex: UInt32 = 0

// MARK: - 802.11 standard OIDs

/// OID_802_11_BSSID — set/query current BSSID (0x0D010101).
///
/// Source: WirelessAssociate @ 0x10001c7f0, step 3 (set BSSID from struct +0x08).
///   0x10001c857: `mov rdx, qword ptr [rdi + 8]` reads BSSID from parameter struct.
///   `mov edx, 0xd010101` passed as OID to `setOIDValue`.
///   Note: StatusBarApp skips scan-key BSSIDs with U/L bit set (0e…) — must match real AP MAC.
let OID_802_11_BSSID: UInt32 = 0x0D_01_01_01

/// OID_802_11_INFRASTRUCTURE_MODE — 0=infra, 1=adhoc, 3=auto (0x0D010108).
///
/// Source: WirelessAssociate @ 0x10001c7f0, step 2
///   0x10001c82b: `movzx ecx, byte ptr [rdi + 0x18]` — reads network type from struct.
///   `mov edx, 0xd010108` passed to setOID.
///   NETTYPE_INFRA=0, NETTYPE_ADHOC=1, NETTYPE_AUTO=3 (CmdNetworkType).
let OID_802_11_INFRASTRUCTURE_MODE: UInt32 = 0x0D_01_01_08

/// OID_802_11_DISASSOCIATE — leave BSS (0x0D010115).
///
/// Source: WirelessAssociate @ 0x10001c7f0, step 1
///   0x10001c818: `mov edx, 0xd010115` — disassociate sent BEFORE setting infra mode.
///   Also CmdPassphrase @ 0x10003d0d0 (CmdDisassociate): `mov edi, 0xd010115`
///   String: "Disassociate \n" (0x10003d10c), "Failed to set disassociate.\n" (0x10003d0f6).
let OID_802_11_DISASSOCIATE: UInt32 = 0x0D_01_01_15

/// Signal strength 0…100 via OID 0x0D010206.
///
/// Source: CmdPassphrase tail (0x10003d130, getSignalStrength)
///   0x10003d143: `mov edi, 0xd010206` — query OID for RSSI.
///   Returns int 0…100. String: "RSSI: %d \n" (0x10003d16f).
///   "Failed to Query Rssi.\n" (0x10003d156).
///   StatusBarApp `[WLANClientUtilityModel getSignalStrength]` + MacAccess `-rssi`.
/// NOTE: OID 0x0D010106 returns 0 on this stack — use this one.
let OID_RT_SIGNAL_STRENGTH: UInt32 = 0x0D_01_02_06

// MARK: - Scan path OIDs (CmdScan)

/// Initiate scan. Set value 0 to start (0xFF07011A).
///
/// Source: CmdScan @ 0x10003d190
///   0x10003d1d1: `mov edi, 0xff07011a` — start scan.
///   `mov esi, eax` (esi=0) — value 0 triggers scan.
///   Stack frame: 0xc80a0 bytes (large local buffer for BSS list).
let OID_RT_SET_SCAN: UInt32 = 0xFF_07_01_1A

/// Query scan progress. 0 = idle, 1+ = in progress (0xFF0101BD).
///
/// Source: CmdScan @ 0x10003d190
///   0x10003d1e1: `mov edi, 0xff0101bd` — query scan in progress.
///   Polled in a `while != 0` loop with `sleep(1)` between queries:
///   0x10003d1fa: `cmp dword ptr [rbp - 0x18], 0`
///   0x10003d1fe: `je 0x10003d230` — exit loop when 0 (idle).
///   Also used in post-connect polling (WirelessAssociate.asm @ 0x10001cb60):
///   `cmp dword ptr [rbp - 0x1c], 0` — returns 0 when scan not in progress.
let OID_RT_GET_SCAN_IN_PROGRESS: UInt32 = 0xFF_01_01_BD

/// Number of BSS entries available via GetNetworkAtIndex (0xFF010419).
///
/// Source: CmdScan @ 0x10003d190
///   0x10003d234: `mov edi, 0xff010419` — query available BSS count.
///   Capped at 0x200 (512) max: `cmp dword ptr [rbp - 0x1c], 0x200`.
let OID_BSS_NUMBER: UInt32 = 0xFF_01_04_19

/// NIC interface status: non-zero = up (0xFF010418).
///
/// Source: CmdScan @ 0x10003d430 (CmdInterfaceStatus)
///   0x10003d44a: `mov edi, 0xff010418` — query interface status.
///   String: "Interface Status: %s\n" (0x10003d48b) — "up" / "down".
///   "Failed to query NIC interface status.\n" (0x10003d45d).
///   Returns 0 = down, non-zero = up.
let OID_RT_NIC_STATUS: UInt32 = 0xFF_01_04_18

// MARK: - Realtek vendor OIDs (0xFF*)

/// SSID value. Buffer 0x84: SSID bytes at +0, length dword at +0x80.
///
/// Source: CmdSsid @ 0x10003ae40
///   Function split: `MacAccess -ssid g` (get) and `MacAccess -ssid s <ssid>` (set).
///   OID: 0xFF070102 at 0x10003aea7 (get) and 0x10003b033 (set).
///
/// Set path:
///   0x10003b033: `mov edi, 0xff070102`
///   0x10003b038: `mov edx, 0x84` — buffer size.
///   Calls `SetInformationBuffer(oid=0xFF070102, buf, 0x84)`.
///   Validates: `strlen` ≤ 0x80 (0x10003af7b) else "Error input SSID.\n".
///   Buffer at [rbp-0x90], copy from argv[3] with `movsxd` byte loop.
///
/// Get path:
///   0x10003aea7: `mov edi, 0xff070102` — query SSID.
///   Calls `setOIDData(oid, &buf)`.
///   Then prints each byte: "Query SSID : " + per-char format.
///
/// String constants:
///   "strlen(argv[3]: %ld\n " (0x10003b01b)
///   "Failed to set SSID: %s\n" (0x10003b058)
///   "Set SSID (%s) success.\n" (0x10003b0ad)
///   "Error input SSID.\n" (0x10003b0cb)
///
/// After setting SSID, immediately triggers `setOIDValue(OID_RT_CONNECT=0xFF01041B, 0)`
/// at 0x10003b073.
let OID_RT_SSID: UInt32 = 0xFF_07_01_02

/// Passphrase / key material. Buffer 0x98: key at +0, key index at +0x1C, length at +0x20.
///
/// Source: CmdPassphrase @ 0x10003ce10
///   OID: 0xFF010305 at 0x10003ceca — set passphrase.
///   Buffer size: 0x98 (0x10003ce9a: `mov eax, 0x98`).
///   Valid range: 8–63 characters (0x10003ce5c: `cmp [rbp-0xb4], 8` / `cmp [rbp-0xb4], 0x3f`).
///   String: "Invalid passphrase length, %d, valid range is 8-63\n" (0x10003ce7c).
///   "Failed to set passphrase.\n" (0x10003ceec), "Set passphrase success.\n" (0x10003cf05).
///
/// WEP variant: CmdPassphrase @ 0x10003cf40 (CmdPassphraseDefaultKey)
///   OID: 0xFF070113 at 0x10003d04b — set WEP default key.
///   Buffer size: 0x98. Valid key lengths: 0xA (10) or 0x1A (26) hex chars.
///   String: "Invalid key length, %d, valid range is 10 or 26 characters!\n" (0x10003cffb).
///   Key index range: 0–3 (0x10003cf7c: `cmp [rbp-0xb4], 0` / `cmp [rbp-0xb4], 4`).
///   "Invalid key index, %d, valid range is 0-3!\n" (0x10003cf9c).
///   "Failed to set wep key.\n" (0x10003d06d), "Set wep key success.\n" (0x10003d086).
///
/// Buffer layout for both:
///   +0x00: key data
///   +0x1C: key index (dword, only for WEP)
///   +0x20: key length (dword)
let OID_RT_PASSPHRASE: UInt32 = 0xFF_01_03_05

/// WEP default key material (0xFF070113). Used for WEP key index setup.
///
/// Source: CmdPassphrase WEP variant @ 0x10003cf40
///   0x10003d04b: `mov edi, 0xff070113`
///   See OID_RT_PASSPHRASE for full buffer layout and validation details.
let OID_RT_WEP_KEY: UInt32 = 0xFF_07_01_13

/// AKM / encryption selector: 0=open, 3=wpa-psk, 6=wpa2-psk (0xFF010194).
///
/// Source: CmdAkm @ 0x10003c770
///   Function handles both get and set for `MacAccess -akm [g|s <val>]`.
///   OID: 0xFF010194 at 0x10003c7ae (get) and 0x10003c9ef (set).
///
/// Get path: queries OID, then prints matching string:
///   Values:
///     0 → "open\n" (0x10003c808)
///     1 → "sharedkey\n" path (queries OID_RT_SHARED_KEY_FLAG at 0xFF01041A)
///     3 → "wpa-psk\n" (0x10003c884)
///     6 → "wpa2-psk\n" (0x10003c89a)
///     else → "unknown encryption method(%d)!\n" (0x10003c8b3)
///
/// Set path: parses string arg → value:
///   "sharedkey" → local var = 1, sets OID_RT_SHARED_KEY_FLAG
///   "open"      → AKM = 0
///   "wpa-psk"   → AKM = 3
///   "wpa2-psk"  → AKM = 6
///   "unknown AKM!"→ error (0x10003c99b)
///
/// Then sets in order:
///   1. OID_RT_SHARED_KEY_FLAG = sharedKeyFlag (0x10003c9c3)
///   2. OID_RT_AKM = value (0x10003c9ef)
///
/// String: "Failed to set AKM.\n" (0x10003ca02), "Set AKM success.\n" (0x10003ca18).
///   "Failed to set shared key auth.\n" (0x10003c9d6).
let OID_RT_AKM: UInt32 = 0xFF_01_01_94

/// Shared key flag: 0=normal, 1=shared-key (WEP). Set before passphrase for legacy WEP (0xFF01041A).
///
/// Source: CmdAkm @ 0x10003c770
///   0x10003c822: `mov edi, 0xff01041a` — query shared key flag.
///   0x10003c9c3: `mov edi, 0xff01041a` — set shared key flag.
///   Also set in WirelessAssociate @ 0x10001c8c1 before AKM.
///   String: "Failed to get shared key authentication mode.\n" (0x10003c838).
let OID_RT_SHARED_KEY_FLAG: UInt32 = 0xFF_01_04_1A

/// Trigger associate after SSID/AKM/PSK are set (WirelessAssociate final call). Value = 0 (0xFF01041B).
///
/// Source: WirelessAssociate @ 0x10001c7f0, final step
///   0x10001cac4: `mov edx, 0xff01041b` — final OID to trigger association.
///   `xor ecx, ecx` — value = 0.
///   Also sent after CmdSsid set (0x10003b073) as a secondary trigger.
///   Also sent via `setOIDValue` (SetInformationValue variant) at 0x10003ef70.
let OID_RT_CONNECT: UInt32 = 0xFF_01_04_1B

/// RF channel. Set before connect to pin a channel; query returns current (1…196) (0xFF010182).
///
/// Source: WirelessAssociate @ 0x10001c7f0, step 4
///   0x10001c870: Set channel from struct parameter.
///   Channel sourced from NET_INFO [0x23] by StatusBarApp.
let OID_RT_CHANNEL: UInt32 = 0xFF_01_01_82

/// RF on/off: 0=radio on, 1=radio off (0xFF818081).
///
/// Source: turnRfOn @ 0x10001d530 / turnRfOff
///   OID: 0xFF818081 — byte query.
///   Value 0 = radio ON, value 1 = radio OFF.
///   RfOff persisten file: `<mac>rfoff.rtl` contains "0\n" = ON, "1\n" = OFF.
///   NicIFLinkStatusWatchdog polls this OID live.
let OID_RT_RF: UInt32 = 0xFF_81_80_81

/// GetConnectionStatus — returns 1 when associated (0x00010114).
///
/// Source: WirelessAssociate.asm @ 0x10001cb10 (GetConnectionStatus)
///   0x10001cb40: `mov edx, 0x10114` — note this is a 24-bit value (0x10114),
///   matching OID_MAP.md entry `0x00010114`.
///   Queries connection status into local dword, returns value.
///   Used in `logLinkSnapshot()` for diagnostics.
let OID_RT_CONNECTION_STATUS: UInt32 = 0x00_01_01_14

/// Ad-hoc WPA-None flag (0xFF030004).
///
/// Source: WirelessAssociate @ 0x10001c7f0
///   WPA-None path (network type adhoc + auth enc 3 or 4):
///   0x10001c90f: `mov edx, 0xff030004` — sets adhoc WPA flag to 0.
///   Sets local flag `byte ptr [rbp - 0x19] = 1`.
///   Later at 0x10001c95a: sets OID_RT_ADHOC_WPA_FLAG again with key index byte.
///   Also at 0x10001cae4: passphrase re-set for adhoc WPA after connect trigger.
let OID_RT_ADHOC_WPA_FLAG: UInt32 = 0xFF_03_00_04

/// Link / association flag. NicIFLinkStatusWatchdog polls OID 0xFF819053; byte ≠ 0 → linked.
///
/// Source: NicIFLinkStatusWatchdog @ 0x10000d650
///   Polls `0xFF819053` live — returns byte value, non-zero = associated.
///   Part of the `0xFF819*` family of link-status OIDs.
let OID_RT_LINK_FLAG: UInt32 = 0xFF_81_90_53

/// Link rate Mbps (0xFF81901D). Live value when associated.
///
/// Source: NicIFLinkStatusWatchdog context (live query sample from OID_MAP.md).
///   Sample value: 867 Mbps. Also `0xFF81902B` reports same/alt rate.
///   Returns bytes (likely 4-byte int), live query sample = 867.
let OID_RT_LINK_RATE: UInt32 = 0xFF_81_90_1D

/// Wireless mode (0xFF818500). Reports 802.11 mode (b/g/n/ac/ax).
///
/// Source: CmdSsid.asm second function @ 0x10003b140
///   0x10003b17a: `mov edi, 0xff818500` — query wireless mode.
///   Returns integer: tested against values 0,1,2,4,8,0x10,0x20 (bitmask).
///   String: "Get wireless mode : " (0x10003b1a6).
///   "Failed to get wireless mode.\n" (0x10003b190).
///   Known values from Wi-Fi Alliance / Realtek:
///     0 = 802.11b/g, 1 = 802.11a, 2 = 802.11n (2.4), 4 = 802.11n (5),
///     8 = 802.11ac, 0x10 = 802.11ax (Wi-Fi 6), 0x20 = 802.11be (Wi-Fi 7)
let OID_RT_WIRELESS_MODE: UInt32 = 0xFF_81_85_00

/// WPS hardware Push-Button button flag (0xFF819029). Non-zero when hardware button pressed.
///
/// Source: OID_MAP.md — GetWPSHwPBC detection.
///   Polled by StatusBarApp to detect physical WPS button press.
///   Returns non-zero when button is being pressed.
let OID_RT_WPS_HW_PBC: UInt32 = 0xFF_81_90_29

/// HT Bandwidth (0xFF819024). Returns channel width: 0=20, 1=40, 2=80, 3=160 MHz.
///
/// Source: GetHTinfo_BW @ 0x10001ec20
///   Reads OID 0xFF819024; maps to the HT/VHT channel width.
///   Values: 0 = 20 MHz, 1 = 40 MHz, 2 = 80 MHz, 3 = 160 MHz.
let OID_RT_BW: UInt32 = 0xFF_81_90_24

/// HT Guard Interval (0xFF819025). 0=long, 1=short.
let OID_RT_GI: UInt32 = 0xFF_81_90_25

/// HT MCS index (0xFF819026). MCS 0–31.
let OID_RT_MCS: UInt32 = 0xFF_81_90_26

// MARK: - Network type values (CmdNetworkType)

/// Infrastructure mode (most Wi‑Fi networks, AP + station).
///
/// Source: WirelessAssociate @ 0x10001c7f0 step 2.
///   Value 0 passed as byte from struct +0x18.
///   Default for connecting to APs.
let NETTYPE_INFRA: UInt32 = 0

/// Ad-hoc / IBSS mode (peer-to-peer, no AP).
///
/// Source: WirelessAssociate @ 0x10001c7f0
///   Value 1 passed. WPA-None is applied when adhoc + auth enc in {3,4}.
///   See OID_RT_ADHOC_WPA_FLAG handling.
let NETTYPE_ADHOC: UInt32 = 1

/// Auto mode — lets the driver decide based on scan results.
///
/// Source: WirelessAssociate. Not used in the connect struct by default;
///   StatusBarApp sets infra or adhoc explicitly.
let NETTYPE_AUTO: UInt32 = 3

// MARK: - AKM / AuthEnc values (CmdAkm + CmdEnc; PreferrAuth_Encry)

/// Open / no authentication.
///
/// Source: CmdAkm @ 0x10003c770, set path:
///   0x10003c93d: `mov dword ptr [rbp - 0x14], 0` — value for "open" string match.
///   Get path: 0x10003c808 prints "open\n".
let AKM_OPEN: UInt32 = 0

/// WPA-PSK (TKIP/AES, auth enc 3).
///
/// Source: CmdAkm @ 0x10003c770, set path:
///   0x10003c966: `mov dword ptr [rbp - 0x14], 3` — value for "wpa-psk" string match.
///   Get path: 0x10003c884 prints "wpa-psk\n".
let AKM_WPA_PSK: UInt32 = 3

/// WPA2-PSK (AES, auth enc 6) — most common for home networks.
///
/// Source: CmdAkm @ 0x10003c770, set path:
///   0x10003c98f: `mov dword ptr [rbp - 0x14], 6` — value for "wpa2-psk" string match.
///   Get path: 0x10003c89a prints "wpa2-psk\n".
let AKM_WPA2_PSK: UInt32 = 6

// CmdEnc string map: none=0, wep64=1, wep128=2, tkip=3/4, aes=5/6

// MARK: - WirelessAssociate parameter struct (0x10001c7f0)
//
// The connect parameter struct is passed via `rdx` (third argument) to WirelessAssociate.
// Fields referenced in the ASM:
//   +0x00: (unused in disassembly)
//   +0x08: BSSID (6 bytes qword? `mov rdx, qword ptr [rdi + 8]`)
//   +0x18: networkType (byte, 0=infra, 1=adhoc — `movzx ecx, byte ptr [rdi + 0x18]`)
//   +0x19: keyIndex (byte, used for WEP/WPA-None — `movzx ecx, byte ptr [rdi + 0x19]`)
//   +0x1A: authEnc / AKM (byte, `movzx ecx, byte ptr [rsi + 0x1a]`)
//   +0x20: key data pointer / passphrase string pointer (`mov rdx, qword ptr [rdi + 0x20]`)
//   +0x28: key data pointer (alternative, for adhoc WPA re-set — `mov rdx, qword ptr [rcx + 0x28]`)
//   +0x30: authEnc value (dword, 0-6 — `mov edx, dword ptr [rdi + 0x30]`)
//
// Connect sequence (WirelessAssociate @ 0x10001c7f0 — 7 steps):
//   1. Disassociate: setOIDValue(OID_802_11_DISASSOCIATE, 0)
//   2. Set infra mode: setOIDValue(OID_802_11_INFRASTRUCTURE_MODE, struct.networkType)
//   3. Set BSSID: setOIDData(OID_802_11_BSSID, struct.BSSID)
//   4. Set channel: setOIDData(OID_RT_CHANNEL, struct.channel)  [step varies]
//   5. Set AKM/encryption:
//      a. If adhoc + (WPA-PSK or WPA-None): set OID_RT_ADHOC_WPA_FLAG=0, flag=1
//      b. If authEnc∈{3,4} (WPA variants): setOIDValue(OID_RT_AKM, authEnc)
//         If authEnc∈{1,2} (WEP): check key length, set AKM=1 or 2
//      c. Else: setOIDValue(OID_RT_AKM, authEnc)
//   6. Connect trigger: setOIDValue(OID_RT_CONNECT, 0)
//   7. If adhoc WPA flag set: re-set passphrase via setOIDData(path, passphrase)

// MARK: - Post-connect / diagnostic OIDs (NicIFLinkStatusWatchdog)
//
// NicIFLinkStatusWatchdog @ 0x10000d650 polls these live OIDs to detect link state:
//   0xFF819053 — link/assoc flag (byte ≠ 0 = linked)
//   0xFF819048 — status code
//   0xFF819055 — flag
//   0xFF81901D — link rate Mbps (e.g. 867)
//   0xFF81902B — same/alt link rate
//   0xFF818081 — RF on/off
//   0x00010114 — connection status (1 = associated)
//   0xFF0101BD — scan in progress (post-connect check)
//
// Reference: re/OID_MAP.md "Private FF819* (from NicIFLinkStatusWatchdog)"
