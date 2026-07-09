import Foundation
import AppKit
import Network
import Combine
import IOKit
import IOKit.network
import SystemConfiguration
import Darwin

// MARK: - Models

struct SavedProfile: Identifiable, Hashable {
    var id: String { ssid }
    let ssid: String
    let hasPassword: Bool
    let channel: Int?
    let isDefault: Bool
}

struct InterfaceSnapshot: Equatable {
    var bsdName: String = ""
    var displayName: String = ""
    var mac: String = "—"
    var ip: String = "—"
    /// IPv4 netmask (e.g. 255.255.255.0)
    var netmask: String = "—"
    /// CIDR prefix length when known (e.g. 24)
    var prefixLength: Int = 0
    var router: String = "—"
    /// Router LAN MAC (ARP / NetworkSignature)
    var routerMAC: String = "—"
    /// Best-effort brand/model (OUI + HTTP fingerprint)
    var routerModel: String = "—"
    var dns: [String] = []
    /// True when DNS is overridden (networksetup custom); false = DHCP / automatic.
    var dnsIsAutomatic: Bool = true
    /// Network service name for networksetup (e.g. "802.11ac NIC")
    var networkServiceName: String = ""
    var active: Bool = false
    var mtu: Int = 0
    var media: String = "—"
    var ssid: String = "—"
    var driverLoaded: Bool = false
    var driverVersion: String = "—"
    var bytesIn: UInt64 = 0
    var bytesOut: UInt64 = 0
    var rxMbps: Double = 0
    var txMbps: Double = 0
    /// True when we can reach beyond the LAN (or gateway + DNS OK)
    var internetReachable: Bool = false
    /// Gateway answers on LAN (ARP / TCP)
    var gatewayReachable: Bool = false
    /// PHY link rate from RtWlanU `IOLinkSpeed` (bits/s)
    var linkSpeedBps: UInt64 = 0
    /// Live signal quality 0…100 (OID 0x0D010206). 0 = unknown / not associated.
    var signalPercent: Int = 0
    /// Associated RF channel from kext (0 = unknown)
    var channel: Int = 0
    var signalLevel: SignalLevel = .none
    /// L2 associating (iface up / join in progress) but no IPv4 yet
    var associating: Bool = false
    /// USB radio (RF) on — StatusBarApp “Radio On/Off”
    var radioOn: Bool = true
    var updatedAt: Date = .distantPast

    var linkMbps: Double { Double(linkSpeedBps) / 1_000_000.0 }
    var signalPercentDisplay: String {
        signalPercent > 0 ? "\(signalPercent)%" : "—"
    }
    /// True only when we have a usable IPv4 on the USB Wi‑Fi iface
    var isConnected: Bool { active && ip != "—" }

    /// Compact label for Status “Router” cell — IP only (model goes in the detail strip).
    var routerDisplay: String {
        if router == "—" || router.isEmpty { return "—" }
        return router
    }

    /// IP with optional /prefix (e.g. 192.168.100.11/24)
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

    /// Compact label for Status “Internet” cell
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
        return DNSPreset.matching(servers: dns) ?? nil
    }
}

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

// MARK: - DNS presets (known public resolvers)

enum DNSPreset: String, CaseIterable, Identifiable {
    case automatic      // DHCP / ISP
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

    /// Empty → clear override (use DHCP DNS).
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

