import Foundation

// MARK: - Network type (CmdNetworkType OID 0x0D010108)
// Realtek: adhoc=1, infra=0, auto=3  (confirmed live + BN)

enum RTNetworkType: UInt32, CaseIterable, Identifiable {
    case infrastructure = 0
    case adhoc = 1
    case auto = 3

    var id: UInt32 { rawValue }

    var label: String {
        switch self {
        case .infrastructure: return L10n.NetType.infra
        case .adhoc: return L10n.NetType.adhoc
        case .auto: return L10n.NetType.auto
        }
    }

    var shortLabel: String {
        switch self {
        case .infrastructure: return L10n.NetType.infraShort
        case .adhoc: return L10n.NetType.adhoc
        case .auto: return L10n.NetType.auto
        }
    }
}

// MARK: - PreferrAuth_Encry / CmdAkm+CmdEnc (OID 0xFF010194)

enum RTAuthEnc: UInt32, CaseIterable, Identifiable {
    case open = 0
    case wep64 = 1
    case wep128 = 2
    case wpaPsk = 3          // WPA-PSK / also used as WPA-None base for ad-hoc
    case wpaPskAes = 4
    case wpa2PskTkip = 5
    case wpa2Psk = 6         // WPA2-PSK AES (most common home AP)

    var id: UInt32 { rawValue }

    var label: String {
        switch self {
        case .open: return L10n.Auth.open
        case .wep64: return L10n.Auth.wep64
        case .wep128: return L10n.Auth.wep128
        case .wpaPsk: return L10n.Auth.wpaPsk
        case .wpaPskAes: return L10n.Auth.wpaPskAes
        case .wpa2PskTkip: return L10n.Auth.wpa2Tkip
        case .wpa2Psk: return L10n.Auth.wpa2
        }
    }

    var needsPassword: Bool {
        self != .open
    }

    /// Map Site_Encry + AKMsuit from Realtek scan plist → default auth
    static func fromScan(siteEncry: Int, akmSuit: Int, isAdhoc: Bool) -> RTAuthEnc {
        if siteEncry == 0 && akmSuit == 0 { return .open }
        if isAdhoc {
            // Ad-hoc with crypto is usually WPA-None (maps to 3/4 in UI)
            if siteEncry != 0 { return .wpaPsk }
            return .open
        }
        // Prefer WPA2 when AKM or enc looks modern
        if siteEncry >= 96 || akmSuit >= 32 { return .wpa2Psk }
        if siteEncry > 0 { return .wpaPsk }
        return .wpa2Psk
    }
}

enum RTWPSMode: String, CaseIterable, Identifiable {
    case none = "none"
    case pbc = "pbc"   // Push-Button on router
    case pin = "pin"   // PIN (enrollee)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return L10n.WPS.none
        case .pbc: return L10n.WPS.pbc
        case .pin: return L10n.WPS.pin
        }
    }
}

/// Options passed into RealtekDriver.connect / joinNetwork
struct JoinOptions: Equatable {
    var networkType: RTNetworkType = .infrastructure
    var authEnc: RTAuthEnc = .wpa2Psk
    var wps: RTWPSMode = .none
    var wpsPin: String = ""
    var channel: UInt32? = nil
    var bssid: String? = nil
    /// Force connection to a specific Wi‑Fi band (2.4 / 5 GHz). nil = auto (use any).
    var forceBand: WiFiBand? = nil

    static func `default`(for net: ScannedNetwork) -> JoinOptions {
        var o = JoinOptions()
        o.networkType = net.isAdhoc ? .adhoc : .infrastructure
        o.authEnc = RTAuthEnc.fromScan(
            siteEncry: net.siteEncry,
            akmSuit: net.akmSuit,
            isAdhoc: net.isAdhoc
        )
        o.channel = net.channel > 0 ? UInt32(net.channel) : nil
        o.bssid = net.bssid
        if !net.isSecure { o.authEnc = .open }
        return o
    }
}
