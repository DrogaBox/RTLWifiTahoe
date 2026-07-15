// UNUSED — types are inline in WiFiModel.swift
import Foundation
import IOKit
import IOKit.network
import SystemConfiguration
import Darwin

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

    /// Shell single-quote escape: `a'b` → `'a'\\''b'`
    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// AppleScript string literal escape for `do shell script "…"`.
    private static func osaStringQuote(_ s: String) -> String {
        "\"" + s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    /// Set DNS servers on a network service. Empty array → DHCP automatic (`Empty`).
    static func setDNSServers(_ servers: [String], serviceName: String) -> (ok: Bool, message: String) {
        guard !serviceName.isEmpty else {
            return (false, "Servicio de red vacío")
        }
        // Reject control characters (possible injection / corrupt SC names)
        if serviceName.unicodeScalars.contains(where: { $0.value < 0x20 }) {
            return (false, "Nombre de servicio inválido")
        }
        for s in servers {
            if s.unicodeScalars.contains(where: { $0.value < 0x20 }) {
                return (false, "Servidor DNS inválido")
            }
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
        // Retry with admin privileges — MUST escape serviceName and servers
        // to prevent shell injection via osascript (P0-1).
        let shellServers = servers.isEmpty
            ? "Empty"
            : servers.map { shellQuote($0) }.joined(separator: " ")
        let cmd = "/usr/sbin/networksetup -setdnsservers \(shellQuote(serviceName)) \(shellServers)"
        rtlog("setDNSServers admin retry: \(cmd)")
        let script = "do shell script \(osaStringQuote(cmd)) with administrator privileges"
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

// Use Darwin's if_msghdr2 if available via import — define RTM_IFINFO2
private let RTM_IFINFO2: UInt8 = 0x12

// Bridging: use Darwin if_msghdr2
extension NetProbe {
    // Re-implement byteCounts using simpler getifaddrs is not enough for counters.
    // Use sysctl NET_RT_IFLIST2 with if_msghdr2 from Darwin.
}
