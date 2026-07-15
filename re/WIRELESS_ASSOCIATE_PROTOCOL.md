# WirelessAssociate — Realtek RtWlanU OID Connect Protocol (RE)

> **Binary:** Realtek StatusBarApp (`MacAccess`)
> **Target functions:** `WirelessAssociate` @ `0x10001c7f0`, `CmdSsid`, `CmdPassphrase`, `CmdAkm`, `CmdSetInformation`, `SetInformationBuffer`, `SetInformationValue`
> **Source files:** `re/*.asm`, `re/OID_MAP.md`
> **Implementation:** `Sources/RealtekDriver.swift`, `Sources/OIDConstants.swift`

## Overview

The Realtek driver (`RtWlanU` kernel extension) does **not** use standard 802.11 MLME primitives (like `Apple80211Event`). Instead, it exposes a **UserClient** via IOKit that accepts raw OID values through `IOConnectCallStructMethod`. The connect sequence is:

```
Disassociate → Infrastructure Mode → SSID → Channel → 
Ad-hoc WPA Flag (if needed) → Shared Key Flag → BSSID → 
Passphrase → AKM → Connect Trigger
```

Each OID is a 32-bit value written via `SetInformationValue` (for scalar values) or `SetInformationBuffer` (for data buffers like SSID/passphrase). The full OID map is in `re/OID_MAP.md`; constants live in `Sources/OIDConstants.swift`.

---

## 1. UserClient Interface

### Matching

The kext class name starts with `RtWlanU`. Matching via IOService:

```
IOEthernetController → class match → "RtWlanU*"
```

### Selectors (IOConnectCall…)

| Sel | Name | Method | Notes |
|-----|------|--------|-------|
| **9** | `kSelQuery` | `IOConnectCallStructMethod` | Query OID → kext fills `req->infoBuf` |
| **10** | `kSelSet` | `IOConnectCallStructMethod` | Set OID → caller fills `req->infoBuf` |
| **0** | `kSelGetNetworkAtIndex` | `IOConnectCallMethod` | Enumerate BSS list, returns `0x640` NETWORK_INFORMATION |

### Buffer layout (`0x9D4`)

All Query/Set struct method calls use a fixed 0x9D4-byte buffer (`kOIDBufSize`). Layout confirmed from `CmdSetInformation.asm`:

```
Offset  Size  Field
──────  ────  ──────────────────────────────────
+0x00   4     OID (uint32)
+0x04   4     InformationBufferLength (0x9C4 max = kOIDDataMax)
+0x08   4     DataLength (returned by query; 0 for set)
+0x0C   4     Reserved (must be 0)
+0x10   0x9C4 Data payload (kOIDDataOff = 0x10)
```

(Verified: `CmdSetInformation.asm` lines `0x10003c206`–`0x10003c21f`)

---

## 2. SetInformationValue (Scalar OIDs) @ `0x10003ef70`

Writes a 4-byte scalar value for an OID. Called from `WirelessAssociate` and `CmdAkm`.

**Assembly trace** (`SetInformationValue.asm`):

```
1. req->OID = oid
2. req->InformationBufferLength = 0x9C4
3. req->DataLength = 0
4. req->reserved = 0
5. *(uint32*)(req + 0x10) = value  ← value stored at data offset
6. req->infoBuf[0] = oid (again, for the kext)
7. req->infoBuf[1] = 0
8. req->infoBuf[2] = 0
9. openAdapter()
10. IOConnectCallStructMethod(conn, 10, req, 0x9D4, req, &0x9D4)
```

**Return:** 0 on success, -1 (0xFFFFFFFF) on failure.

**Key detail:** The value is stored at `req + 0x10` (the data payload offset). The OID is stored at `req + 0x00` (the first field). This matches `setOIDValue` in `RealtekDriver.swift`.

---

## 3. SetInformationBuffer (Data OIDs) @ `0x10003eda0`

Writes a variable-length data buffer for an OID (used for SSID `0xFF070102` and passphrase `0xFF010305`).

**Assembly trace** (`SetInformationBuffer.asm`):