    /// Match current servers to a known preset (order-insensitive).
    static func matching(servers: [String]) -> DNSPreset? {
        let set = Set(servers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        guard !set.isEmpty else { return .automatic }
        for p in DNSPreset.allCases where p != .automatic {
            if Set(p.servers) == set { return p }
        }
        // Partial match: primary server is a known one
        for p in DNSPreset.allCases where p != .automatic {
            if let first = p.servers.first, set.contains(first) { return p }
        }
        return nil
    }
}

// MARK: - Fast sysctl / ifaddrs helpers (no Process / shell)

enum NetProbe {
    static func interfaceExists(_ bsd: String) -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            if String(cString: p.pointee.ifa_name) == bsd { return true }
            ptr = p.pointee.ifa_next
        }
        return false
    }

    /// IPv4 + netmask + flags for a BSD interface.
    static func ipv4AndFlags(bsd: String) -> (ip: String?, mask: String?, up: Bool, running: Bool) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (nil, nil, false, false) }
        defer { freeifaddrs(ifaddr) }
        var ip: String?
        var mask: String?
        var up = false
        var running = false
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let name = String(cString: p.pointee.ifa_name)
            if name == bsd {
                let flags = Int32(p.pointee.ifa_flags)
                up = (flags & IFF_UP) != 0
                running = (flags & IFF_RUNNING) != 0
                if let addr = p.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    let s = String(cString: hostname)
                    if !s.isEmpty { ip = s }
                    // Netmask lives on ifa_netmask (same AF_INET entry)
                    if let nmask = p.pointee.ifa_netmask, nmask.pointee.sa_family == UInt8(AF_INET) {
                        var maskHost = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(nmask, socklen_t(nmask.pointee.sa_len), &maskHost, socklen_t(maskHost.count), nil, 0, NI_NUMERICHOST)
                        let m = String(cString: maskHost)
                        if !m.isEmpty { mask = m }
                    }
                }
            }
            ptr = p.pointee.ifa_next
        }
        // Fallback: SCDynamicStore SubnetMasks for this iface / service
        if mask == nil, let m = subnetMaskFromDynamicStore(bsd: bsd) {
            mask = m
        }
        return (ip, mask, up, running)
    }

    /// Convert dotted mask → prefix length (255.255.255.0 → 24).
    static func prefixLength(fromMask mask: String) -> Int {
        let parts = mask.split(separator: ".").compactMap { UInt8(String($0)) }
        guard parts.count == 4 else { return 0 }
        var bits = 0
        for o in parts {
            var v = o
            // Count leading ones
            for _ in 0..<8 {
                if v & 0x80 != 0 { bits += 1; v <<= 1 } else {
                    // ensure rest are zero for a valid mask
                    return bits
                }
            }
        }
        return bits
    }

    private static func subnetMaskFromDynamicStore(bsd: String) -> String? {
        guard let store = SCDynamicStoreCreate(nil, "RTLWifiTahoe-mask" as CFString, nil, nil) else {
            return nil
        }
        // Service IPv4 for this BSD
        if let keys = SCDynamicStoreCopyKeyList(store, "State:/Network/Service/[^/]+/IPv4" as CFString) as? [String] {
            for key in keys {
                guard let dict = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any] else { continue }
                let ifName = (dict["InterfaceName"] as? String)
                    ?? (dict["ConfirmedInterfaceName"] as? String)
                guard ifName == bsd else { continue }
                if let masks = dict["SubnetMasks"] as? [String], let m = masks.first, !m.isEmpty {
                    return m
                }
            }
        }
        let ifKey = "State:/Network/Interface/\(bsd)/IPv4" as CFString
        if let dict = SCDynamicStoreCopyValue(store, ifKey) as? [String: Any],
           let masks = dict["SubnetMasks"] as? [String], let m = masks.first, !m.isEmpty {
            return m
        }
        return nil
    }

    /// True when the Ethernet interface has an active data-link (IOLinkActiveCount > 0
    /// or parent IOLinkSpeed > 0). Do NOT use IFF_RUNNING — RtWlanU sets it even when
    /// ifconfig says `status: inactive`.
    static func mediaActive(bsd: String) -> Bool {
        let matching = IOServiceMatching("IOEthernetInterface") as NSMutableDictionary
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return false
        }
        defer { IOObjectRelease(iterator) }
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }
            guard let name = IORegistryEntryCreateCFProperty(service, "BSD Name" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String, name == bsd else { continue }
            if let n = IORegistryEntryCreateCFProperty(service, "IOLinkActiveCount" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? NSNumber, n.intValue > 0 {
                return true
            }
            var parent: io_registry_entry_t = 0
            if IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent) == KERN_SUCCESS {
                defer { IOObjectRelease(parent) }
                if let n = IORegistryEntryCreateCFProperty(parent, "IOLinkSpeed" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? NSNumber, n.uint64Value > 0 {
                    return true
                }
            }
            return false
        }
        return false
    }

    static func macAddress(bsd: String) -> String? {
        let matching = IOServiceMatching("IOEthernetInterface") as NSMutableDictionary
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }
            guard let name = IORegistryEntryCreateCFProperty(service, "BSD Name" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String, name == bsd else { continue }
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent) == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(parent) }
            if let macData = IORegistryEntryCreateCFProperty(parent, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? Data, macData.count >= 6 {
                return macData.prefix(6).map { String(format: "%02x", $0) }.joined(separator: ":")
            }
        }
        return nil
    }

    /// Bytes in/out via ifmib sysctl (fast, no shell).
    static func byteCounts(bsd: String) -> (inBytes: UInt64, outBytes: UInt64)? {
        // if_nametoindex
        let idx = if_nametoindex(bsd)
        guard idx > 0 else { return nil }

        var name: [Int32] = [CTL_NET, PF_LINK, NET_RT_IFLIST2, 0]
        var len: size_t = 0
        guard sysctl(&name, 4, nil, &len, nil, 0) == 0, len > 0 else { return nil }
        var buf = [UInt8](repeating: 0, count: len)
        guard sysctl(&name, 4, &buf, &len, nil, 0) == 0 else { return nil }

        var offset = 0
        while offset + MemoryLayout<if_msghdr>.size <= len {
            let hdr: if_msghdr = buf.withUnsafeBytes { raw in
                raw.load(fromByteOffset: offset, as: if_msghdr.self)
            }
            let msglen = Int(hdr.ifm_msglen)
            guard msglen > 0 else { break }
            if hdr.ifm_type == UInt8(RTM_IFINFO2) {
                // if_msghdr2 layout: if_msghdr2 then sockaddr_dl
                let hdr2: if_msghdr2 = buf.withUnsafeBytes { raw in
                    raw.load(fromByteOffset: offset, as: if_msghdr2.self)
                }
                if hdr2.ifm_index == UInt16(idx) {
                    let data = hdr2.ifm_data
                    return (data.ifi_ibytes, data.ifi_obytes)
                }
            }
            offset += msglen
        }
        return nil
    }

    static func scInterfaces() -> [(bsd: String, name: String)] {
        let ports = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
        return ports.compactMap { iface in
            guard let bsd = SCNetworkInterfaceGetBSDName(iface) as String? else { return nil }
            let name = SCNetworkInterfaceGetLocalizedDisplayName(iface) as String? ?? bsd
            return (bsd, name)
        }
    }

    /// Router / DNS for a BSD iface.
    ///
    /// macOS often puts `Router` on `State:/Network/Service/<UUID>/IPv4`
    /// (with `InterfaceName=en1`), **not** on `State:/Network/Interface/en1/IPv4`.
    /// Global primary may be another NIC (en3) on the same LAN — still valid gateway.
    static func routerAndDNS(forBSD bsd: String) -> (router: String?, dns: [String], routerMAC: String?) {
        guard let store = SCDynamicStoreCreate(nil, "RTLWifiTahoe" as CFString, nil, nil) else {
            return (nil, [], nil)
        }
        var router: String?
        var dns: [String] = []
        var routerMAC: String?

        // 1) Network Service bound to this BSD (the real source of Router / DNS)
        if let keys = SCDynamicStoreCopyKeyList(store, "State:/Network/Service/[^/]+/IPv4" as CFString) as? [String] {
            for key in keys {
                guard let dict = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any] else { continue }
                let ifName = (dict["InterfaceName"] as? String)
                    ?? (dict["ConfirmedInterfaceName"] as? String)
                guard ifName == bsd else { continue }

                if let r = dict["Router"] as? String, !r.isEmpty { router = r }
                if let mac = dict["ARPResolvedHardwareAddress"] as? String, !mac.isEmpty {
                    routerMAC = normalizeMAC(mac)
                }
                if routerMAC == nil, let sig = dict["NetworkSignature"] as? String {
                    routerMAC = macFromNetworkSignature(sig)
                }

                // DNS sibling key
                let dnsKey = key.replacingOccurrences(of: "/IPv4", with: "/DNS")
                if let d = SCDynamicStoreCopyValue(store, dnsKey as CFString) as? [String: Any],
                   let servers = d["ServerAddresses"] as? [String] {
                    dns = servers.filter { !$0.isEmpty && !$0.hasPrefix("fe80:") }
                }
                // DHCP Option_3 = router, Option_6 = DNS (raw IPv4 big-endian)
                let dhcpKey = key.replacingOccurrences(of: "/IPv4", with: "/DHCP")
                if let dhcp = SCDynamicStoreCopyValue(store, dhcpKey as CFString) as? [String: Any] {
                    if router == nil, let ip = ipv4FromDHCPOption(dhcp["Option_3"]) {
                        router = ip
                    }
                    if dns.isEmpty, let ip = ipv4FromDHCPOption(dhcp["Option_6"]) {
                        dns = [ip]
                    }
                }
                break
            }
        }

        // 2) Interface-level keys (usually incomplete on USB Wi‑Fi)
        if router == nil {
            let ifKey = "State:/Network/Interface/\(bsd)/IPv4" as CFString
            if let dict = SCDynamicStoreCopyValue(store, ifKey) as? [String: Any] {
                router = dict["Router"] as? String
            }
        }
        if dns.isEmpty {
            let ifDNS = "State:/Network/Interface/\(bsd)/DNS" as CFString
            if let dict = SCDynamicStoreCopyValue(store, ifDNS) as? [String: Any],
               let servers = dict["ServerAddresses"] as? [String] {
                dns = servers.filter { !$0.isEmpty && !$0.hasPrefix("fe80:") }
            }
        }

        // 3) Global default — accept if primary is us OR gateway is on our subnet
        let globalKey = "State:/Network/Global/IPv4" as CFString
        if let dict = SCDynamicStoreCopyValue(store, globalKey) as? [String: Any] {
            let primary = dict["PrimaryInterface"] as? String
            let gRouter = dict["Router"] as? String
            if router == nil, let gRouter {
                if primary == bsd {
                    router = gRouter
                } else if let ourIP = ipv4Address(bsd: bsd), sameIPv4Subnet(ourIP, gRouter, mask: "255.255.255.0") {
                    // en3 primary, en1 secondary, same home LAN
                    router = gRouter
                }
            }
            if dns.isEmpty {
                let dnsKey = "State:/Network/Global/DNS" as CFString
                if let d = SCDynamicStoreCopyValue(store, dnsKey) as? [String: Any],
                   let servers = d["ServerAddresses"] as? [String] {
                    dns = servers.filter { !$0.isEmpty && !$0.hasPrefix("fe80:") }
                }
            }
        }

        // 4) Fallback: classic .1 on /24 when we have an address but no Router key
        if router == nil, let ip = ipv4Address(bsd: bsd) {
            router = guessGateway(from: ip)
        }
        if dns.isEmpty, let router {
            dns = [router]
        }

        return (router, dns, routerMAC)
    }

    /// TCP reachability with short timeout (no shell).
    static func canConnect(host: String, port: UInt16, timeoutMs: Int = 400) -> Bool {
        var hints = addrinfo(
            ai_flags: AI_NUMERICHOST,
            ai_family: AF_INET,
            ai_socktype: SOCK_STREAM,
            ai_protocol: IPPROTO_TCP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )
        var res: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, String(port), &hints, &res) == 0, let info = res else { return false }
        defer { freeaddrinfo(info) }

        let fd = socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
        guard fd >= 0 else { return false }
        defer { close(fd) }

        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
        let cr = connect(fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        if cr == 0 { return true }
        if errno != EINPROGRESS { return false }

        var pfd = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
        let pr = poll(&pfd, 1, Int32(timeoutMs))
        guard pr > 0 else { return false }
        var soError: Int32 = 0
        var len = socklen_t(MemoryLayout<Int32>.size)
        getsockopt(fd, SOL_SOCKET, SO_ERROR, &soError, &len)
        return soError == 0
    }

    static func probeInternet(router: String?) -> (gatewayOK: Bool, internetOK: Bool) {
        var gatewayOK = false
        if let router, !router.isEmpty {
            // Router admin UI is almost always :80; also try :443
            gatewayOK = canConnect(host: router, port: 80, timeoutMs: 350)
                || canConnect(host: router, port: 443, timeoutMs: 350)
                || canConnect(host: router, port: 53, timeoutMs: 350)
        }
        // Public DNS / anycast — proves WAN (or CGNAT to internet)
        let internetOK = canConnect(host: "1.1.1.1", port: 443, timeoutMs: 500)
            || canConnect(host: "8.8.8.8", port: 53, timeoutMs: 500)
            || canConnect(host: "9.9.9.9", port: 53, timeoutMs: 500)
        return (gatewayOK, internetOK)
    }

    // MARK: - Router model (OUI + light HTTP fingerprint)

    /// Synchronous best-effort identity. Safe for work queue; HTTP capped ~0.6s.
    static func identifyRouter(ip: String?, mac: String?) -> String? {
        var brand: String?
        if let mac, let b = vendorFromOUI(mac) { brand = b }

        guard let ip, !ip.isEmpty else { return brand }

        // HTTP GET / with short timeout
        if let html = httpGetString(url: "http://\(ip)/", timeout: 0.55) {
            let lower = html.lowercased()
            if lower.contains("cuscss") || lower.contains("huawei") || lower.contains("hgw") {
                brand = brand ?? "Huawei"
                // Try model-ish tokens in scripts/meta
                if let m = firstMatch(html, pattern: #"(?i)(model|devicename|product(?:name)?)\s*[:=]\s*[\"']([^\"']{2,40})[\"']"#) {
                    return tidyModel(brand: brand, model: m)
                }
            }
            if lower.contains("tp-link") || lower.contains("tplink") { brand = "TP-Link" }
            if lower.contains("asus") || lower.contains("rt-ac") || lower.contains("rt-ax") { brand = brand ?? "ASUS" }
            if lower.contains("netgear") { brand = "NETGEAR" }
            if lower.contains("xiaomi") || lower.contains("miwifi") { brand = "Xiaomi" }
            if lower.contains("mikrotik") { brand = "MikroTik" }
            if lower.contains("ubiquiti") || lower.contains("unifi") { brand = "Ubiquiti" }
            if lower.contains("fiberhome") { brand = "FiberHome" }
            if lower.contains("zte") { brand = "ZTE" }
            if lower.contains("nokia") { brand = "Nokia" }
            if let title = firstMatch(html, pattern: #"<title>([^<]{2,60})</title>"#) {
                let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty, t.lowercased() != "login", t != "—" {
                    return tidyModel(brand: brand, model: t)
                }
            }
        }

        // Common JSON/info endpoints (best effort)
        for path in ["/api/system/deviceinfo", "/api/system/info", "/cgi-bin/luci/admin/status/overview"] {
            if let body = httpGetString(url: "http://\(ip)\(path)", timeout: 0.4) {
                if let m = firstMatch(body, pattern: #"(?i)\"(?:model|DeviceName|product_name|devicename)\"\s*:\s*\"([^\"]{2,40})\""#) {
                    return tidyModel(brand: brand, model: m)
                }
            }
        }

        return brand
    }

    private static func tidyModel(brand: String?, model: String) -> String {
        var m = model.trimmingCharacters(in: .whitespacesAndNewlines)
        // Decode common HTML junk from CPE pages (&#x2d; → -, &amp; → &, etc.)
        m = m.replacingOccurrences(of: "&#x2d;", with: "-", options: .caseInsensitive)
        m = m.replacingOccurrences(of: "&#45;", with: "-")
        m = m.replacingOccurrences(of: "&ndash;", with: "-")
        m = m.replacingOccurrences(of: "&mdash;", with: "-")
        m = m.replacingOccurrences(of: "&amp;", with: "&")
        m = m.replacingOccurrences(of: "&nbsp;", with: " ")
        m = m.replacingOccurrences(of: "&#x", with: "|x", options: .caseInsensitive) // leftover entity start
        // Drop broken entity leftovers like "|x2d10" or ";10"
        if let re = try? NSRegularExpression(pattern: #"\|x[0-9a-fA-F]+;?"#, options: []) {
            m = re.stringByReplacingMatches(in: m, range: NSRange(m.startIndex..., in: m), withTemplate: "-")
        }
        if let re = try? NSRegularExpression(pattern: #"&#\w+;"#, options: []) {
            m = re.stringByReplacingMatches(in: m, range: NSRange(m.startIndex..., in: m), withTemplate: "")
        }
        // Keep readable model chars only
        m = m.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        m = m.trimmingCharacters(in: CharacterSet(charactersIn: "-_| "))
        // Prefer short product codes (e.g. HG8145X6-10)
        if m.count > 28 {
            m = String(m.prefix(28)).trimmingCharacters(in: .whitespaces)
        }
        guard !m.isEmpty else { return brand ?? "—" }
        guard let brand, !brand.isEmpty else { return m }
        if m.localizedCaseInsensitiveContains(brand) { return m }
        return "\(brand) \(m)"
    }

    private static func httpGetString(url: String, timeout: TimeInterval) -> String? {
        guard let u = URL(string: url) else { return nil }
        var req = URLRequest(url: u, timeoutInterval: timeout)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.httpMethod = "GET"
        let sem = DispatchSemaphore(value: 0)
        var result: String?
        let task = URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data, let s = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) {
                result = s
            }
            sem.signal()
        }
        task.resume()
        _ = sem.wait(timeout: .now() + timeout + 0.15)
        return result
    }

    private static func firstMatch(_ text: String, pattern: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let m = re.firstMatch(in: text, options: [], range: range) else { return nil }
        let idx = m.numberOfRanges > 2 ? 2 : 1
        guard m.numberOfRanges > idx, let r = Range(m.range(at: idx), in: text) else { return nil }
        return String(text[r])
    }

    /// First 3 octets → common consumer CPE vendors (not exhaustive).
    static func vendorFromOUI(_ mac: String) -> String? {
        let hex = mac.lowercased().filter { $0.isHexDigit }
        guard hex.count >= 6 else { return nil }
        let oui = String(hex.prefix(6))
        // Huawei (home gateways often 0c8408 / from this AP family)
        let table: [String: String] = [
            "0c8408": "Huawei", "00e0fc": "Huawei", "04c06f": "Huawei", "1c1d67": "Huawei",
            "20f17c": "Huawei", "24daf4": "Huawei", "285fdb": "Huawei", "2c9d1e": "Huawei",
            "48adb1": "Huawei", "4c1fcc": "Huawei", "5cf96a": "Huawei", "70a8e3": "Huawei",
            "80d4a5": "Huawei", "88cf98": "Huawei", "9c28ef": "Huawei", "a0f479": "Huawei",
            "c8d15e": "Huawei", "e0247f": "Huawei", "f4e3fb": "Huawei", "fc48ef": "Huawei",
            "50bd5f": "TP-Link", "50c7bf": "TP-Link", "14cc20": "TP-Link", "98dac4": "TP-Link",
            "b0be76": "TP-Link", "c0e42d": "TP-Link", "ec086b": "TP-Link",
            "04d4c4": "ASUS", "2c56dc": "ASUS", "04d9f5": "ASUS", "1c872c": "ASUS",
            "a0e4cb": "ASUS", "04d3b0": "Nokia", "00d0d6": "Nokia",
            "001e2a": "NETGEAR", "a040a0": "NETGEAR", "c40415": "NETGEAR",
            "28d127": "Xiaomi", "64cc2e": "Xiaomi", "f8a45f": "Xiaomi",
            "0418d6": "Ubiquiti", "24a43c": "Ubiquiti", "788a20": "Ubiquiti",
            "4c5e0c": "RouterBOARD", "48a98a": "RouterBOARD",
            "00a0de": "Yamaha", "0019e0": "TP-Link",
            "d8fb5e": "ASUS", "60a44c": "ASUS"
        ]
        return table[oui]
    }

    private static func normalizeMAC(_ mac: String) -> String {
        let hex = mac.lowercased().filter { $0.isHexDigit }
        guard hex.count >= 12 else { return mac.lowercased() }
        var parts: [String] = []
        var i = hex.startIndex
        for _ in 0..<6 {
            let j = hex.index(i, offsetBy: 2)
            parts.append(String(hex[i..<j]))
            i = j
        }
        return parts.joined(separator: ":")
    }

    private static func macFromNetworkSignature(_ sig: String) -> String? {
        // IPv4.Router=192.168.100.1;IPv4.RouterHardwareAddress=0c:84:08:68:fd:17
        guard let r = sig.range(of: "RouterHardwareAddress=") else { return nil }
        let rest = sig[r.upperBound...]
        let mac = rest.split(separator: ";").first.map(String.init) ?? String(rest)
        let t = mac.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : normalizeMAC(t)
    }

    private static func ipv4FromDHCPOption(_ any: Any?) -> String? {
        let data: Data?
        if let d = any as? Data { data = d }
        else if let d = any as? NSData { data = d as Data }
        else { data = nil }
        guard let data, data.count >= 4 else { return nil }
        return "\(data[0]).\(data[1]).\(data[2]).\(data[3])"
    }

    private static func ipv4Address(bsd: String) -> String? {
        ipv4AndFlags(bsd: bsd).ip
    }

    private static func guessGateway(from ip: String) -> String? {
        let parts = ip.split(separator: ".").compactMap { UInt8(String($0)) }
        guard parts.count == 4 else { return nil }
        // Common home gateways: x.x.x.1
        return "\(parts[0]).\(parts[1]).\(parts[2]).1"
    }

    private static func sameIPv4Subnet(_ a: String, _ b: String, mask: String) -> Bool {
        func octets(_ s: String) -> [UInt32]? {
            let p = s.split(separator: ".").compactMap { UInt32(String($0)) }
            guard p.count == 4 else { return nil }
            return p
        }
        guard let A = octets(a), let B = octets(b), let M = octets(mask) else { return false }
        for i in 0..<4 where (A[i] & M[i]) != (B[i] & M[i]) { return false }
        return true
    }

    // MARK: - DNS (networksetup)

    /// Map BSD device (en1) → System Settings service name ("802.11ac NIC").
    static func networkServiceName(forBSD bsd: String) -> String? {
        let out = runNetworksetup(["-listnetworkserviceorder"]) ?? ""
        // (2) 802.11ac NIC
        // (Hardware Port: 802.11ac NIC, Device: en1)
        var lastName: String?
        let nameRe = try? NSRegularExpression(pattern: #"^\*?\((\d+)\)\s+(.+)$"#)
        for line in out.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if let nameRe {
                let range = NSRange(t.startIndex..., in: t)
                if let m = nameRe.firstMatch(in: t, range: range),
                   let nr = Range(m.range(at: 2), in: t) {
                    lastName = String(t[nr]).trimmingCharacters(in: .whitespaces)
                }
            }
            // Hardware Port line with Device: en1
            if t.contains("Device: \(bsd)") || t.contains("Device:\(bsd)") {
                if let lastName, !lastName.isEmpty { return lastName }
            }
        }
        // Fallback: listallnetworkservices and pick name containing 802.11 / Wi-Fi / WLAN
        if let list = runNetworksetup(["-listallnetworkservices"]) {
            for line in list.components(separatedBy: .newlines) {
                var n = line.trimmingCharacters(in: .whitespaces)
                if n.isEmpty || n.hasPrefix("An asterisk") { continue }
                if n.hasPrefix("*") {
                    n = String(n.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                let l = n.lowercased()
                if l.contains("802.11") || l.contains("wifi") || l.contains("wi-fi") || l.contains("wlan") {
                    return n
                }
            }
        }
        return nil
    }

    /// DNS configured on the service via networksetup.
    /// Returns (servers, isAutomatic). Automatic = no override (DHCP).
    static func configuredDNS(serviceName: String) -> (servers: [String], isAutomatic: Bool) {
        guard !serviceName.isEmpty,
              let out = runNetworksetup(["-getdnsservers", serviceName]) else {
            return ([], true)
        }
        let lower = out.lowercased()
        if lower.contains("aren't any") || lower.contains("are not any") || lower.contains("there aren't") {
            return ([], true)
        }
        var servers: [String] = []
        for line in out.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            // IPv4 or IPv6 literal
            if t.contains(" "), t.lowercased().contains("dns") { continue }
            if t.first?.isNumber == true || t.contains(":") {
                servers.append(t)
            }
        }
        return (servers, servers.isEmpty)
    }

    /// Set DNS servers on a network service. Empty array → DHCP automatic (`Empty`).
    static func setDNSServers(_ servers: [String], serviceName: String) -> (ok: Bool, message: String) {
        guard !serviceName.isEmpty else {
            return (false, "Servicio de red vacío")
        }
        var args = ["-setdnsservers", serviceName]
        if servers.isEmpty {
            args.append("Empty")
        } else {
            args.append(contentsOf: servers)
        }
        let (code, out, err) = runNetworksetupDetailed(args)
        if code == 0 {
            return (true, "OK")
        }
        // Retry with admin privileges (macOS may require it for some configs)
        let shellServers = servers.isEmpty ? "Empty" : servers.map { "'\($0)'" }.joined(separator: " ")
        let cmd = "/usr/sbin/networksetup -setdnsservers '\(serviceName)' \(shellServers)"
        let script = "do shell script \"\(cmd)\" with administrator privileges"
        let (acode, aout, aerr) = runOSAscript(script)
        if acode == 0 {
            return (true, "OK (admin)")
        }
        let msg = [err, out, aerr, aout].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }.joined(separator: " · ")
        return (false, msg.isEmpty ? "No se pudo cambiar DNS (código \(code))" : msg)
    }

    private static func runNetworksetup(_ args: [String]) -> String? {
        let (_, out, err) = runNetworksetupDetailed(args)
        let s = out.isEmpty ? err : out
        return s.isEmpty ? nil : s
    }

    private static func runNetworksetupDetailed(_ args: [String]) -> (Int32, String, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        p.arguments = args
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do {
            try p.run()
            p.waitUntilExit()
        } catch {
            return (-1, "", error.localizedDescription)
        }
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, out, err)
    }

    private static func runOSAscript(_ source: String) -> (Int32, String, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", source]
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do {
            try p.run()
            p.waitUntilExit()
        } catch {
            return (-1, "", error.localizedDescription)
        }
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, out, err)
    }

    /// Driver presence + PHY link speed via IOKit (no kextstat shell).
    /// `phyLinked` is true only when IOLinkSpeed > 0 (real association rate).
    static func realtekDriver() -> (loaded: Bool, version: String, linkSpeedBps: UInt64, phyLinked: Bool) {
        let matching = IOServiceMatching("RtWlanU")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return (false, "not loaded", 0, false)
        }
        defer { IOObjectRelease(iterator) }
        let svc = IOIteratorNext(iterator)
        guard svc != 0 else { return (false, "not loaded", 0, false) }
        defer { IOObjectRelease(svc) }

        var version = "loaded"
        if let ver = IORegistryEntryCreateCFProperty(svc, "RtWlanDriverVersion" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? String {
            version = ver
        }

        var linkSpeed: UInt64 = 0
        if let n = IORegistryEntryCreateCFProperty(svc, "IOLinkSpeed" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? NSNumber {
            linkSpeed = n.uint64Value
        }

        // Do NOT treat bare IOLinkStatus!=0 as linked — RtWlanU often reports
        // non-zero status with the adapter idle (causes false "Connected").
        let phyLinked = linkSpeed > 0
        return (true, version, linkSpeed, phyLinked)
    }
}

