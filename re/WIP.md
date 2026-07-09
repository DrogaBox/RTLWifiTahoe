# WIP / deferred work

Items **not scheduled** unless a real need appears. Do not implement “just in case.”

---

## WPA3 / SAE + `wpa_supplicant` — **WIP · only if needed**

**Status:** Deferred. Not required for current daily use (WPA2-PSK via kext OIDs works).

### Why it exists on the Realtek stack
StatusBarApp joins some modern APs by writing `profile1x.rtl` (`sae_password=…`) and launching:

`…/StatusBarApp.app/Contents/MacOS/wpa_supplicant -Dosx -i enX -c …/profile1x.rtl`

RE hook: `startWpaSupplicant` @ `0x1000179a0` (see `OID_MAP.md`).

Tahoe’s connect path uses **UserClient OIDs** (SSID + passphrase + AKM WPA2). That covers:

- WPA2-PSK / AES (most home APs)
- Mixed WPA2/WPA3 where the AP still accepts WPA2

It does **not** implement SAE/EAPOL. Pure **WPA3-only** networks will fail until this WIP is done.

### When to pick this up
- [ ] A target SSID is **WPA3 only** (no WPA2) and Join fails despite correct password  
- [ ] User/router policy forces SAE  
- [ ] Enterprise 802.1X is required (same supplicant family)

### When **not** to
- Network works with Tahoe today  
- Router is WPA2 or WPA2/WPA3 transition  
- Only curiosity / feature parity with StatusBarApp

### Likely approach (when needed)
1. Detect SAE/WPA3 from scan IEs / AKM  
2. Write/update `profile1x.rtl` (already partially stripped on forget)  
3. Invoke Realtek’s bundled `wpa_supplicant` (or document dependency)  
4. Poll link/IP like current join path  
5. **Not** a full kext rewrite

### Related (also deferred unless needed)
| Item | Note |
|------|------|
| Full WPS PBC/PIN (WSC M1–M8) | Experimental stub only in `RealtekDriver` |
| 802.1X enterprise | Same supplicant path |

---

*Last decision: ship app features first; WPA3 only when a real AP requires it.*

---

## Backlog (review 2026-07) — RE available when needed

### A · App only (high value, no BN)

| # | Item | Why |
|---|------|-----|
| A1 | **RSSI / signal real en menú y Status** | ✅ Done — OID **`0x0D010206`** (getSignalStrength). UI + tooltip. |
| A2 | **Tap cercana → Join preseleccionado** | Menos fricción; pasar SSID/BSSID/channel al JoinPanel. |
| A3 | **Mostrar canal / BSSID / rate del link activo** | Status: “Ch 157 · 0c:84:… · 867 Mbps” desde kext + scan match. |
| A4 | **Preferir banda al unir dual-SSID** | Si mismo SSID en 2.4 y 5, preferir 5 o la de mejor señal (ya hay gen/band). |
| A5 | **Notificaciones** | “Conectado / caído / reconectando” (flag Pro ya existe `showNotifications` a medias). |
| A6 | **Icono menú = badge Wi‑Fi 6 / radio off** | SF Symbol + tinte; no hace falta RE. |

### B · RE ligera (strings/OIDs, pocas horas BN o dumps vivos)

| # | Item | RE hook |
|---|------|---------|
| B1 | **Confirmar OID RSSI / quality** | `Failed to Query Rssi`, `getSignalStrength`, `dSAQuality`, MacAccess `-rssi` |
| B2 | **Wireless mode (b/g/n/ac/ax)** | `MacAccess -wirelessmode`, `GetSupportedWirelessMode`, `kSupportedWirelessMode` — si el dongle está en modo viejo, fuerza rates bajos |
| B3 | **Canal actual asociado** | Ya hay set channel; falta get fiable del BSS activo |
| B4 | **BSSID asociado (GetBSSID)** | Comparar con scan real MAC; diagnosticar multi-AP |
| B5 | **Tx power (solo Pro/debug)** | `-setTxPowerAll` — opcional, no prioritario |

### C · RE media (StatusBarApp path)

| # | Item | When |
|---|------|------|
| C1 | **WPA3 / SAE + wpa_supplicant** | Solo AP WPA3-only (sección arriba) |
| C2 | **WPS completo** | Solo si el usuario lo usa de verdad |
| C3 | **Orden connect 1:1 vs WirelessAssociate** | Si hay APs WPA2 que fallan y StatusBarApp no |

### D · No hacer (bajo ROI)

- Reescribir el kext  
- Enterprise 802.1X “por si acaso”  
- CAM/EFuse/debug registers en UI  
- Country code / channel plan (riesgo regulatorio, poco beneficio casero)

### Suggested next sprint (if continuing)

1. **A1 + B1** — RSSI real (mejor UX diaria + RE corta)  
2. **A2 + A3** — Join desde cercanas + detalle del link  
3. **B2** — wirelessmode solo si rates se sienten bajos vs StatusBarApp  
4. **C1** — solo cuando aparezca red WPA3-only  

Binary Ninja: scripts en `re/bn_*.py`, salida `re/bn_gui_output/`, mapa `OID_MAP.md`.