```
1. req->OID = oid
2. req->InformationBufferLength = data_length (from edx parameter)
3. req->DataLength = 0
4. req->reserved = 0
5. memcpy(req + 0x10, data_ptr, data_length)
6. req->infoBuf[0] = oid
7. req->infoBuf[1] = 0
8. req->infoBuf[2] = 0
9. openAdapter()
10. IOConnectCallStructMethod(conn, 10, req, 0x9D4, req, &0x9D4)
```

**Return:** 1 on success, -1 (0xFFFFFFFF) on failure.

**Implementation:** `setOIDData` in `RealtekDriver.swift` uses the same layout: OID at +0, length at +4, data at +0x10.

---

## 4. CmdSsid (SSID Query/Set) @ `0x10003ae40`

### Query path (`argv[2] == "g"`)

```
1. OID 0xFF070102 query → read buffer
2. Print "Query SSID : "
3. Iterate bytes, print hex "02X "
4. Return
```

### Set path (`argv[2] == "s"`)

```
1. Validate argc >= 4 (ssid argument)
2. strlen(argv[3]) must be ≤ 0x80 (128 bytes max SSID)
3. memcpy(local_buf, argv[3], strlen)
4. SetInformationBuffer(OID 0xFF070102, local_buf, 0x84)
   → buffer 0x84 bytes: SSID at +0, length dword at +0x80
5. If success: print "Set SSID (%s) success."
6.   SetInformationValue(OID 0xFF01041B, 0)  ← Connect trigger!
   If failure: print "Failed to set SSID: %s"
```

**Key insight:** `CmdSsid` does NOT just set the SSID. After a successful SSID set, it **immediately fires the connect trigger** (`OID 0xFF01041B = 0`). This means that for a minimal open-network join, only the SSID needs to be set — the connect trigger follows automatically.

However, in the full `WirelessAssociate` path (and our implementation), the connect trigger is called **explicitly at the end** after all OIDs are written. The `CmdSsid` auto-trigger is only for the MacAccess CLI tool's simple `-ssid s MyNet` path.

**SSID buffer layout:**
```
Offset  Size  Field
──────  ────  ──────────────────
+0x00   0x80  SSID bytes (ASCII)
+0x80   4     SSID length (uint32)
─── total: 0x84 bytes ───
```

---

## 5. CmdPassphrase (Passphrase/Key Set) @ `0x10003ce10`

### Passphrase path (WPA-PSK/WPA2-PSK)

```
1. Validate strlen in [8, 63] (8-63 chars)
2. Create 0x98-byte buffer, zero-filled
3.   +0x00: key material (passphrase bytes)
4.   +0x80: key length (uint32)
5.   +0x84: padding (0)
6. SetInformationBuffer(OID 0xFF010305, buf, 0x98)
7. Print "Set passphrase success." or "Failed to set passphrase."
```

### WEP key path (separate function @ `0x10003cf40`)

```
1. Validate key index in [0, 3]
2. Validate key length == 10 (64-bit) or 26 (128-bit) hex chars
3. Same 0x98 buffer layout
4. SetInformationBuffer(OID 0xFF070113, buf, 0x98)
5. Print "Set wep key success." or "Failed to set wep key."
```

**WEP uses a different OID** (`0xFF070113`) from passphrase (`0xFF010305`), but the same buffer layout.

**Passphrase buffer layout:**
```
Offset  Size  Field
──────  ────  ──────────────────
+0x00   0x80  Key bytes
+0x80   4     Key length (uint32)
+0x84   4     Padding (0)
─── total: 0x98 bytes ───
```

---

## 6. CmdAkm (AKM / Encryption) @ `0x10003c770`

Sets the authentication and key management (AKM) OID (`0xFF010194`) and the shared key flag OID (`0xFF01041A`).

### Query path (`argv[2] == "g"`)

```
1. Query OID 0xFF010194 → get current AKM value
2. Switch on value:
   - 0 → print "open"
   - 1 → query OID 0xFF01041A (shared key flag)
         if != 0 → "sharedkey" else "open"
   - 3 → "wpa-psk"
   - 6 → "wpa2-psk"
   - default → "unknown encryption method(%d)!"
```