// if_msghdr2 / if_data64 for byte counters
private struct if_data64_local {
    var ifi_type: UInt8 = 0
    var ifi_typelen: UInt8 = 0
    var ifi_physical: UInt8 = 0
    var ifi_addrlen: UInt8 = 0
    var ifi_hdrlen: UInt8 = 0
    var ifi_recvquota: UInt8 = 0
    var ifi_xmitquota: UInt8 = 0
    var ifi_unused1: UInt8 = 0
    var ifi_mtu: UInt32 = 0
    var ifi_metric: UInt32 = 0
    var ifi_baudrate: UInt64 = 0
    var ifi_ipackets: UInt64 = 0
    var ifi_ierrors: UInt64 = 0
    var ifi_opackets: UInt64 = 0
    var ifi_oerrors: UInt64 = 0
    var ifi_collisions: UInt64 = 0
    var ifi_ibytes: UInt64 = 0
    var ifi_obytes: UInt64 = 0
    var ifi_imcasts: UInt64 = 0
    var ifi_omcasts: UInt64 = 0
    var ifi_iqdrops: UInt64 = 0
    var ifi_noproto: UInt64 = 0
    var ifi_recvtiming: UInt32 = 0
    var ifi_xmittiming: UInt32 = 0
    // remainder unused
}

