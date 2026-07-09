import Foundation
import AppKit

// MARK: - Band (from 802.11 channel)

/// Derived from channel number (Realtek scan / NET_INFO ch@0x23).
enum WiFiBand: String, CaseIterable, Identifiable, Hashable {
    case g24 = "2.4"
    case g5 = "5"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .g24: return L10n.Band.g24
        case .g5: return L10n.Band.g5
        }
    }

    var shortLabel: String {
        switch self {
        case .g24: return L10n.Band.g24Short
        case .g5: return L10n.Band.g5Short
        }
    }

    /// IEEE 802.11 channel → band. Unknown / 0 → nil.
    static func from(channel: Int) -> WiFiBand? {
        switch channel {
        case 1...14: return .g24
        // 5 GHz: 36–165 common; allow wider range Realtek may report
        case 32...196: return .g5
        default: return nil
        }
    }
}

/// Join list filter: all bands or one band.
enum WiFiBandFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case g24 = "2.4"
    case g5 = "5"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return L10n.Band.all
        case .g24: return L10n.Band.g24
        case .g5: return L10n.Band.g5
        }
    }

    func matches(_ net: ScannedNetwork) -> Bool {
        switch self {
        case .all: return true
        case .g24: return net.band == .g24
        case .g5: return net.band == .g5
        }
    }
}

// MARK: - Wi‑Fi generation (from beacon IEs in NET_INFO)

/// Highest PHY generation advertised by the AP (from HT / VHT / HE / EHT IEs).
enum WiFiGeneration: Int, CaseIterable, Comparable, Hashable, Identifiable {
    case unknown = 0
    case legacy = 1   // a/b/g only
    case wifi4 = 4    // 802.11n  HT Cap
    case wifi5 = 5    // 802.11ac VHT Cap
    case wifi6 = 6    // 802.11ax HE Cap
    case wifi7 = 7    // 802.11be EHT Cap

    var id: Int { rawValue }

    var shortBadge: String {
        switch self {
        case .unknown: return ""
        case .legacy: return "g"
        case .wifi4: return "4"
        case .wifi5: return "5"
        case .wifi6: return "6"
        case .wifi7: return "7"
        }
    }

    var label: String {
        switch self {
        case .unknown: return ""
        case .legacy: return L10n.Gen.legacy
        case .wifi4: return L10n.Gen.wifi4
        case .wifi5: return L10n.Gen.wifi5
        case .wifi6: return L10n.Gen.wifi6
        case .wifi7: return L10n.Gen.wifi7
        }
    }

    /// Compact chip text for list rows.
    var chip: String {
        switch self {
        case .unknown: return ""
        case .legacy: return L10n.Gen.bg
        case .wifi4: return L10n.Gen.wifi4
        case .wifi5: return L10n.Gen.wifi5
        case .wifi6: return L10n.Gen.wifi6
        case .wifi7: return L10n.Gen.wifi7
        }
    }

    static func < (lhs: WiFiGeneration, rhs: WiFiGeneration) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Detect from raw NET_INFO `0x640` (or any buffer that embeds 802.11 IEs).
    ///
    /// Realtek packs WPS + a copy of the beacon/probe IEs after the fixed header.
    /// We slide-window for well-known element IDs with strict lengths to avoid
    /// false positives (e.g. random `FF` bytes).
    static func detect(from data: Data) -> WiFiGeneration {
        let bytes = [UInt8](data)
        guard bytes.count > 0x40 else { return .unknown }

        var hasHT = false
        var hasVHT = false
        var hasHE = false
        var hasEHT = false

        // Fixed header ends ~0x2C; IEs appear after. Advance by 2+len (P2-8).
        let start = min(0x2C, bytes.count)
        var i = start
        while i + 2 < bytes.count {
            let id = bytes[i]
            let len = Int(bytes[i + 1])
            guard i + 2 + len <= bytes.count else { break }

            switch id {
            case 0x2D: // HT Capabilities (typically 26)
                if len == 26 || len == 28 { hasHT = true }
            case 0xBF: // VHT Capabilities (typically 12)
                if len == 12 || len == 13 { hasVHT = true }
            case 0xFF: // Extension (HE / EHT / …)
                if len >= 1 {
                    let ext = bytes[i + 2]
                    // HE Capabilities = 35 (0x23). Element length incl. ext id ~21–54.
                    if ext == 35 && len >= 20 && len <= 64 { hasHE = true }
                    // HE Operation = 36 — reinforces ax, not required
                    if ext == 36 && len >= 4 && len <= 20 { hasHE = true }
                    // EHT Capabilities = 108 (Wi‑Fi 7)
                    if ext == 108 && len >= 4 && len <= 128 { hasEHT = true }
                    // EHT Operation = 106
                    if ext == 106 && len >= 3 && len <= 32 { hasEHT = true }
                }
            default:
                break
            }
            i += 2 + len
        }

        if hasEHT { return .wifi7 }
        if hasHE { return .wifi6 }
        if hasVHT { return .wifi5 }
        if hasHT { return .wifi4 }
        // Had some IE payload but no HT → treat as legacy a/b/g
        if bytes.count > 0x80 { return .legacy }
        return .unknown
    }
}

// MARK: - Scanned network

