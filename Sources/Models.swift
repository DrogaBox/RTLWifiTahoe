// UNUSED — types are inline in WiFiModel.swift
import Foundation

// MARK: - InterfaceSnapshot

struct InterfaceSnapshot {
    var bsdName: String = ""
    var displayName: String = ""
    var mac: String = "—"
    var ip: String = "—"
    /// IPv4 netmask (e.g. 255.255.255.0)
    var netmask: String = "—"
    /// CIDR prefix length when known (e.g. 24)
    var prefixLength: Int = 0
    var router: String = "—"
    var routerMAC: String = "—"
    var routerModel: String = "—"
    var dns: [String] = []
    var dnsIsAutomatic: Bool = true
    var networkServiceName: String = ""
    var active: Bool = false
    var ssid: String = "—"
    var driverLoaded: Bool = false
    var driverVersion: String = "—"
    var bytesIn: UInt64 = 0
    var bytesOut: UInt64 = 0
    var rxMbps: Double = 0
    var txMbps: Double = 0
    var internetReachable: Bool = false
    var gatewayReachable: Bool = false
    var linkSpeedBps: UInt64 = 0
    var signalPercent: Int = 0
    var channel: Int = 0
    var signalLevel: SignalLevel = .none
    var associating: Bool = false
    var radioOn: Bool = true
    var linkMbps: Double { Double(linkSpeedBps) / 1_000_000.0 }
    var updatedAt: Date = .distantPast

    var ipDisplay: String {
        if ip == "—" || ip.isEmpty { return "—" }
        if prefixLength > 0 && prefixLength <= 32 {
            return "\(ip)/\(prefixLength)"
        }
        return ip
    }

    var netmaskDisplay: String {
        if netmask == "—" || netmask.isEmpty { return "—" }
        return netmask
    }

    var routerDisplay: String {
        if router == "—" || router.isEmpty { return "—" }
        return router
    }

    var internetDisplay: String {
        if internetReachable { return L10n.Status.internetOK }
        if gatewayReachable { return L10n.Status.internetLAN }
        if router != "—", active { return L10n.Status.internetNoRoute }
        return "—"
    }

    var dnsDisplay: String {
        if dnsIsAutomatic && dns.isEmpty { return L10n.DNS.autoDisplay }
        if dns.isEmpty { return "—" }
        let joined = dns.joined(separator: " · ")
        return dnsIsAutomatic ? "\(joined) (DHCP)" : joined
    }

    var matchedDNSPreset: DNSPreset? {
        if dnsIsAutomatic { return .automatic }
        if dns.isEmpty { return .automatic }
        return nil
    }
}

// MARK: - Saved profiles

struct SavedProfile: Identifiable, Hashable {
    var id: String { ssid }
    let ssid: String
    let hasPassword: Bool
    let channel: Int?
    let isDefault: Bool
}

// MARK: - DNSPreset

enum DNSPreset: String, CaseIterable, Identifiable, Equatable {
    case automatic
    case cloudflare
    case google
    case quad9
    case adguard
    case opendns
    case cloudflareGoogle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return L10n.DNS.auto
        case .cloudflare: return L10n.DNS.cloudflare
        case .google: return L10n.DNS.google
        case .quad9: return L10n.DNS.quad9
        case .adguard: return L10n.DNS.adguard
        case .opendns: return L10n.DNS.opendns
        case .cloudflareGoogle: return L10n.DNS.cfGoogle
        }
    }

    var shortLabel: String { label }

    var servers: [String] {
        switch self {
        case .automatic: return []
        case .cloudflare: return ["1.1.1.1", "1.0.0.1"]
        case .google: return ["8.8.8.8", "8.8.4.4"]
        case .quad9: return ["9.9.9.9", "149.112.112.112"]
        case .adguard: return ["94.140.14.14", "94.140.15.15"]
        case .opendns: return ["208.67.222.222", "208.67.220.220"]
        case .cloudflareGoogle: return ["1.1.1.1", "8.8.8.8"]
        }
    }

    var detail: String {
        let s = servers
        return s.isEmpty ? L10n.DNS.detailAuto : s.joined(separator: " · ")
    }
}

// MARK: - Menu bar display mode

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly = "icon"
    case ssid = "ssid"
    case ip = "ip"
    case rate = "rate"
    case ssidIp = "ssid_ip"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iconOnly: return L10n.MenuBar.icon
        case .ssid: return L10n.MenuBar.ssid
        case .ip: return L10n.MenuBar.ip
        case .rate: return L10n.MenuBar.speed
        case .ssidIp: return L10n.MenuBar.ssidIp
        }
    }
}