// Use Darwin's if_msghdr2 if available via import — define RTM_IFINFO2
private let RTM_IFINFO2: UInt8 = 0x12

// Bridging: use Darwin if_msghdr2
extension NetProbe {
    // Re-implement byteCounts using simpler getifaddrs is not enough for counters.
    // Use sysctl NET_RT_IFLIST2 with if_msghdr2 from Darwin.
}

// MARK: - Model

@MainActor
final class WiFiModel: ObservableObject {
    static let shared = WiFiModel()

    @Published var snapshot = InterfaceSnapshot()
    @Published var profiles: [SavedProfile] = []
    @Published var preferredBSD: String = UserDefaults.standard.string(forKey: "preferred_bsd") ?? ""
    @Published var statusText: String = "…"
    @Published var lastError: String?
    @Published var isRefreshing = false
    @Published var radioBusy = false

    /// Nearby APs from driver scan (Status list). Empty when scan is off / never run.
    @Published var nearbyNetworks: [ScannedNetwork] = []
    @Published var isScanningNearby = false
    /// Age label for UI (“hace 12s”)
    @Published var nearbyScanAgeText: String = ""

    /// When false, no automatic or manual background BSS scans (Join panel still can scan on demand).
    @Published var scanEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "scan_enabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "scan_enabled")
    }() {
        didSet {
            UserDefaults.standard.set(scanEnabled, forKey: "scan_enabled")
            if !scanEnabled {
                // Stop in-flight scan results from overwriting; clear list so UI is honest
                nearbyNetworks = []
                nearbyScanAgeText = "scan apagado"
                isScanningNearby = false
            } else {
                scanNearby(force: true)
            }
        }
    }

    @Published var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: "launch_at_login") {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launch_at_login")
            LoginItemHelper.setEnabled(launchAtLogin)
        }
    }
    @Published var hideClassicUtility: Bool = UserDefaults.standard.bool(forKey: "hide_classic") {
        didSet {
            UserDefaults.standard.set(hideClassicUtility, forKey: "hide_classic")
            if hideClassicUtility { quitClassicStatusBarApp() }
        }
    }
    @Published var showNotifications: Bool = UserDefaults.standard.object(forKey: "show_notifications") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showNotifications, forKey: "show_notifications") }
    }
    @Published var menuBarMode: MenuBarDisplayMode = {
        let raw = UserDefaults.standard.string(forKey: "menubar_mode") ?? ""
        // Migrate old English display-name values
        switch raw {
        case "Icon", "icon": return .iconOnly
        case "SSID", "ssid": return .ssid
        case "IP", "ip": return .ip
        case "Speed", "rate": return .rate
        case "SSID + IP", "ssid_ip": return .ssidIp
        default: return MenuBarDisplayMode(rawValue: raw) ?? .iconOnly
        }
    }() {
        didSet { UserDefaults.standard.set(menuBarMode.rawValue, forKey: "menubar_mode") }
    }
    @Published var refreshHz: Double = UserDefaults.standard.object(forKey: "refresh_hz") as? Double ?? 2.0 {
        didSet {
            UserDefaults.standard.set(refreshHz, forKey: "refresh_hz")
            restartTimer()
        }
    }

    /// Last DNS preset the user picked (UI selection; may differ until apply succeeds).
    @Published var selectedDNSPreset: DNSPreset = {
        DNSPreset(rawValue: UserDefaults.standard.string(forKey: "dns_preset") ?? "") ?? .automatic
    }() {
        didSet { UserDefaults.standard.set(selectedDNSPreset.rawValue, forKey: "dns_preset") }
    }
    @Published var dnsBusy = false
    @Published var dnsStatusMessage: String?
    @Published var disconnectBusy = false

    /// When set, Join panel opens directly on this network (Status nearby tap).
    @Published var pendingJoinNetwork: ScannedNetwork? = nil

    /// Re-join default profile when link drops (USB plug, sleep, failed DHCP).
    @Published var autoReconnect: Bool = {
        if UserDefaults.standard.object(forKey: "auto_reconnect") == nil { return true }
        return UserDefaults.standard.bool(forKey: "auto_reconnect")
    }() {
        didSet { UserDefaults.standard.set(autoReconnect, forKey: "auto_reconnect") }
    }

    private var timer: Timer?
    /// After user taps Disconnect, suppress auto-reconnect for a while.
    private var suppressAutoReconnectUntil: Date = .distantPast
    private var lastAutoReconnectAttempt: Date = .distantPast
    private var autoReconnectInFlight = false
    private let autoReconnectCooldown: TimeInterval = 35
    private var previousBytes: (in: UInt64, out: UInt64, t: Date)?
    private var pathMonitor: NWPathMonitor?
    private var lastSSID: String = ""
    private var lastSlowRefresh: Date = .distantPast
    private var lastNearbyScan: Date = .distantPast
    private var nearbyScanTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private let workQueue = DispatchQueue(label: "com.drogabox.rtlwifitahoe.probe", qos: .userInitiated)
    /// Min seconds between automatic BSS scans (driver scan is heavy)
    private let nearbyScanInterval: TimeInterval = 25

    private let realtekSupport = "/Library/Application Support/WLAN/com.realtek.utility.wifi"
    private let classicAppCandidates = [
        "/Library/Application Support/WLAN/StatusBarApp.app",
        "/Applications/StatusBarApp.app",
        NSHomeDirectory() + "/Downloads/StatusBarApp.app"
    ]

    // Cached slow data
    private var cachedDriver: (loaded: Bool, version: String, linkSpeedBps: UInt64, phyLinked: Bool) =
        (false, "—", 0, false)
    /// After Join, show "Associating" for a short window even if media is still inactive.
    private var joinGraceUntil: Date = .distantPast
    private var cachedProfiles: [SavedProfile] = []
    private var cachedMac: [String: String] = [:]
    private var cachedDisplayName: [String: String] = [:]
    /// Router identity cache (avoid HTTP every 2s tick)
    private var cachedRouterIdentityIP: String?
    private var cachedRouterModel: String?

    private init() {
        // Replace classic StatusBarApp completely
        if UserDefaults.standard.object(forKey: "hide_classic") == nil {
            UserDefaults.standard.set(true, forKey: "hide_classic")
            hideClassicUtility = true
        }
        startPathMonitor()
        restartTimer()
        observeWake()
        AppNotify.requestAuthorizationIfNeeded()
        refreshAsync(forceSlow: true)
        purgeClassicUtility()
    }

    private func observeWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                rtlog("system wake — refresh + auto-reconnect check")
                // Allow reconnect soon after wake
                self.suppressAutoReconnectUntil = Date().addingTimeInterval(2)
                self.lastAutoReconnectAttempt = .distantPast
                self.refreshAsync(forceSlow: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.maybeAutoReconnect(force: true)
                }
            }
        }
    }

    func restartTimer() {
        timer?.invalidate()
        // Default 2s — light path only
        let interval = max(1.0, min(5.0, refreshHz))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAsync(forceSlow: false) }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func startPathMonitor() {
        let mon = NWPathMonitor()
        mon.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                // Only upgrade to OK — never clear a positive TCP probe result
                // with a flaky path event. Probe in refresh owns "No route".
                guard path.status == .satisfied else { return }
                var s = self.snapshot
                if !s.internetReachable, s.ip != "—" {
                    s.internetReachable = true
                    self.snapshot = s
                }
            }
        }
        mon.start(queue: DispatchQueue.global(qos: .utility))
        pathMonitor = mon
    }

    // MARK: Public refresh API

    /// Opens popover: never blocks UI. Uses cache + async update.
    func refreshNow() {
        refreshAsync(forceSlow: true)
        scanNearby(force: false)
    }

    /// Light refresh for timer / menu label.
    func refreshLight() {
        refreshAsync(forceSlow: false)
        // Occasional background BSS scan when enabled
        scanNearby(force: false)
    }

    /// Trigger BSS scan for Status nearby list. No-op when scan is disabled.
    func scanNearby(force: Bool = true) {
        guard scanEnabled else {
            nearbyScanAgeText = "scan apagado"
            return
        }
        guard snapshot.driverLoaded, snapshot.radioOn else { return }
        if isScanningNearby { return }
        if !force, Date().timeIntervalSince(lastNearbyScan) < nearbyScanInterval {
            updateNearbyAgeText()
            return
        }

        isScanningNearby = true
        let connectedSSID: String? = {
            guard snapshot.ip != "—" || snapshot.linkSpeedBps > 0 else { return nil }
            let s = snapshot.ssid
            return (s.isEmpty || s == "—") ? nil : s
        }()

        nearbyScanTask?.cancel()
        nearbyScanTask = Task { [weak self] in
            let (nets, _) = await RealtekLiveScan.scan(currentSSID: connectedSSID)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                // User may have disabled scan while we were working
                guard self.scanEnabled else {
                    self.isScanningNearby = false
                    self.nearbyNetworks = []
                    self.nearbyScanAgeText = "scan apagado"
                    return
                }
                self.nearbyNetworks = nets
                self.lastNearbyScan = Date()
                self.isScanningNearby = false
                self.updateNearbyAgeText()
            }
        }
    }

    private func updateNearbyAgeText() {
        guard scanEnabled else {
            nearbyScanAgeText = "scan apagado"
            return
        }
        if lastNearbyScan == .distantPast {
            nearbyScanAgeText = isScanningNearby ? "escaneando…" : "sin datos"
            return
        }
        let age = Date().timeIntervalSince(lastNearbyScan)
        if age < 5 { nearbyScanAgeText = "ahora" }
        else if age < 60 { nearbyScanAgeText = "hace \(Int(age))s" }
        else if age < 3600 { nearbyScanAgeText = "hace \(Int(age / 60)) min" }
        else { nearbyScanAgeText = "caché antiguo" }
    }

    private func refreshAsync(forceSlow: Bool) {
        // Coalesce concurrent refreshes
        if isRefreshing && !forceSlow { return }

        let pref = preferredBSD
        let force = forceSlow || Date().timeIntervalSince(lastSlowRefresh) > 10
        let prev = previousBytes
        let support = realtekSupport
        let cachedDrv = cachedDriver
        let cachedProf = cachedProfiles
        let cachedMacMap = cachedMac
        let cachedNames = cachedDisplayName
        let graceUntil = joinGraceUntil
        let cachedRModel = cachedRouterModel
        let cachedRIP = cachedRouterIdentityIP

        isRefreshing = true

        workQueue.async { [weak self] in
            var snap = InterfaceSnapshot()
            var profiles = cachedProf
            var driver = cachedDrv
            var macMap = cachedMacMap
            var nameMap = cachedNames
            var prevBytes = prev
            // Local copies so work queue can update identity without racing UI
            var cachedRouterIdentityIP = cachedRIP
            var cachedRouterModel = cachedRModel

            // --- FAST path (always) ---
            let ifaces = NetProbe.scInterfaces()
            for (bsd, name) in ifaces { nameMap[bsd] = name }

            var bsd = pref
            var display = ""
            if bsd.isEmpty {
                if let hit = ifaces.first(where: {
                    let l = $0.name.lowercased()
                    return l.contains("802.11") || l.contains("wlan") || l.contains("wifi") || l.contains("wireless")
                }) {
                    bsd = hit.bsd
                    display = hit.name
                } else if NetProbe.interfaceExists("en1") {
                    bsd = "en1"
                    display = "802.11ac NIC"
                }
            } else {
                display = nameMap[bsd] ?? bsd
            }

            snap.bsdName = bsd
            snap.displayName = display.isEmpty ? bsd : display

            // Driver + PHY every tick
            driver = NetProbe.realtekDriver()
            if force {
                profiles = Self.loadProfiles(supportPath: support)
            }

            var hasIP = false
            var mediaUp = false
            if !bsd.isEmpty {
                let (ip, mask, _, _) = NetProbe.ipv4AndFlags(bsd: bsd)
                hasIP = ip != nil
                mediaUp = NetProbe.mediaActive(bsd: bsd)
                snap.ip = ip ?? "—"
                if let mask, !mask.isEmpty {
                    snap.netmask = mask
                    snap.prefixLength = NetProbe.prefixLength(fromMask: mask)
                } else {
                    snap.netmask = "—"
                    snap.prefixLength = 0
                }
                if let mac = macMap[bsd] ?? NetProbe.macAddress(bsd: bsd) {
                    macMap[bsd] = mac
                    snap.mac = mac
                }
                // Always resolve network service name (needed for DNS apply)
                let serviceName = NetProbe.networkServiceName(forBSD: bsd) ?? ""
                snap.networkServiceName = serviceName

                if hasIP {
                    let (router, dnsSC, rmac) = NetProbe.routerAndDNS(forBSD: bsd)
                    snap.router = router ?? "—"
                    snap.routerMAC = rmac ?? "—"
                    // Prefer networksetup DNS (reflects manual override); fall back to SC
                    let (dnsList, isAuto) = NetProbe.configuredDNS(serviceName: serviceName)
                    if !dnsList.isEmpty {
                        snap.dns = dnsList
                        snap.dnsIsAutomatic = isAuto
                    } else {
                        snap.dns = dnsSC
                        snap.dnsIsAutomatic = dnsSC.isEmpty || dnsSC == [router].compactMap { $0 }
                    }
                    // Real connectivity (not “has DNS string”)
                    let (gwOK, netOK) = NetProbe.probeInternet(router: router)
                    snap.gatewayReachable = gwOK || router != nil
                    snap.internetReachable = netOK
                    // Brand/model: OUI instant + short HTTP (only on slow refresh or first time)
                    if force || cachedRouterIdentityIP != router {
                        if let model = NetProbe.identifyRouter(ip: router, mac: rmac) {
                            snap.routerModel = model
                            cachedRouterIdentityIP = router
                            cachedRouterModel = model
                        } else if let rmac, let v = NetProbe.vendorFromOUI(rmac) {
                            snap.routerModel = v
                            cachedRouterIdentityIP = router
                            cachedRouterModel = v
                        } else if cachedRouterIdentityIP == router, let m = cachedRouterModel {
                            snap.routerModel = m
                        } else {
                            snap.routerModel = "—"
                        }
                    } else if let m = cachedRouterModel {
                        snap.routerModel = m
                    }
                } else {
                    snap.router = "—"
                    snap.routerMAC = "—"
                    snap.routerModel = "—"
                    snap.dns = []
                    snap.dnsIsAutomatic = true
                    snap.internetReachable = false
                    snap.gatewayReachable = false
                    snap.netmask = "—"
                    snap.prefixLength = 0
                }

                if let counts = Self.byteCountsFast(bsd: bsd) {
                    let now = Date()
                    if let p = prevBytes {
                        let dt = now.timeIntervalSince(p.t)
                        if dt > 0.15 {
                            snap.rxMbps = max(0, Double(counts.inBytes &- p.in) * 8 / dt / 1_000_000)
                            snap.txMbps = max(0, Double(counts.outBytes &- p.out) * 8 / dt / 1_000_000)
                        }
                    }
                    prevBytes = (counts.inBytes, counts.outBytes, now)
                    snap.bytesIn = counts.inBytes
                    snap.bytesOut = counts.outBytes
                }
            }

            snap.driverLoaded = driver.loaded
            snap.driverVersion = driver.version
            snap.linkSpeedBps = driver.linkSpeedBps

            // USB radio RF state (OID or soft file)
            if let off = RealtekDriver.shared.isRadioOff() {
                snap.radioOn = !off
            }

            // Live signal % (StatusBarApp getSignalStrength → OID 0x0D010206)
            if let pct = RealtekDriver.shared.querySignalPercent(), pct > 0 {
                snap.signalPercent = pct
            } else {
                snap.signalPercent = 0
            }
            let assocCh = RealtekDriver.shared.queryAssociatedChannel()
            snap.channel = assocCh

            // Really linked at L2? PHY rate or ifconfig media active — NOT IFF_RUNNING alone,
            // and NOT a sticky SSID string left in the kext after a failed join.
            let reallyLinked = hasIP || mediaUp || driver.phyLinked
            let inJoinGrace = Date() < graceUntil

            let liveSSID = RealtekDriver.shared.currentSSID()
            if reallyLinked, let liveSSID, !liveSSID.isEmpty {
                snap.ssid = liveSSID
            } else if let def = profiles.first(where: { $0.isDefault }) {
                snap.ssid = def.ssid
            } else if let last = Self.lastNetwork(supportPath: support) {
                snap.ssid = last
            } else if let first = profiles.first {
                snap.ssid = first.ssid
            } else {
                snap.ssid = "—"
            }

            // connected = IPv4; associating = only after Join or real L2 without IP
            snap.active = hasIP
            snap.associating = !hasIP && (reallyLinked || inJoinGrace)
            snap.signalLevel = SignalLevel.from(
                signalPercent: snap.signalPercent > 0 ? snap.signalPercent : nil,
                linkSpeedBps: driver.linkSpeedBps,
                hasIP: hasIP,
                associating: snap.associating
            )
            snap.updatedAt = Date()

            let status: String
            if !driver.loaded {
                status = L10n.Model.driverMissing
            } else if !snap.radioOn {
                status = L10n.Model.radioOff
            } else if bsd.isEmpty {
                status = L10n.Model.noIface
            } else if hasIP {
                status = L10n.tr("model.connected", snap.ssid)
            } else if snap.associating {
                status = L10n.tr("model.associating", snap.ssid)
            } else if liveSSID != nil && !reallyLinked {
                status = L10n.tr("model.no_link", snap.ssid)
            } else {
                status = L10n.Model.disconnected
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.cachedDriver = driver
                self.cachedProfiles = profiles
                self.cachedMac = macMap
                self.cachedDisplayName = nameMap
                self.previousBytes = prevBytes
                self.cachedRouterIdentityIP = cachedRouterIdentityIP
                self.cachedRouterModel = cachedRouterModel
                self.profiles = profiles
                self.snapshot = snap
                self.statusText = status
                self.isRefreshing = false
                if force { self.lastSlowRefresh = Date() }
                // Notify link loss (had IP → no IP), not during join grace
                let hadIP = self.snapshot.ip != "—"
                let nowIP = hasIP
                let prevSSID = self.lastSSID
                if hadIP, !nowIP, Date() >= self.joinGraceUntil {
                    AppNotify.disconnected(ssid: prevSSID.isEmpty ? snap.ssid : prevSSID)
                }

                self.lastSSID = snap.ssid
                // Sync picker to what the system actually uses (not while applying)
                if !self.dnsBusy, let matched = snap.matchedDNSPreset {
                    self.selectedDNSPreset = matched
                }
                // Auto-reconnect when no IP but we have a saved default profile
                if !hasIP, snap.radioOn, driver.loaded {
                    self.maybeAutoReconnect(force: false)
                }
            }
        }
    }

    // MARK: - Disconnect / auto-reconnect

    /// Leave current BSS (disassociate). Keeps radio on. Suppresses auto-reconnect briefly.
    func disconnectNetwork() {
        disconnectBusy = true
        lastError = nil
        suppressAutoReconnectUntil = Date().addingTimeInterval(90)
        workQueue.async { [weak self] in
            let ok = RealtekDriver.shared.disconnect()
            DispatchQueue.main.async {
                guard let self else { return }
                self.disconnectBusy = false
                if ok {
                    let left = self.snapshot.ssid
                    self.statusText = L10n.Model.disconnectedOk
                    self.lastError = nil
                    AppNotify.disconnected(ssid: left)
                    rtlog("disconnect UI OK — auto-reconnect suppressed 90s")
                } else {
                    self.lastError = L10n.Model.disconnectFail
                }
                self.refreshAsync(forceSlow: true)
            }
        }
    }

    /// If enabled, try to rejoin Last Network / default profile when offline.
    func maybeAutoReconnect(force: Bool) {
        guard autoReconnect else { return }
        guard !autoReconnectInFlight else { return }
        guard Date() >= suppressAutoReconnectUntil else { return }
        if !force, Date().timeIntervalSince(lastAutoReconnectAttempt) < autoReconnectCooldown {
            return
        }
        // Don't fight user who is mid-join
        guard Date() >= joinGraceUntil else { return }
        guard snapshot.driverLoaded, snapshot.radioOn else { return }
        guard snapshot.ip == "—" else { return }
        // Skip if media already linking hard
        if snapshot.associating, !force { return }

        let support = realtekSupport
        let targetSSID: String? = {
            if let last = Self.lastNetwork(supportPath: support), !last.isEmpty { return last }
            if let def = profiles.first(where: { $0.isDefault }) { return def.ssid }
            return profiles.first?.ssid
        }()
        guard let ssid = targetSSID, !ssid.isEmpty, ssid != "—" else { return }

        let pass = KeychainStore.bestPassword(forSSID: ssid, supportPath: support) ?? ""
        // Only auto-join networks we have a password for (or open — rare)
        let entry = RealtekProfiles.allProfiles(supportPath: support)[ssid]
        let openish = (entry?["PreferrAuth_Encry"] as? Int) == 0
            || (entry?["PreferrAuth_Encry"] as? NSNumber)?.intValue == 0
        if pass.isEmpty && !openish {
            rtlog("auto-reconnect skip \(ssid): no stored password (Keychain/Profiles)")
            return
        }

        autoReconnectInFlight = true
        lastAutoReconnectAttempt = Date()
        joinGraceUntil = Date().addingTimeInterval(20)
        rtlog("auto-reconnect → \(ssid)")
        statusText = L10n.tr("model.reconnecting", ssid)
        AppNotify.reconnecting(ssid: ssid)

        Task { @MainActor in
            var opts = JoinOptions()
            opts.networkType = .infrastructure
            opts.authEnc = pass.isEmpty ? .open : .wpa2Psk
            if let ch = profiles.first(where: { $0.ssid == ssid })?.channel, ch > 0 {
                opts.channel = UInt32(ch)
            }
            let msg = await joinNetwork(
                ssid: ssid,
                password: pass,
                useStoredPassword: pass.isEmpty,
                channel: opts.channel.map { Int($0) },
                bssid: nil, // never pin stale BSSID on auto path
                options: opts
            )
            autoReconnectInFlight = false
            if msg.hasPrefix("✓") {
                rtlog("auto-reconnect SUCCESS \(msg)")
                statusText = msg
            } else {
                rtlog("auto-reconnect fail: \(msg)")
                // next attempt after cooldown
            }
        }
    }

    // MARK: - DNS apply

    /// Apply a well-known DNS preset (or Auto/DHCP) to the USB Wi‑Fi service.
    func applyDNSPreset(_ preset: DNSPreset) {
        selectedDNSPreset = preset
        let service = snapshot.networkServiceName.isEmpty
            ? (NetProbe.networkServiceName(forBSD: snapshot.bsdName.isEmpty ? "en1" : snapshot.bsdName) ?? "")
            : snapshot.networkServiceName
        guard !service.isEmpty else {
            dnsStatusMessage = L10n.DNS.noService
            lastError = dnsStatusMessage
            return
        }

        dnsBusy = true
        dnsStatusMessage = nil
        let servers = preset.servers
        workQueue.async { [weak self] in
            let result = NetProbe.setDNSServers(servers, serviceName: service)
            DispatchQueue.main.async {
                guard let self else { return }
                self.dnsBusy = false
                if result.ok {
                    self.dnsStatusMessage = preset == .automatic
                        ? L10n.DNS.appliedAuto
                        : L10n.tr("dns.applied", preset.label, servers.joined(separator: ", "))
                    self.lastError = nil
                    rtlog("dns apply OK \(preset.rawValue) service=\(service) \(servers)")
                    // Re-read after a short delay so networksetup settles
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.refreshAsync(forceSlow: true)
                    }
                } else {
                    self.dnsStatusMessage = result.message
                    self.lastError = result.message
                    rtlog("dns apply FAIL \(result.message)")
                }
            }
        }
    }

    /// Fast byte counters via sysctl IFLIST2
    nonisolated private static func byteCountsFast(bsd: String) -> (inBytes: UInt64, outBytes: UInt64)? {
        let idx = if_nametoindex(bsd)
        guard idx > 0 else { return nil }

        var mib: [Int32] = [CTL_NET, PF_LINK, NET_RT_IFLIST2, 0]
        var len: size_t = 0
        guard sysctl(&mib, 4, nil, &len, nil, 0) == 0, len > 0 else { return nil }
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        defer { buf.deallocate() }
        var len2 = len
        guard sysctl(&mib, 4, buf, &len2, nil, 0) == 0 else { return nil }

        var offset = 0
        while offset + MemoryLayout<if_msghdr>.size <= len2 {
            let hdr = buf.advanced(by: offset).withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
            let msglen = Int(hdr.ifm_msglen)
            guard msglen > 0 else { break }
            if hdr.ifm_type == RTM_IFINFO2 {
                // if_msghdr2: first fields match, then if_data64
                // Use if_msghdr2 from Darwin
                let hdr2 = buf.advanced(by: offset).withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }
                if Int(hdr2.ifm_index) == idx {
                    let d = hdr2.ifm_data
                    return (d.ifi_ibytes, d.ifi_obytes)
                }
            }
            offset += msglen
        }
        return nil
    }

    nonisolated private static func lastNetwork(supportPath: String) -> String? {
        let path = supportPath + "/wifiUtility.plist"
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let last = dict["Last Network"] as? String, !last.isEmpty else { return nil }
        return last
    }

    nonisolated private static func loadProfiles(supportPath: String) -> [SavedProfile] {
        let last = lastNetwork(supportPath: supportPath)
        let dict = RealtekProfiles.allProfiles(supportPath: supportPath)
        var found: [SavedProfile] = []
        for (ssid, entry) in dict {
            // Only dictionary KEYS are SSIDs — never Password values
            let pass = entry["Password"] as? String ?? ""
            let channel = entry["Channel"] as? Int
            let hasStoredPass = pass.count >= 8
                || RealtekProfiles.hasCredentialInProfile1x(ssid: ssid, supportPath: supportPath)
            let hasKC = KeychainStore.password(forSSID: ssid) != nil
            found.append(SavedProfile(
                ssid: ssid,
                hasPassword: hasStoredPass || hasKC,
                channel: channel,
                isDefault: last.map { $0.caseInsensitiveCompare(ssid) == .orderedSame } ?? false
            ))
        }
        found.sort {
            if $0.isDefault != $1.isDefault { return $0.isDefault && !$1.isDefault }
            return $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending
        }
        // Do NOT invent a fake profile from "Last Network" alone — that made
        // "Olvidar" look broken (SSID reappeared without real stored config).
        return found
    }

    // MARK: Actions

    func copyIP() {
        guard snapshot.ip != "—" else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snapshot.ip, forType: .string)
    }

    func copyMAC() {
        guard snapshot.mac != "—" else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snapshot.mac, forType: .string)
    }

    func openRouter() {
        let r = snapshot.router
        guard r != "—", let url = URL(string: "http://\(r)") else { return }
        NSWorkspace.shared.open(url)
    }

    func openNetworkSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func revealProfilesFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: realtekSupport))
    }

    /// Forget a saved network: wipe ProfilesList + profile1x.rtl password + Last Network.
    /// Does not disconnect the current link — next Join will ask for the password again.
    func forgetNetwork(ssid: String) {
        let support = realtekSupport
        let target = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        workQueue.async { [weak self] in
            _ = KeychainStore.deletePassword(forSSID: target)
            let ok = RealtekProfiles.forget(ssid: target, supportPath: support)
            // Confirm credentials are gone (Keychain + Realtek stores)
            let stillPass = KeychainStore.password(forSSID: target) != nil
                || RealtekProfiles.password(for: target, supportPath: support) != nil
                || RealtekProfiles.hasCredentialInProfile1x(ssid: target, supportPath: support)
            let stillListed = RealtekProfiles.allProfiles(supportPath: support).keys
                .contains { $0.caseInsensitiveCompare(target) == .orderedSame }
            let profiles = Self.loadProfiles(supportPath: support)
            DispatchQueue.main.async {
                guard let self else { return }
                self.profiles = profiles
                self.cachedProfiles = profiles
                if !ok || stillListed || stillPass {
                    self.lastError = stillPass
                        ? L10n.tr("model.forget_pass_left", target)
                        : L10n.tr("model.forget_fail", target)
                    rtlog("forget UI fail ok=\(ok) listed=\(stillListed) pass=\(stillPass)")
                } else {
                    self.lastError = nil
                    self.statusText = L10n.tr("model.forgot", target)
                    rtlog("forget UI OK \(target) — reconnect will ask password")
                }
                self.refreshAsync(forceSlow: true)
            }
        }
    }

    /// Toggle USB Wi‑Fi radio (same as StatusBarApp Radio On/Off).
    func setUSBRadio(on: Bool) {
        radioBusy = true
        lastError = nil
        workQueue.async { [weak self] in
            let ok = RealtekDriver.shared.setRadioOn(on)
            DispatchQueue.main.async {
                guard let self else { return }
                self.radioBusy = false
                if !ok {
                    self.lastError = on ? L10n.Model.radioOnFail : L10n.Model.radioOffFail
                }
                var s = self.snapshot
                s.radioOn = on
                self.snapshot = s
                self.statusText = on ? L10n.Model.radioOn : L10n.Model.radioOffStatus
                self.refreshAsync(forceSlow: true)
            }
        }
    }

    func toggleUSBRadio() {
        setUSBRadio(on: !snapshot.radioOn)
    }

    /// Join using RtWlanU kext only — never launches StatusBarApp.
    func joinNetwork(
        ssid: String,
        password: String?,
        useStoredPassword: Bool,
        channel: Int? = nil,
        bssid: String? = nil,
        options: JoinOptions? = nil
    ) async -> String {
        let ssid = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ssid.isEmpty else { return L10n.Model.emptySSID }
        guard snapshot.driverLoaded else {
            rtlog("join: driver not loaded")
            return L10n.Model.driverNotLoaded
        }

        let support = realtekSupport
        var pass = password ?? ""
        if useStoredPassword, pass.isEmpty {
            pass = KeychainStore.bestPassword(forSSID: ssid, supportPath: support) ?? ""
        } else if pass.isEmpty {
            // Prefer Keychain even when UI left field blank
            pass = KeychainStore.bestPassword(forSSID: ssid, supportPath: support) ?? ""
        }

        var opts = options ?? JoinOptions()
        if let channel, channel > 0 { opts.channel = UInt32(channel) }
        if let bssid { opts.bssid = bssid }
        if opts.authEnc.needsPassword && pass.isEmpty && opts.wps == .none {
            // keep as-is; UI should have asked
        }

        rtlog("joinNetwork ssid=\(ssid) passLen=\(pass.count) type=\(opts.networkType.shortLabel) auth=\(opts.authEnc.rawValue) wps=\(opts.wps.rawValue)")

        if opts.wps == .none, !pass.isEmpty {
            workQueue.async {
                _ = KeychainStore.setPassword(pass, forSSID: ssid)
                try? RealtekProfiles.upsert(ssid: ssid, password: pass, supportPath: support)
                try? RealtekProfiles.setLastNetwork(ssid, supportPath: support)
            }
        } else if opts.wps == .none {
            workQueue.async {
                try? RealtekProfiles.setLastNetwork(ssid, supportPath: support)
            }
        }

        joinGraceUntil = Date().addingTimeInterval(opts.wps == .pbc ? 40 : 25)

        let ok: Bool = await withCheckedContinuation { cont in
            workQueue.async {
                func linked() -> Bool {
                    NetProbe.realtekDriver().linkSpeedBps > 0 || NetProbe.mediaActive(bsd: "en1")
                }

                var r = RealtekDriver.shared.connect(ssid: ssid, password: pass, options: opts)

                // Retries only for normal (non-WPS) joins
                if opts.wps == .none {
                    if !linked() {
                        var o = opts
                        o.bssid = nil
                        rtlog("join: retry without BSSID")
                        r = RealtekDriver.shared.connect(ssid: ssid, password: pass, options: o) || r
                    }
                    if !linked(), let ch = opts.channel {
                        var o = opts
                        o.channel = ch >= 36 ? 7 : 157
                        o.bssid = nil
                        rtlog("join: retry alt channel \(o.channel!)")
                        r = RealtekDriver.shared.connect(ssid: ssid, password: pass, options: o) || r
                    }
                    if !linked() && opts.authEnc == .wpa2Psk && !pass.isEmpty {
                        var o = opts
                        o.authEnc = .wpaPsk
                        o.bssid = nil
                        rtlog("join: retry WPA-PSK auth=3")
                        r = RealtekDriver.shared.connect(ssid: ssid, password: pass, options: o) || r
                    }
                }
                cont.resume(returning: r)
            }
        }

        for i in 0..<6 {
            try? await Task.sleep(nanoseconds: 600_000_000)
            refreshAsync(forceSlow: true)
            if snapshot.ip != "—" {
                rtlog("join poll \(i+1) got IP \(snapshot.ip)")
                break
            }
        }
        refreshAsync(forceSlow: true)
        RealtekDriver.shared.logLinkSnapshot(tag: "join-final")

        if snapshot.ip != "—" {
            rtlog("join SUCCESS ip=\(snapshot.ip)")
            // Successful join re-enables auto-reconnect immediately
            suppressAutoReconnectUntil = .distantPast
            AppNotify.connected(ssid: ssid, ip: snapshot.ip)
            return L10n.tr("model.join_ok", ssid, snapshot.ip)
        }
        if ok {
            rtlog("join OIDs OK but L2 dead — see \(RTLog.filePath)")
            return L10n.Model.joinNoLink
        }
        rtlog("join FAILED OID sequence")
        return L10n.tr("model.join_fail", ssid)
    }

    /// Kill classic StatusBarApp completely — we no longer need it.
    func quitClassicStatusBarApp() {
        for app in NSWorkspace.shared.runningApplications
        where app.bundleIdentifier == "com.realtek.utility.statusbar" {
            app.terminate()
        }
        // Also quit if launched from Downloads path under same name
        for app in NSWorkspace.shared.runningApplications
        where app.localizedName == "StatusBarApp" {
            app.terminate()
        }
    }

    /// Call on launch: remove classic utility from Login Items path if present (best-effort).
    func purgeClassicUtility() {
        quitClassicStatusBarApp()
        // Remove common LaunchAgents if any
        let agents = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/LaunchAgents/com.realtek.utility.statusbar.plist"),
            URL(fileURLWithPath: "/Library/LaunchAgents/com.realtek.utility.statusbar.plist")
        ]
        for url in agents {
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    func setPreferredInterface(_ bsd: String) {
        preferredBSD = bsd
        UserDefaults.standard.set(bsd, forKey: "preferred_bsd")
        refreshAsync(forceSlow: true)
    }

    func availableBSDInterfaces() -> [(bsd: String, name: String)] {
        NetProbe.scInterfaces()
    }

    var menuBarTitle: String {
        switch menuBarMode {
        case .iconOnly: return ""
        case .ssid: return snapshot.active ? String(snapshot.ssid.prefix(12)) : L10n.MenuBar.off
        case .ip: return snapshot.ip == "—" ? "…" : snapshot.ip
        case .rate:
            return String(format: "%.1fM", snapshot.rxMbps + snapshot.txMbps)
        case .ssidIp:
            if !snapshot.active { return L10n.MenuBar.off }
            return "\(String(snapshot.ssid.prefix(8))) \(snapshot.ip)"
        }
    }
}