struct ScannedNetwork: Identifiable, Hashable {
    var id: String { ssid + "|" + (bssid ?? "") }
    let ssid: String
    var bssid: String? = nil
    var isSecure: Bool = true
    var isConnected: Bool = false
    var signalBars: Int = 3
    var signalPercent: Int = 0
    var channel: Int = 0
    var isFromLiveScan: Bool = true
    /// Realtek NetworkType bool (true = ad-hoc / IBSS)
    var isAdhoc: Bool = false
    /// Site_Encry from scan (0 = open)
    var siteEncry: Int = 0
    /// AKMsuit from scan (0 = open-ish, 32 = PSK, …)
    var akmSuit: Int = 0
    /// WPS IE present in BSS
    var hasWPS: Bool = false
    /// Highest advertised generation (Wi‑Fi 4/5/6/7) from IEs
    var generation: WiFiGeneration = .unknown

    var band: WiFiBand? { WiFiBand.from(channel: channel) }

    var bandLabel: String { band?.shortLabel ?? "—" }

    var modeBadge: String {
        if isAdhoc { return L10n.Badge.adhoc }
        if hasWPS { return L10n.Badge.wps }
        return isSecure ? L10n.Badge.secured : L10n.Badge.open
    }

    var isWifi6OrNewer: Bool { generation >= .wifi6 }
}

// MARK: - Scan without StatusBarApp

enum RealtekLiveScan {
    static let scanPlistPath = "/tmp/1.plist"

    /// Primary: talk to RtWlanU kext directly. Fallback: /tmp/1.plist cache.
    static func scan(
        classicAppPaths: [String] = [],
        currentSSID: String?
    ) async -> (networks: [ScannedNetwork], error: String?) {
        // 1) Native driver scan (no StatusBarApp)
        let live: [ScannedNetwork] = await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let nets = RealtekDriver.shared.scanNetworks()
                cont.resume(returning: nets)
            }
        }

        var merged = live
        if merged.isEmpty {
            // 2) Fallback cache (may exist from earlier driver write)
            merged = readCachedScan(currentSSID: currentSSID)
        }

        // Mark connected only if caller passed a *really* associated SSID
        // (has IP / L2). Sticky kext SSID alone must NOT show CONECTADO.
        if let cur = currentSSID, !cur.isEmpty {
            for i in merged.indices where merged[i].ssid == cur {
                merged[i].isConnected = true
            }
        }

        if merged.isEmpty {
            return ([], "No se detectaron redes. ¿Está el adaptador USB conectado y el kext RtWlanU cargado?")
        }
        return (merged, nil)
    }

    static func readCachedScan(currentSSID: String?) -> [ScannedNetwork] {
        let url = URL(fileURLWithPath: scanPlistPath)
        guard let data = try? Data(contentsOf: url),
              let root = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return [] }

        var networks: [ScannedNetwork] = []
        for (ssid, value) in root {
            guard let bssids = value as? [String: Any], !ssid.isEmpty else { continue }
            var bestSignal = 0
            var bestBSSID: String?
            var bestChannel = 0
            var bestEnc = 0
            var bestAkm = 0
            var bestAdhoc = false
            var bestWPS = false
            var bestGen: WiFiGeneration = .unknown
            for (bssid, infoAny) in bssids {
                guard let info = infoAny as? [String: Any] else { continue }
                let sig = (info["SignalStrength"] as? Int) ?? (info["SignalStrength"] as? NSNumber)?.intValue ?? 0
                let ch = (info["Channel"] as? Int) ?? (info["Channel"] as? NSNumber)?.intValue ?? 0
                let enc = (info["Site_Encry"] as? Int) ?? (info["Site_Encry"] as? NSNumber)?.intValue ?? 0
                let akm = (info["AKMsuit"] as? Int) ?? (info["AKMsuit"] as? NSNumber)?.intValue ?? 0
                let adhoc = (info["NetworkType"] as? Bool) ?? false
                let wps: Bool = {
                    if let d = info["WPSIE"] as? Data { return d.count > 8 }
                    if let d = info["WPSIE"] as? NSData { return d.length > 8 }
                    return false
                }()
                let genRaw = (info["Generation"] as? Int) ?? (info["Generation"] as? NSNumber)?.intValue ?? 0
                let gen = WiFiGeneration(rawValue: genRaw) ?? .unknown
                // Prefer stronger signal; on tie, keep higher generation (Wi‑Fi 6 > 5)
                let better = sig > bestSignal
                    || (sig == bestSignal && gen > bestGen)
                if better {
                    bestSignal = sig
                    bestBSSID = bssid
                    bestChannel = ch
                    bestEnc = enc
                    bestAkm = akm
                    bestAdhoc = adhoc
                    bestWPS = wps
                    bestGen = gen
                }
            }
            let bars: Int
            switch bestSignal {
            case 80...: bars = 4
            case 60..<80: bars = 3
            case 40..<60: bars = 2
            case 1..<40: bars = 1
            default: bars = 0
            }
            networks.append(ScannedNetwork(
                ssid: ssid,
                bssid: bestBSSID,
                isSecure: bestEnc != 0 || bestAkm != 0,
                isConnected: currentSSID == ssid,
                signalBars: bars,
                signalPercent: min(100, max(0, bestSignal)),
                channel: bestChannel,
                isFromLiveScan: true,
                isAdhoc: bestAdhoc,
                siteEncry: bestEnc,
                akmSuit: bestAkm,
                hasWPS: bestWPS,
                generation: bestGen
            ))
        }
        networks.sort {
            if $0.isConnected != $1.isConnected { return $0.isConnected && !$1.isConnected }
            if $0.signalPercent != $1.signalPercent { return $0.signalPercent > $1.signalPercent }
            return $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending
        }
        return networks
    }

    static func cacheAge() -> TimeInterval? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: scanPlistPath),
              let date = attrs[.modificationDate] as? Date else { return nil }
        return Date().timeIntervalSince(date)
    }
}