### Set path (`argv[2] == "s"`)

```
1. Validate argv[3] exists
2. Match against string arguments:
   - "sharedkey" → SetInformationValue(OID 0xFF01041A, 1)
   - "open"      → Set OID 0xFF010194 = 0
   - "wpa-psk"   → Set OID 0xFF010194 = 3
   - "wpa2-psk"  → Set OID 0xFF010194 = 6
3. If not set yet:
   - SetInformationValue(OID 0xFF01041A, shared? 1 : 0)
   - SetInformationValue(OID 0xFF010194, value)
```

**AKM value map:**
| Value | String | Meaning |
|-------|--------|---------|
| 0     | open   | Open (no security) |
| 1     | n/a    | WEP (uses shared key flag) |
| 3     | wpa-psk | WPA-PSK |
| 6     | wpa2-psk | WPA2-PSK (most common) |

**Shared key flag:** OID `0xFF01041A` — set to 1 for WEP shared-key authentication, 0 otherwise. Confirmed from `CmdAkm.asm` lines `0x10003c81e`–`0x10003c84e`.

---

## 7. WirelessAssociate — Full Connect Sequence @ `0x10001c7f0`

This is the **main connect function** called from `ApplyTheProfileAndTryToConnect` (join path) and `MenuItemClickToJoinNetwork:` (UI join). It takes a connection params structure (rdx) with the following layout (inferred from assembly):

```
Param struct (rbp - 0x18, passed as rdx):
  +0x00  : ???
  +0x08  : Infra Mode value (from WiFiProfile) — 0x0D010108 value
  +0x18  : Network type (infra/adhoc byte) — 0=infra, 1=adhoc
  +0x19  : Key index (for WEP)
  +0x1A  : Auth mode byte (open/shared)
  +0x20  : SSID string pointer
  +0x28  : Passphrase string pointer
  +0x30  : AKM enc value (0/3/6 etc.)
```

### Full OID sequence (from `WirelessAssociate.asm`)

```
Step  OID              Value            Source
────  ───────────────  ───────────────  ──────────────────────
1     0x0D010115       0                Disassociate (leave BSS)
2     0x0D010108       params->0x08     Infrastructure mode (infra=0, adhoc=1)
3     0xFF01041A       params->0x30==2  Shared key flag (WEP only)
      0xFF030004       0                If network type = adhoc + AKM 3 or 4:
                                        Ad-hoc WPA-None flag
4     0xFF030004       params->0x19     If AKM=1 or AKM=2:
                                        WEP key index → Ad-hoc key index
      OID 0xFF070113   key_data         Set WEP key
      OID 0xFF010194   AKM value        2 if key_len==0x1A (WEP-128), else 1
5     OID 0xFF010194   params->0x30     AKM (open=0, wpa=3, wpa2=6)
6     0xFF01041B       0                Connect trigger (final!)
7     0xFF030004       passphrase       If adhoc WPA flag was set (var_19):
                                        Also set passphrase again after trigger
```

### Key observations from the assembly

**Step 1: Disassociate** — Always called first, unconditionally, with value 0. This ensures a clean state before setting new parameters.

**Step 2: Infrastructure mode** — Set from the profile's stored value. Always happens immediately after disassociate.

**Step 3: Shared key flag + Ad-hoc WPA flag** — Two paths handled here:
- If `params->netType == 2` (shared-key WEP): set `0xFF01041A = 1`
- If `params->netType == 1 (adhoc)` AND AKM value is 3 or 4: set `0xFF030004 = 0` (adhoc WPA-None mode)
- The `var_19` (byte at `rbp-0x19`) tracks whether we set `0xFF030004` in this step