// MARK: - Realtek profile store (ProfilesList.plist + wifiUtility.plist + profile1x.rtl)

enum RealtekProfiles {
    /// PreferrAuth_Encry = 6 → WPA2-PSK (observed from existing profile)
    private static let authWPA2PSK = 6

    /// Wipe saved credentials for an SSID so the next join asks for the password.
    ///
    /// Realtek stores secrets in **two** places:
    /// 1. `ProfilesList.plist` → `Password` (WPA2-PSK path — what Tahoe uses today)
    /// 2. `profile1x.rtl` → `sae_password=` (WPA3 / wpa_supplicant — StatusBarApp only;
    ///    Tahoe join does not use SAE yet; see re/WIP.md, deferred until needed)
    /// Plus `wifiUtility.plist` → `Last Network` (used as “default” in the UI).
    @discardableResult
    static func forget(ssid: String, supportPath: String) -> Bool {
        let target = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return false }

        var profiles = allProfiles(supportPath: supportPath)

        // Exact or case-insensitive key match
        var removedKey: String?
        if profiles[target] != nil {
            removedKey = target
        } else if let hit = profiles.keys.first(where: {
            $0.caseInsensitiveCompare(target) == .orderedSame
        }) {
            removedKey = hit
        }

        if let key = removedKey {
            profiles.removeValue(forKey: key)
            rtlog("forget: drop ProfilesList key=\(key)")
        } else {
            rtlog("forget: SSID not in ProfilesList (still clearing other stores): \(target)")
        }