**Step 4: WEP path** (if AKM=1 or AKM=2):
- Set `0xFF030004` to key index
- Write WEP key via `0xFF070113` (CmdPassphrase's WEP path)
- Set `0xFF010194` to 2 (WEP-128) or 1 (WEP-64) depending on key length (0x1A=26 hex chars for 128-bit)

**Step 5: AKM** — The main AKM value is written using the `[rip + 0x193f36]` selector (likely mapped as `SetWPAKey:` or the general set method). Three sub-paths:

- **AKM 3 or 4** (WPA-PSK variants): Writes the passphrase via `0x1949a7` selector, then sets AKM via `0xff010194`
- **AKM 5 or 6** (WPA2-PSK variants): Same path
- **Other AKM** (0=open, 1=WEP, 2=WEP-128): Sets AKM directly without passphrase

**Step 6: Connect trigger** — Always set `0xFF01041B = 0`. This is the final OID that tells the kext to associate.

**Step 7: Additional passphrase** — If `var_19` is set (meaning we passed through the adhoc WPA path in step 3), an additional passphrase write happens after the connect trigger. This is a quirk of the StatusBarApp's ad-hoc path.

### Comparison: MacAccess CLI vs WirelessAssociate

The individual `Cmd*` functions (CmdSsid, CmdPassphrase, CmdAkm) are the **MacAccess CLI tool's command handlers**. They implement the same OID operations but with different sequencing:

| Aspect | MacAccess CLI (`Cmd*`) | WirelessAssociate |
|--------|----------------------|-------------------|
| SSID | Set separately via `CmdSsid` + auto-triggers connect | Set manually in assembly before passphrase |
| Passphrase | Set separately via `CmdPassphrase` | Set as part of the sequence after AKM |
| AKM | Set separately via `CmdAkm` | Set as part of the sequence |
| Connect trigger | Auto-fired by CmdSsid after SSID set | Explicit at end of sequence |
| Ad-hoc WPA | Not handled | Full path with `0xFF030004` |
| Channel | Not set | May be set before connect |

Our implementation (`RealtekDriver.swift`) follows the **WirelessAssemble** path, not the CLI path.

---

## 8. SetInformation_Buffer_Length @ `0x10001e770`

An alternative SetInformation variant that accepts buffer length as a separate argument. Called with 6 parameters:

```c
bool SetInformation_Buffer_Length(
    void* adapter,       // rdi — IOKit adapter context
    void* unused,        // rsi
    uint32 oid,          // edx — OID to set
    void* data_ptr,      // rcx — pointer to data
    uint32 data_len,     // r8d — length of data
    uint32 extra_unused  // [rsp+0x28]
)
```

**Buffer layout:**
```
Offset  Size  Field
──────  ────  ──────────────────
+0x00   4     oid
+0x04   4     data_len (InformationBufferLength)
+0x08   4     0 (DataLength)
+0x0C   4     0 (reserved)
+0x10   var   data (memcpy from data_ptr)
```

The layout matches `SetInformationBuffer` exactly, but the parameters are in a different order. This function is **not used directly** in our implementation — `setOIDData` uses the standard `SetInformationBuffer` layout.

---

## 9. SetInformation_Value @ `0x10001e420`

An alternative `SetInformationValue` variant that takes OID and value as separate parameters:

```c
bool SetInformation_Value(
    void* adapter,       // rdi — IOKit adapter context
    void* unused,        // rsi
    uint32 oid,          // edx
    uint32 value         // ecx
)
```

**Buffer layout:**
```
Offset  Size  Field
──────  ────  ──────────────────
+0x00   4     oid
+0x04   4     0x9C4 (InformationBufferLength)
+0x08   4     0 (DataLength)
+0x0C   4     0 (reserved)
+0x10   4     value (uint32)
```

This is essentially identical to `SetInformationValue @ 0x10003ef70` but with a cleaner parameter interface. Our `setOIDValue` follows the same logic.

---

## 10. Complete Connect Sequence Summary

### Normal WPA2-PSK infrastructure connect

```
1.  Open adapter (IOServiceOpen)
2.  Set OID 0xFF818081 = 0       (RF on — turnRfOn)
3.  Write soft RF file "0\n"      (bRfOff = 0 = ON)
4.  Set OID 0x0D010115 = 0       (Disassociate — leave any previous BSS)
5.  Set OID 0x0D010108 = 0       (Infrastructure mode)
6.  Set OID 0xFF070102 = ssid     (SSID: buffer 0x84)
7.  Set OID 0xFF010182 = ch       (Channel — optional)
8.  Set OID 0xFF01041A = 0        (Shared key flag = normal)
9.  Set OID 0x0D010101 = bssid    (BSSID — optional, real MAC only)
10. Set OID 0xFF010305 = password  (Passphrase: buffer 0x98)
11. Set OID 0xFF010194 = 6        (AKM = WPA2-PSK)
12. Set OID 0xFF01041B = 0        (Connect trigger)
```

### Open infrastructure connect (no password)

```
1.  Open adapter
2.  Set OID 0xFF818081 = 0
3.  Set OID 0x0D010115 = 0       (Disassociate)
4.  Set OID 0x0D010108 = 0       (Infrastructure mode)
5.  Set OID 0xFF070102 = ssid     (SSID)
6.  Set OID 0xFF01041A = 0        (Shared key flag)
7.  Set OID 0xFF010194 = 0        (AKM = open)
8.  Set OID 0xFF01041B = 0        (Connect trigger)
```

### Ad-hoc WPA-None connect

```
1.  Open adapter
2.  Set OID 0xFF818081 = 0
3.  Set OID 0x0D010115 = 0
4.  Set OID 0x0D010108 = 1       (Ad-hoc mode)
5.  Set OID 0xFF070102 = ssid
6.  Set OID 0xFF030004 = 0        (Ad-hoc WPA-None flag — BEFORE key)
7.  Set OID 0xFF01041A = 0
8.  Set OID 0xFF010305 = password (Passphrase)
9.  Set OID 0xFF010194 = 3        (AKM = WPA-PSK)
10. Set OID 0xFF01041B = 0
11. Set OID 0xFF010305 = password (Passphrase again — WirelessAssociate quirk)
```

---

## 11. Post-Connect Polling & Diagnostics

After `OID_RT_CONNECT` (`0xFF01041B`), the driver attempts association. Key diagnostic OIDs:

| OID | What it returns | Used in |
|-----|----------------|---------|
| `0x0D010206` | Signal strength 0–100 | `querySignalPercent()` |
| `0xFF010182` | Associated channel | `queryAssociatedChannel()` |
| `0xFF070102` | Current SSID (query) | `currentSSID()` |
| `0x00010114` | Connection status (1=associated) | `logLinkSnapshot()` |
| `0xFF819053` | Link flag (byte ≠ 0 → linked) | `logLinkSnapshot()`, `NicIFLinkStatusWatchdog` |
| `0xFF81901D` | Link rate in Mbps | Live diagnostics |

The polling loop waits up to ~6s (10 × 600ms) for PHY link (`IOLinkSpeed > 0` or media active). If link doesn't come up, the OIDs were accepted by the kext but the AP didn't respond — common issues:
- Incorrect channel (pinned from scan table, wrong BSS)
- BSSID pinned to a scan-table key (0e…) instead of real AP MAC (0c…)
- Wrong AKM / auth type
- Password length mismatch (passphrase truncation)

---

## 12. Known Failure Modes

| Symptom | Probable cause | Check |
|---------|---------------|-------|
| OIDs return OK, SSID held, no link | Wrong channel | `queryAssociatedChannel()` vs AP actual channel |
| OIDs return OK, SSID held, no link | BSSID pinning bad MAC | Check BSSID used: must be real AP MAC (0c…), not scan key (0e…) |
| SSID set fails (-1) | Driver not loaded | `driverLoaded` must be true |
| Passphrase set fails | Length < 8 or > 63 | Validate password length |
| Connect trigger fails | Missing prerequisite OID | Ensure SSID + AKM set before trigger |
| Link up but no IP | DHCP timeout | Wait for IP after link (our polling loop handles this) |

---

## References

- `re/all_connect.asm` — Combined dump of all connect-path functions
- `re/OID_MAP.md` — Full OID map with live query samples
- `re/WIP.md` — Deferred items (WPA3/SAE, full WPS, 802.1X)
- `re/bn_connect_path.py` — Binary Ninja script to decompile connect functions
- `re/bn_deep_connect.py` — BN script for deeper RE (radio, watchdog, supplicant)
- `Sources/RealtekDriver.swift` — Production implementation
- `Sources/OIDConstants.swift` — Centralized OID constants with cross-references