        var wroteProfiles = false
        do {
            // Archive as NSDictionary tree — same shape StatusBarApp reads
            let nsProfiles = NSMutableDictionary()
            for (k, v) in profiles {
                nsProfiles[k] = NSDictionary(dictionary: v)
            }
            let root = NSDictionary(dictionary: ["RealtekProfiles": nsProfiles])
            let data = try NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: supportPath + "/ProfilesList.plist"), options: .atomic)
            wroteProfiles = true
        } catch {
            rtlog("forget: ProfilesList write failed \(error.localizedDescription)")
        }

        // Always strip wpa_supplicant / SAE secret file
        stripProfile1x(ssid: target, supportPath: supportPath)

        // Always clear Last Network if it points at this SSID
        clearLastNetwork(ifSSID: target, supportPath: supportPath)

        // Verify: must not reappear with a password
        let stillListed = allProfiles(supportPath: supportPath).keys
            .contains { $0.caseInsensitiveCompare(target) == .orderedSame }
        let stillPass = password(for: target, supportPath: supportPath) != nil
            || hasCredentialInProfile1x(ssid: target, supportPath: supportPath)

        if stillListed {
            rtlog("forget: VERIFY fail — still in ProfilesList")
            // Last-resort: rewrite empty if that was the only profile
            if allProfiles(supportPath: supportPath).count == 1 || stillPass {
                try? writeProfilesList([:], supportPath: supportPath)
            }
        }
        if stillPass {
            rtlog("forget: VERIFY fail — credential still present")
        }

        let ok = wroteProfiles && !stillListed && !stillPass
        // If it was never in ProfilesList but we cleared profile1x + last, treat as OK
        if !wroteProfiles && removedKey == nil {
            let okAlt = !hasCredentialInProfile1x(ssid: target, supportPath: supportPath)
            rtlog("forget: alt ok=\(okAlt) for \(target)")
            return okAlt
        }
        rtlog("forget: done \(target) ok=\(ok) removedKey=\(removedKey ?? "-")")
        return ok || (!stillListed && !stillPass)
    }

    private static func writeProfilesList(_ profiles: [String: [String: Any]], supportPath: String) throws {
        let nsProfiles = NSMutableDictionary()
        for (k, v) in profiles {
            nsProfiles[k] = NSDictionary(dictionary: v)
        }
        let root = NSDictionary(dictionary: ["RealtekProfiles": nsProfiles])
        let data = try NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: false)
        try data.write(to: URL(fileURLWithPath: supportPath + "/ProfilesList.plist"), options: .atomic)
    }

    private static func clearLastNetwork(ifSSID ssid: String, supportPath: String) {
        let util = supportPath + "/wifiUtility.plist"
        guard var dict = NSDictionary(contentsOfFile: util) as? [String: Any] else { return }
        let last = (dict["Last Network"] as? String) ?? ""
        guard !last.isEmpty, last.caseInsensitiveCompare(ssid) == .orderedSame else { return }
        dict["Last Network"] = ""
        if let d = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
            try? d.write(to: URL(fileURLWithPath: util), options: .atomic)
            rtlog("forget: cleared Last Network (\(last))")
        }
    }

    /// `profile1x.rtl` — wpa_supplicant config with `sae_password="…"`.
    static func hasCredentialInProfile1x(ssid: String, supportPath: String) -> Bool {
        let path = supportPath + "/profile1x.rtl"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8), !text.isEmpty else {
            return false
        }
        for block in profile1xBlocks(in: text) {
            guard blockMatchesSSID(block, ssid: ssid) else { continue }
            if block.contains("sae_password=\"") || block.contains("psk=\"") || block.contains("password=\"") {
                // Empty password does not count
                if block.range(of: #"sae_password="[^"]+""#, options: .regularExpression) != nil { return true }
                if block.range(of: #"psk="[^"]{8,}""#, options: .regularExpression) != nil { return true }
                if block.range(of: #"password="[^"]+""#, options: .regularExpression) != nil { return true }
            }
        }
        return false
    }

    /// Remove `network={…}` blocks for this SSID from profile1x.rtl.
    static func stripProfile1x(ssid: String, supportPath: String) {
        let path = supportPath + "/profile1x.rtl"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8), !text.isEmpty else { return }

        var kept: [String] = []
        var removed = 0
        for block in profile1xBlocks(in: text) {
            if blockMatchesSSID(block, ssid: ssid) {
                removed += 1
            } else {
                kept.append(block)
            }
        }
        guard removed > 0 else {
            // Also handle loose file that is a single network without clean parse
            if text.localizedCaseInsensitiveContains("ssid=\"\(ssid)\"")
                || text.localizedCaseInsensitiveContains("ssid=\(ssid)") {
                try? "".write(toFile: path, atomically: true, encoding: .utf8)
                rtlog("forget: wiped entire profile1x.rtl (ssid match, no blocks kept)")
            }
            return
        }
        let out = kept.joined(separator: "\n")
        try? out.write(toFile: path, atomically: true, encoding: .utf8)
        rtlog("forget: stripped \(removed) network block(s) from profile1x.rtl for \(ssid)")
    }

    private static func blockMatchesSSID(_ block: String, ssid: String) -> Bool {
        // ssid="Name" or ssid=Name
        if block.range(of: "ssid=\"\(ssid)\"", options: .caseInsensitive) != nil { return true }
        // line-based ssid= without quotes
        for line in block.split(whereSeparator: \.isNewline) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.lowercased().hasPrefix("ssid=") {
                var v = String(t.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if v.hasPrefix("\"") && v.hasSuffix("\"") && v.count >= 2 {
                    v = String(v.dropFirst().dropLast())
                }
                if v.caseInsensitiveCompare(ssid) == .orderedSame { return true }
            }
        }
        return false
    }

    /// Split profile1x text into `network={…}` blocks (brace-balanced).
    private static func profile1xBlocks(in text: String) -> [String] {
        var blocks: [String] = []
        var search = text.startIndex
        while search < text.endIndex,
              let start = text.range(of: "network={", range: search..<text.endIndex) {
            var depth = 0
            var i = start.lowerBound
            var end = text.endIndex
            while i < text.endIndex {
                let ch = text[i]
                if ch == "{" { depth += 1 }
                else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        end = text.index(after: i)
                        break
                    }
                }
                i = text.index(after: i)
            }
            blocks.append(String(text[start.lowerBound..<end]))
            search = end
        }
        return blocks
    }

    /// RealtekProfiles → { SSID: { Password, PreferrAuth_Encry, Channel, … } }
    /// Only dictionary *keys* are SSIDs. Never treat Password values as network names.
    static func allProfiles(supportPath: String) -> [String: [String: Any]] {
        let path = supportPath + "/ProfilesList.plist"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return [:] }

        // Preferred: proper NSKeyedUnarchiver (StatusBarApp format)
        if let root = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSDictionary,
           let profs = root["RealtekProfiles"] as? NSDictionary {
            var result: [String: [String: Any]] = [:]
            for (key, val) in profs {
                guard let ssid = key as? String, !ssid.isEmpty, ssid.count <= 32 else { continue }
                if ssid == "RealtekProfiles" || ssid == "Password" || ssid == "Channel" { continue }
                if let entry = val as? NSDictionary {
                    var plain: [String: Any] = [:]
                    for (ek, ev) in entry {
                        if let es = ek as? String { plain[es] = ev }
                    }
                    result[ssid] = plain
                } else if let entry = val as? [String: Any] {
                    result[ssid] = entry
                }
            }
            return result
        }

        if let root = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [NSDictionary.self, NSMutableDictionary.self, NSString.self, NSNumber.self, NSArray.self],
            from: data
        ) as? [String: Any],
           let profs = root["RealtekProfiles"] as? [String: Any] {
            var result: [String: [String: Any]] = [:]
            for (ssid, val) in profs {
                guard !ssid.isEmpty, ssid.count <= 32 else { continue }
                if let entry = val as? [String: Any] {
                    result[ssid] = entry
                } else if let entry = val as? NSDictionary {
                    var plain: [String: Any] = [:]
                    for (ek, ev) in entry {
                        if let es = ek as? String { plain[es] = ev }
                    }
                    result[ssid] = plain
                }
            }
            return result
        }
        return [:]
    }

    static func password(for ssid: String, supportPath: String) -> String? {
        let target = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        let profiles = allProfiles(supportPath: supportPath)
        let entry = profiles[target]
            ?? profiles.first(where: { $0.key.caseInsensitiveCompare(target) == .orderedSame })?.value
        if let pass = entry?["Password"] as? String {
            let t = pass.trimmingCharacters(in: .whitespacesAndNewlines)
            // WPA-PSK length 8…63; empty = open / not stored
            if (8...63).contains(t.count) { return t }
        }
        // Do not fall back to profile1x.rtl for UI prefill after forget —
        // that file is only for wpa_supplicant; Join uses explicit password.
        return nil
    }

    static func setLastNetwork(_ ssid: String, supportPath: String) throws {
        let path = supportPath + "/wifiUtility.plist"
        var dict = (NSDictionary(contentsOfFile: path) as? [String: Any]) ?? [:]
        dict["Last Network"] = ssid
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: path))
    }

    static func upsert(ssid: String, password: String, supportPath: String) throws {
        var profiles = allProfiles(supportPath: supportPath)
        // Prefer existing key casing if present
        let key = profiles.keys.first(where: { $0.caseInsensitiveCompare(ssid) == .orderedSame }) ?? ssid
        var entry = profiles[key] ?? [:]
        if !password.isEmpty {
            entry["Password"] = password
        } else if entry["Password"] == nil {
            entry["Password"] = ""
        }
        entry["PreferrAuth_Encry"] = entry["PreferrAuth_Encry"] ?? authWPA2PSK
        entry["profilesState"] = 1
        entry["Channel"] = entry["Channel"] ?? 0
        entry["NetworkType"] = false
        profiles[key] = entry
        try writeProfilesList(profiles, supportPath: supportPath)
    }
}

// MARK: - Login item

enum LoginItemHelper {
    static let label = "com.drogabox.rtlwifitahoe"
    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func setEnabled(_ enabled: Bool) {
        let fm = FileManager.default
        if enabled {
            let exe = Bundle.main.bundleURL.path
            let dict: [String: Any] = [
                "Label": label,
                "ProgramArguments": ["/usr/bin/open", "-a", exe],
                "RunAtLoad": true
            ]
            let url = plistURL
            try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
                try? data.write(to: url)
            }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            p.arguments = ["load", "-w", url.path]
            try? p.run()
        } else {
            let url = plistURL
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            p.arguments = ["unload", "-w", url.path]
            try? p.run()
            try? fm.removeItem(at: url)
        }
    }
}
