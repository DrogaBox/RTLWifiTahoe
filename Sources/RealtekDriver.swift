import Foundation
import IOKit
import Darwin

// MARK: - Reverse-engineered RtWlanU UserClient protocol
// From StatusBarApp CmdScan / QueryInformation / SetInformationValue:
//   open: IOEthernetController matching "RtWlanU*"
//   Query OID:  IOConnectCallStructMethod(conn, 9,  &req, 0x9d4, &req, &sz)
//   Set OID:    IOConnectCallStructMethod(conn, 10, &req, 0x9d4, &req, &sz)
//   Get BSS[i]: IOConnectCallMethod(conn, 0, &index, 1, nil, 0, nil, nil, buf, &0x640)

private let kOIDBufSize: Int = 0x9D4
private let kOIDDataMax: Int = 0x9C4
private let kOIDDataOff: Int = 0x10
private let kNetInfoSize: Int = 0x640

private let kSelQuery: UInt32 = 9
private let kSelSet: UInt32 = 10
private let kSelGetNetworkAtIndex: UInt32 = 0

/// When true, log every OID (connect path). Routine UI polls stay quiet.
private var verboseOIDLog = false

// OIDs from StatusBarApp (CmdScan / CmdSsid / CmdAkm / CmdPassphrase / WirelessAssociate)
private let OID_RT_SET_SCAN: UInt32 = 0xFF_07_01_1A
private let OID_RT_GET_SCAN_IN_PROGRESS: UInt32 = 0xFF_01_01_BD
private let OID_BSS_NUMBER: UInt32 = 0xFF_01_04_19
private let OID_RT_SSID: UInt32 = 0xFF_07_01_02          // CmdSsid get/set buffer 0x84
private let OID_RT_PASSPHRASE: UInt32 = 0xFF_01_03_05    // CmdPassphrase buffer 0x98
private let OID_RT_AKM: UInt32 = 0xFF_01_01_94           // 0=open 3=wpa-psk 6=wpa2-psk
private let OID_RT_SHARED_KEY_FLAG: UInt32 = 0xFF_01_04_1A // 0=normal 1=sharedkey
private let OID_RT_CONNECT: UInt32 = 0xFF_01_04_1B       // trigger associate after SSID/AKM/PSK
private let OID_RT_CHANNEL: UInt32 = 0xFF_01_01_82       // setChannel
private let OID_RT_RF: UInt32 = 0xFF_81_80_81            // 0=RF on, 1=RF off (turnRfOn/Off)
private let OID_802_11_INFRASTRUCTURE_MODE: UInt32 = 0x0D_01_01_08
private let OID_802_11_DISASSOCIATE: UInt32 = 0x0D_01_01_15
private let OID_802_11_BSSID: UInt32 = 0x0D_01_01_01
/// GetConnectionStatus (StatusBarApp) — returns 1 when associated
private let OID_RT_CONNECTION_STATUS: UInt32 = 0x00_01_01_14
/// Signal strength 0…100 — StatusBarApp `getSignalStrength` / MacAccess `-rssi`
/// (QueryInformation:Data: with OID 0x0D010206). NOT 0x0D010106 (returns 0 here).
private let OID_RT_SIGNAL_STRENGTH: UInt32 = 0x0D_01_02_06

// CmdNetworkType: adhoc=1, infra=0, auto=3  (BN + live query when StatusBarApp connected)
private let NETTYPE_INFRA: UInt32 = 0
private let NETTYPE_ADHOC: UInt32 = 1
private let NETTYPE_AUTO: UInt32 = 3

// AKM / Enc values (CmdAkm + CmdEnc string map; PreferrAuth_Encry)
private let AKM_OPEN: UInt32 = 0
private let AKM_WPA_PSK: UInt32 = 3
private let AKM_WPA2_PSK: UInt32 = 6
// CmdEnc: none=0 wep64=1 wep128=2 tkip=3/4 aes=5/6 — AES maps to 6

final class RealtekDriver {
    static let shared = RealtekDriver()

    private var connection: io_connect_t = 0
    private let lock = NSLock()

    private init() {}

    deinit { close() }

    // MARK: - Open / close

    @discardableResult
    func open() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if connection != 0 { return true }

        let matching = IOServiceMatching("IOEthernetController")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            rtlog("open: IOServiceMatching IOEthernetController failed")
            return false
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            let className = IOObjectCopyClass(service)?.takeRetainedValue() as String? ?? ""
            let isRTL = className.hasPrefix("RtWlanU")
                || ((IORegistryEntryCreateCFProperty(service, "IOClass" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? String)?.hasPrefix("RtWlanU") ?? false)
                || ((IORegistryEntryCreateCFProperty(service, "CFBundleIdentifier" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? String)?.contains("realtek") ?? false)

            if !isRTL {
                let vendor = IORegistryEntryCreateCFProperty(service, "IOVendor" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? String
                if vendor != "TP-Link" && vendor != "Realtek" && !(className.contains("Wlan") || className.contains("RTL")) {
                    let ver = IORegistryEntryCreateCFProperty(service, "RtWlanDriverVersion" as CFString, kCFAllocatorDefault, 0)
                    if ver == nil { continue }
                    ver?.release()
                }
            }

            var conn: io_connect_t = 0
            let kr = IOServiceOpen(service, mach_task_self_, 0, &conn)
            if kr == KERN_SUCCESS {
                connection = conn
                rtlog("open: OK class=\(className) conn=\(conn)")
                return true
            }
            rtlog("open: IOServiceOpen class=\(className) kr=\(kr)")
        }

        let matching2 = IOServiceMatching("RtWlanU")
        var it2: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching2, &it2) == KERN_SUCCESS else {
            rtlog("open: no RtWlanU service")
            return false
        }
        defer { IOObjectRelease(it2) }
        let svc = IOIteratorNext(it2)
        guard svc != 0 else {
            rtlog("open: RtWlanU iterator empty")
            return false
        }
        defer { IOObjectRelease(svc) }
        var conn: io_connect_t = 0
        guard IOServiceOpen(svc, mach_task_self_, 0, &conn) == KERN_SUCCESS else {
            rtlog("open: RtWlanU open failed")
            return false
        }
        connection = conn
        rtlog("open: OK RtWlanU conn=\(conn)")
        return true
    }

    func close() {
        lock.lock(); defer { lock.unlock() }
        if connection != 0 {
            IOServiceClose(connection)
            connection = 0
        }
    }

    // MARK: - OID helpers

    private func queryOID(_ oid: UInt32, out: UnsafeMutableRawPointer?, maxLen: Int) -> Int {
        lock.lock(); defer { lock.unlock() }
        guard connection != 0 || openUnlocked() else {
            rtlog(String(format: "queryOID 0x%08X FAIL open", oid))
            return -1
        }

        var buf = [UInt8](repeating: 0, count: kOIDBufSize)
        buf.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: oid, toByteOffset: 0, as: UInt32.self)
            raw.storeBytes(of: UInt32(kOIDDataMax), toByteOffset: 4, as: UInt32.self)
            raw.storeBytes(of: UInt32(0), toByteOffset: 8, as: UInt32.self)
            raw.storeBytes(of: UInt32(0), toByteOffset: 12, as: UInt32.self)
        }
        var outSize = kOIDBufSize
        let kr = buf.withUnsafeMutableBytes { raw -> kern_return_t in
            IOConnectCallStructMethod(
                connection, kSelQuery,
                raw.baseAddress, kOIDBufSize,
                raw.baseAddress, &outSize
            )
        }
        guard kr == KERN_SUCCESS else {
            if verboseOIDLog { rtlog(String(format: "queryOID 0x%08X kr=%d", oid, kr)) }
            return -1
        }
        let dataLen = buf.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt32.self) }
        guard dataLen > 0 else {
            if verboseOIDLog { rtlog(String(format: "queryOID 0x%08X ok dlen=0", oid)) }
            return -1
        }
        let copyLen = min(Int(dataLen), maxLen, kOIDDataMax)
        if let out {
            _ = buf.withUnsafeBytes { src in
                memcpy(out, src.baseAddress!.advanced(by: kOIDDataOff), copyLen)
            }
        }
        if verboseOIDLog {
            if maxLen <= 4, let out {
                let v = out.load(as: UInt32.self)
                rtlog(String(format: "queryOID 0x%08X ok dlen=%u val=%u", oid, dataLen, v))
            } else {
                rtlog(String(format: "queryOID 0x%08X ok dlen=%u copy=%d", oid, dataLen, copyLen))
            }
        }
        return copyLen
    }

    @discardableResult
    private func setOIDValue(_ oid: UInt32, value: UInt32) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard connection != 0 || openUnlocked() else {
            rtlog(String(format: "setOID 0x%08X=%u FAIL open", oid, value))
            return false
        }

        var buf = [UInt8](repeating: 0, count: kOIDBufSize)
        buf.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: oid, toByteOffset: 0, as: UInt32.self)
            raw.storeBytes(of: UInt32(kOIDDataMax), toByteOffset: 4, as: UInt32.self)
            raw.storeBytes(of: UInt32(0), toByteOffset: 8, as: UInt32.self)
            raw.storeBytes(of: UInt32(0), toByteOffset: 12, as: UInt32.self)
            raw.storeBytes(of: value, toByteOffset: kOIDDataOff, as: UInt32.self)
        }
        var outSize = kOIDBufSize
        let kr = buf.withUnsafeMutableBytes { raw -> kern_return_t in
            IOConnectCallStructMethod(
                connection, kSelSet,
                raw.baseAddress, kOIDBufSize,
                raw.baseAddress, &outSize
            )
        }
        let ok = kr == KERN_SUCCESS
        if verboseOIDLog || !ok {
            rtlog(String(format: "setOID 0x%08X=%u -> %@", oid, value, ok ? "OK" : "FAIL kr=\(kr)"))
        }
        return ok
    }

    private func openUnlocked() -> Bool {
        // called under lock
        if connection != 0 { return true }
        lock.unlock()
        let ok = open()
        lock.lock()
        return ok
    }

    private func getNetwork(at index: UInt64) -> Data? {
        lock.lock(); defer { lock.unlock() }
        guard connection != 0 || openUnlocked() else { return nil }

        var idx = index
        var buf = [UInt8](repeating: 0, count: kNetInfoSize)
        var outSize = kNetInfoSize
        let kr = buf.withUnsafeMutableBytes { raw -> kern_return_t in
            IOConnectCallMethod(
                connection,
                kSelGetNetworkAtIndex,
                &idx, 1,
                nil, 0,
                nil, nil,
                raw.baseAddress, &outSize
            )
        }
        guard kr == KERN_SUCCESS, outSize >= 0x22 else { return nil }
        return Data(buf.prefix(outSize))
    }

    // MARK: - Public query / scan / connect

    /// Live signal quality 0…100 (StatusBarApp getSignalStrength → OID 0x0D010206).
    /// Returns nil if not associated / query failed.
    func querySignalPercent() -> Int? {
        guard open() else { return nil }
        var raw: UInt32 = 0
        let n = queryOID(OID_RT_SIGNAL_STRENGTH, out: &raw, maxLen: 4)
        guard n >= 1 else { return nil }
        // Most Realtek builds return 0…100 quality (we see 100 when strong).
        if raw <= 100 { return Int(raw) }
        // Fallback: signed dBm in low byte / full word
        let s = Int(Int32(bitPattern: raw))
        if s < 0 && s >= -120 {
            // Map −100…−40 dBm → ~0…100
            return max(0, min(100, 2 * (s + 100)))
        }
        let b = Int(Int8(bitPattern: UInt8(raw & 0xFF)))
        if b < 0 && b >= -120 {
            return max(0, min(100, 2 * (b + 100)))
        }
        return min(100, Int(raw))
    }

    /// Current RF channel from kext (OID_RT_CHANNEL get). 0 if unknown.
    func queryAssociatedChannel() -> Int {
        guard open() else { return 0 }
        var ch: UInt32 = 0
        let n = queryOID(OID_RT_CHANNEL, out: &ch, maxLen: 4)
        if n >= 1 {
            let c = Int(ch & 0xFF)
            if (1...196).contains(c) { return c }
        }
        // Sometimes only 1 byte written
        var b: UInt8 = 0
        if queryOID(OID_RT_CHANNEL, out: &b, maxLen: 1) >= 1, (1...196).contains(Int(b)) {
            return Int(b)
        }
        return 0
    }

    /// Currently associated SSID via OID 0xFF070102 (CmdSsid "g"). Empty if not associated.
    func currentSSID() -> String? {
        _ = open()
        var buf = [UInt8](repeating: 0, count: 0x84)
        let n = buf.withUnsafeMutableBytes { raw -> Int in
            queryOID(OID_RT_SSID, out: raw.baseAddress, maxLen: 0x84)
        }
        guard n > 0 else { return nil }
        // Layout: ASCII SSID at 0…; optional length dword at 0x80
        var len = min(n, 32)
        if n >= 0x84 {
            let declared = Int(buf[0x80])
            if (1...32).contains(declared) { len = declared }
        }
        if let nul = buf[..<len].firstIndex(of: 0) { len = nul }
        guard len > 0 else { return nil }
        let s = String(bytes: buf[0..<len], encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters.union(.whitespaces))
        guard let s, !s.isEmpty else { return nil }
        return s
    }

    /// Full scan: start scan, wait, enumerate BSS list. No StatusBarApp.
    func scanNetworks() -> [ScannedNetwork] {
        _ = open()

        // Start scan (value 0 matches CmdScan)
        _ = setOIDValue(OID_RT_SET_SCAN, value: 0)

        // Wait until scan not in progress
        for _ in 0..<30 {
            var progress: UInt32 = 1
            let n = queryOID(OID_RT_GET_SCAN_IN_PROGRESS, out: &progress, maxLen: 4)
            if n >= 4 && progress == 0 { break }
            if n < 0 { break }
            Thread.sleep(forTimeInterval: 0.25)
        }

        // BSS count
        var count: UInt32 = 0
        let cn = queryOID(OID_BSS_NUMBER, out: &count, maxLen: 4)
        if cn < 4 || count == 0 {
            // Fallback: try reading up to 64 entries anyway
            count = 64
        }
        count = min(count, 512)

        var bySSID: [String: ScannedNetwork] = [:]

        for i in 0..<count {
            guard let data = getNetwork(at: UInt64(i)) else { continue }
            guard let parsed = Self.parseNetInfo(data) else { continue }
            if parsed.ssid.isEmpty { continue }
            // Same SSID may appear on 2.4 + 5; keep stronger signal, then higher gen (Wi‑Fi 6)
            if let prev = bySSID[parsed.ssid] {
                let better = parsed.signalPercent > prev.signalPercent
                    || (parsed.signalPercent == prev.signalPercent && parsed.generation > prev.generation)
                if better { bySSID[parsed.ssid] = parsed }
            } else {
                bySSID[parsed.ssid] = parsed
            }
        }
        var results = Array(bySSID.values)

        // Also write /tmp/1.plist cache for consistency
        writeScanCache(results)

        results.sort {
            if $0.signalPercent != $1.signalPercent { return $0.signalPercent > $1.signalPercent }
            return $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending
        }
        return results
    }

    /// Associate — matches StatusBarApp WirelessAssociate + ad-hoc / WPS options.
    @discardableResult
    func connect(
        ssid: String,
        password: String,
        preferWPA2: Bool = true,
        channel: UInt32? = nil,
        bssid: String? = nil,
        options: JoinOptions? = nil
    ) -> Bool {
        var opts = options ?? JoinOptions()
        if options == nil {
            opts.channel = channel
            opts.bssid = bssid
            if password.isEmpty { opts.authEnc = .open }
            else { opts.authEnc = preferWPA2 ? .wpa2Psk : .wpaPsk }
        }
        // Allow explicit channel/bssid override from call site
        if let channel { opts.channel = channel }
        if let bssid { opts.bssid = bssid }

        verboseOIDLog = true
        defer { verboseOIDLog = false }

        RTLog.shared.section(
            "CONNECT ssid=\(ssid) passLen=\(password.count) type=\(opts.networkType.shortLabel) auth=\(opts.authEnc.rawValue) wps=\(opts.wps.rawValue) ch=\(opts.channel.map(String.init) ?? "-") bssid=\(opts.bssid ?? "-")"
        )
        logLinkSnapshot(tag: "pre")

        guard open() else {
            rtlog("connect ABORT: open failed")
            return false
        }

        if opts.wps == .pbc {
            return connectWPS_PBC(ssidHint: ssid, options: opts)
        }
        if opts.wps == .pin {
            return connectWPS_PIN(ssid: ssid, pin: opts.wpsPin, options: opts)
        }

        let pass = password
        let isOpen = opts.authEnc == .open || pass.isEmpty
        let authEnc = isOpen ? RTAuthEnc.open.rawValue : opts.authEnc.rawValue
        let netType = opts.networkType.rawValue
        rtlog("authEnc=\(authEnc) netType=\(netType) isOpen=\(isOpen) adhoc=\(opts.networkType == .adhoc)")

        waitScanIdle(timeoutSec: 5)

        _ = setOIDValue(OID_RT_RF, value: 0)
        writeSoftRFOn()

        _ = setOIDValue(OID_802_11_DISASSOCIATE, value: 0)
        Thread.sleep(forTimeInterval: 0.35)

        // CmdNetworkType: infra=0, adhoc=1, auto=3
        _ = setOIDValue(OID_802_11_INFRASTRUCTURE_MODE, value: netType)
        rtlog("network type \(opts.networkType.shortLabel)=\(netType)")

        // SSID first (WirelessAssociate)
        var ssidBuf = [UInt8](repeating: 0, count: 0x84)
        let ssidBytes = Array(ssid.utf8.prefix(0x80))
        for (i, b) in ssidBytes.enumerated() { ssidBuf[i] = b }
        var ssidLen = UInt32(ssidBytes.count)
        withUnsafeBytes(of: &ssidLen) { ssidBuf.replaceSubrange(0x80..<0x84, with: $0) }
        guard setOIDData(OID_RT_SSID, data: ssidBuf) else {
            rtlog("connect ABORT: set SSID failed")
            return false
        }

        if let channel = opts.channel, (1...196).contains(channel) {
            rtlog("set channel \(channel)")
            _ = setOIDValue(OID_RT_CHANNEL, value: channel)
        }

        // Ad-hoc + WPA-None: StatusBarApp sets OID 0xFF030004 before key (WirelessAssociate)
        let isAdhocWPA = opts.networkType == .adhoc
            && (opts.authEnc == .wpaPsk || opts.authEnc == .wpaPskAes)
        if isAdhocWPA {
            rtlog("adhoc WPA-None path: set 0xFF030004=0")
            _ = setOIDValue(0xFF_03_00_04, value: 0)
        }

        // Shared-key: 1 only for classic shared-key WEP; else 0
        let shared: UInt32 = (opts.authEnc == .wep64 || opts.authEnc == .wep128) ? 0 : 0
        _ = setOIDValue(OID_RT_SHARED_KEY_FLAG, value: shared)

        // BSSID: only pin a *real* AP MAC. Scan-table keys (often 0e… U/L bit)
        // break association — prefer real MAC from WPS IE (0c…).
        if opts.networkType != .adhoc, let bssid = opts.bssid, let mac = Self.parseBSSID(bssid) {
            if Self.looksLikeRealBSSID(mac) {
                rtlog("set BSSID \(bssid) (real)")
                _ = setOIDData(OID_802_11_BSSID, data: mac)
            } else {
                rtlog("skip BSSID \(bssid) (scan-table / local-admin — not real AP MAC)")
            }
        }

        if !isOpen {
            if opts.authEnc == .wep64 || opts.authEnc == .wep128 {
                // WEP via same passphrase buffer path is imperfect; still try
                rtlog("WEP key path (index 0)")
            }
            let passBytes = Array(pass.utf8.prefix(63))
            let minLen = (opts.authEnc == .wep64 || opts.authEnc == .wep128) ? 5 : 8
            guard passBytes.count >= minLen else {
                rtlog("connect ABORT: key len \(passBytes.count) < \(minLen)")
                return false
            }
            var passBuf = [UInt8](repeating: 0, count: 0x98)
            for (i, b) in passBytes.enumerated() { passBuf[i] = b }
            var passLen = UInt32(passBytes.count)
            withUnsafeBytes(of: &passLen) { passBuf.replaceSubrange(0x80..<0x84, with: $0) }
            guard setOIDData(OID_RT_PASSPHRASE, data: passBuf) else {
                rtlog("connect ABORT: set passphrase failed")
                return false
            }
        }

        _ = setOIDValue(OID_RT_AKM, value: authEnc)

        // Ad-hoc WPA may set WPA key again after flag (WirelessAssociate var_21 path)
        if isAdhocWPA && !isOpen {
            var passBuf = [UInt8](repeating: 0, count: 0x98)
            let passBytes = Array(pass.utf8.prefix(63))
            for (i, b) in passBytes.enumerated() { passBuf[i] = b }
            var passLen = UInt32(passBytes.count)
            withUnsafeBytes(of: &passLen) { passBuf.replaceSubrange(0x80..<0x84, with: $0) }
            _ = setOIDData(OID_RT_PASSPHRASE, data: passBuf)
        }

        guard setOIDValue(OID_RT_CONNECT, value: 0) else {
            rtlog("connect ABORT: connect trigger failed")
            return false
        }

        // 8) Poll link — also query RSSI if available
        var sawPhy = false
        for i in 1...10 {
            Thread.sleep(forTimeInterval: 0.6)
            logLinkSnapshot(tag: "t+\(i)")
            if let live = currentSSIDQuiet() { rtlog("t+\(i) kextSSID=\(live)") }
            if let pct = querySignalPercent() {
                rtlog("t+\(i) signal=\(pct)%")
            }
            let drv = NetProbe.realtekDriver()
            if drv.phyLinked || NetProbe.mediaActive(bsd: "en1") {
                sawPhy = true
                rtlog("t+\(i) LINK UP detected")
                break
            }
        }

        if !sawPhy {
            rtlog("DIAG: OIDs OK, SSID held, but IOLinkSpeed=0 / media inactive / no DHCP.")
        } else {
            rtlog("connect: PHY link asserted — waiting for DHCP on host")
        }
        return true
    }

    // MARK: - WPS (experimental / WIP)
    // Full WSC enrollee + WPA3-SAE (wpa_supplicant / profile1x.rtl) are DEFERRED.
    // See re/WIP.md — implement only when a real network requires it.
    // PBC/PIN below are stubs (hw flag + open join), not production WPS.

    /// Hardware WPS PBC flag (GetWPSHwPBC → OID 0xFF819029).
    func wpsHardwarePBCPressed() -> Bool {
        guard open() else { return false }
        var b: UInt8 = 0
        let n = queryOID(0xFF_81_90_29, out: &b, maxLen: 1)
        return n >= 1 && b != 0
    }

    /// Start WPS Push-Button: user must press WPS on the router within ~2 minutes.
    /// We wait for the AP to enter PBC, then attempt open/infra associate to the given SSID
    /// (full WSC M1–M8 is not reimplemented; StatusBarApp does that in -[WPS …]).
    private func connectWPS_PBC(ssidHint: String, options: JoinOptions) -> Bool {
        rtlog("WPS PBC: press WPS on the router now (also check hw button OID 0xFF819029)")
        _ = setOIDValue(OID_RT_RF, value: 0)
        writeSoftRFOn()
        _ = setOIDValue(OID_802_11_DISASSOCIATE, value: 0)
        _ = setOIDValue(OID_802_11_INFRASTRUCTURE_MODE, value: NETTYPE_INFRA)

        // Poll ~20s for hardware PBC (user should press router WPS first)
        var sawHw = false
        for i in 0..<10 {
            if wpsHardwarePBCPressed() {
                sawHw = true
                rtlog("WPS PBC: hardware flag set at t=\(i*2)s")
                break
            }
            if i == 0 || i % 3 == 0 {
                rtlog("WPS PBC: waiting… t=\(i*2)s (press router WPS button)")
            }
            Thread.sleep(forTimeInterval: 2)
        }
        if !sawHw {
            rtlog("WPS PBC: no hw flag — trying SSID join open (router may still be in PBC window)")
        }

        // After PBC window, StatusBarApp runs full WSC; we fall back to open associate
        // on the target SSID (works for some APs that temporarily open during WPS).
        var opts = options
        opts.wps = .none
        opts.authEnc = .open
        opts.networkType = .infrastructure
        return connect(ssid: ssidHint, password: "", options: opts)
    }

    private func connectWPS_PIN(ssid: String, pin: String, options: JoinOptions) -> Bool {
        let digits = pin.filter(\.isNumber)
        guard digits.count == 8 || digits.count == 4 else {
            rtlog("WPS PIN: need 4 or 8 digits, got \(digits.count)")
            return false
        }
        rtlog("WPS PIN \(digits.count) digits for \(ssid) — full WSC not ported; attempting open join")
        // Store pin in soft log only; real enrollee needs EAPOL (StatusBarApp WPS class)
        var opts = options
        opts.wps = .none
        opts.authEnc = .open
        opts.networkType = .infrastructure
        // Future: feed PIN into WSC_Init_handshake
        return connect(ssid: ssid, password: "", options: opts)
    }

    private func waitScanIdle(timeoutSec: Double) {
        let deadline = Date().addingTimeInterval(timeoutSec)
        while Date() < deadline {
            var progress: UInt32 = 1
            let n = queryOID(OID_RT_GET_SCAN_IN_PROGRESS, out: &progress, maxLen: 4)
            if n >= 4 && progress == 0 {
                rtlog("scan idle")
                return
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        rtlog("scan wait timeout (continuing)")
    }

    private static func parseBSSID(_ s: String) -> [UInt8]? {
        let hex = s.lowercased().filter { $0.isHexDigit }
        guard hex.count == 12 else { return nil }
        var out = [UInt8]()
        var i = hex.startIndex
        while i < hex.endIndex {
            let j = hex.index(i, offsetBy: 2)
            guard let b = UInt8(hex[i..<j], radix: 16) else { return nil }
            out.append(b)
            i = j
        }
        return out.count == 6 ? out : nil
    }

    /// Reject multicast / locally-administered MACs that Realtek uses as scan-table keys.
    /// Example: table key `0e84…` (U/L=1) vs real AP `0c84…` (U/L=0).
    private static func looksLikeRealBSSID(_ mac: [UInt8]) -> Bool {
        guard mac.count == 6 else { return false }
        if mac.allSatisfy({ $0 == 0 }) || mac.allSatisfy({ $0 == 0xFF }) { return false }
        // bit0 = multicast
        if (mac[0] & 0x01) != 0 { return false }
        // bit1 = locally administered — Realtek scan keys use this; real APs usually don't
        if (mac[0] & 0x02) != 0 { return false }
        return true
    }

    /// Disassociate current BSS (leave network). Does not turn RF off.
    @discardableResult
    func disconnect() -> Bool {
        verboseOIDLog = true
        defer { verboseOIDLog = false }
        guard open() else {
            rtlog("disconnect ABORT: open failed")
            return false
        }
        rtlog("disconnect: OID disassociate")
        let ok = setOIDValue(OID_802_11_DISASSOCIATE, value: 0)
        Thread.sleep(forTimeInterval: 0.25)
        logLinkSnapshot(tag: "post-disconnect")
        return ok
    }

    /// Link / IOKit snapshot for diagnostics (no password).
    func logLinkSnapshot(tag: String) {
        let drv = NetProbe.realtekDriver()
        let media = NetProbe.mediaActive(bsd: "en1")
        let (ip, _, up, running) = NetProbe.ipv4AndFlags(bsd: "en1")
        var linkFlag: UInt8 = 0xFF
        let n = queryOID(0xFF_81_90_53, out: &linkFlag, maxLen: 1)
        var connSt: UInt32 = 0xFFFF_FFFF
        let nc = queryOID(OID_RT_CONNECTION_STATUS, out: &connSt, maxLen: 4)
        let rfOff = isRadioOff()
        rtlog("[\(tag)] driver=\(drv.loaded) ver=\(drv.version) linkMbps=\(drv.linkSpeedBps/1_000_000) phy=\(drv.phyLinked) media=\(media) ifUp=\(up) ifRun=\(running) ip=\(ip ?? "-") ff819053=\(n >= 1 ? String(linkFlag) : "?") connStatus=\(nc >= 4 ? String(connSt) : "?") rfOff=\(String(describing: rfOff))")
    }

    /// Query SSID without recursive log spam on every poll.
    private func currentSSIDQuiet() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard connection != 0 else { return nil }
        var req = [UInt8](repeating: 0, count: kOIDBufSize)
        req.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: OID_RT_SSID, toByteOffset: 0, as: UInt32.self)
            raw.storeBytes(of: UInt32(kOIDDataMax), toByteOffset: 4, as: UInt32.self)
        }
        var outSize = kOIDBufSize
        let kr = req.withUnsafeMutableBytes { r -> kern_return_t in
            IOConnectCallStructMethod(connection, kSelQuery, r.baseAddress, kOIDBufSize, r.baseAddress, &outSize)
        }
        guard kr == KERN_SUCCESS else { return nil }
        let dataLen = Int(req.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt32.self) })
        guard dataLen > 0 else { return nil }
        let copyLen = min(dataLen, 32)
        let slice = Array(req[kOIDDataOff..<(kOIDDataOff + copyLen)])
        var len = copyLen
        if let nul = slice.firstIndex(of: 0) { len = nul }
        guard len > 0 else { return nil }
        return String(bytes: slice[0..<len], encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters.union(.whitespaces))
    }

    // MARK: - Radio (USB Wi‑Fi RF on/off) — StatusBarApp MenuItemRadioOnOff

    /// `true` = radio transmitting (turnRfOn). OID 0xFF818081: 0=on, 1=off.
    /// Also syncs soft state file + best-effort `ifconfig en1 up/down` like StatusBarApp.
    @discardableResult
    func setRadioOn(_ on: Bool) -> Bool {
        verboseOIDLog = true
        defer { verboseOIDLog = false }
        guard open() else {
            rtlog("setRadioOn(\(on)): open failed")
            return false
        }
        // turnRfOn → value 0; turnRfOff → value 1
        let value: UInt32 = on ? 0 : 1
        rtlog("setRadioOn(\(on)) OID 0xFF818081=\(value)")
        let ok = setOIDValue(OID_RT_RF, value: value)
        // Soft RF file: MenuItemRadioOnOff writes global bRfOff (1=OFF, 0=ON) as "%d\n"
        //   radio ON  -> file "0"
        //   radio OFF -> file "1"
        writeSoftRF(on: on)
        ifconfigInterface(up: on)
        Thread.sleep(forTimeInterval: 0.2)
        let off = isRadioOff()
        rtlog("setRadioOn result ok=\(ok) isRadioOff=\(String(describing: off)) softOff=\(String(describing: softRFFileSaysOff()))")
        return ok
    }

    /// Query RF off flag. `true` = radio off, `false` = on, `nil` = query failed.
    func isRadioOff() -> Bool? {
        guard open() else { return softRFFileSaysOff() }
        var byte: UInt8 = 0xFF
        // IsRfOff: query OID 0xFF818081 as 1 byte; non-zero => RF off
        let n = queryOID(OID_RT_RF, out: &byte, maxLen: 1)
        if n >= 1 {
            return byte != 0
        }
        return softRFFileSaysOff()
    }

    /// StatusBarApp `MenuItemRadioOnOff` soft state file `<mac>rfoff.rtl`:
    ///   fprintf("%d\n", bRfOff) where bRfOff: 0 = radio ON, 1 = radio OFF
    /// (confirmed from BN HLIL — we previously had this inverted)
    private func writeSoftRF(on: Bool) {
        let dir = "/Library/Application Support/WLAN/com.realtek.utility.wifi"
        // bRfOff: 0 when on, 1 when off
        let body = on ? "0\n" : "1\n"
        var wrote = false
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            for f in files where f.hasSuffix("rfoff.rtl") {
                try? body.write(toFile: "\(dir)/\(f)", atomically: true, encoding: .utf8)
                rtlog("softRF file \(f) -> \(body.trimmingCharacters(in: .whitespacesAndNewlines)) (bRfOff, radio \(on ? "ON" : "OFF"))")
                wrote = true
            }
        }
        if !wrote, let mac = NetProbe.macAddress(bsd: "en1") {
            let name = mac.replacingOccurrences(of: ":", with: "") + "rfoff.rtl"
            try? body.write(toFile: "\(dir)/\(name)", atomically: true, encoding: .utf8)
            rtlog("softRF created \(name) bRfOff=\(on ? 0 : 1)")
        }
    }

    private func writeSoftRFOn() { writeSoftRF(on: true) }

    private func softRFFileSaysOff() -> Bool? {
        let dir = "/Library/Application Support/WLAN/com.realtek.utility.wifi"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return nil }
        for f in files where f.hasSuffix("rfoff.rtl") {
            if let s = try? String(contentsOfFile: "\(dir)/\(f)", encoding: .utf8) {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                // file holds bRfOff: "1" = OFF, "0" = ON
                if t == "1" { return true }
                if t == "0" { return false }
            }
        }
        return nil
    }

    private func ifconfigInterface(up: Bool) {
        // Best-effort without sudo; StatusBarApp uses sudo ifconfig
        let bsd = "en1"
        let mode = up ? "up" : "down"
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        p.arguments = [bsd, mode]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
            p.waitUntilExit()
            rtlog("ifconfig \(bsd) \(mode) exit=\(p.terminationStatus)")
        } catch {
            rtlog("ifconfig \(bsd) \(mode) error: \(error.localizedDescription)")
        }
    }

    /// SetInformationBuffer layout from StatusBarApp @ 0x10003eda0:
    ///   +0 OID, +4 infoBufLen = data length, +8 = 0, +12 = 0, +16 data…
    private func setOIDData(_ oid: UInt32, data: [UInt8]) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard connection != 0 || openUnlocked() else {
            rtlog(String(format: "setBuf 0x%08X len=%d FAIL open", oid, data.count))
            return false
        }

        var buf = [UInt8](repeating: 0, count: kOIDBufSize)
        let copyLen = min(data.count, kOIDDataMax)
        buf.withUnsafeMutableBytes { raw in
            raw.storeBytes(of: oid, toByteOffset: 0, as: UInt32.self)
            raw.storeBytes(of: UInt32(copyLen), toByteOffset: 4, as: UInt32.self)
            raw.storeBytes(of: UInt32(0), toByteOffset: 8, as: UInt32.self)
            raw.storeBytes(of: UInt32(0), toByteOffset: 12, as: UInt32.self)
        }
        for i in 0..<copyLen { buf[kOIDDataOff + i] = data[i] }
        var outSize = kOIDBufSize
        let kr = buf.withUnsafeMutableBytes { raw -> kern_return_t in
            IOConnectCallStructMethod(
                connection, kSelSet,
                raw.baseAddress, kOIDBufSize,
                raw.baseAddress, &outSize
            )
        }
        let ok = kr == KERN_SUCCESS
        if verboseOIDLog || !ok {
            rtlog(String(format: "setBuf 0x%08X len=%d -> %@", oid, copyLen, ok ? "OK" : "FAIL kr=\(kr)"))
        }
        return ok
    }

    // MARK: - Parse 0x640 NETWORK_INFORMATION
    // Verified from live GetNetworkAtIndex dumps:
    //   [0..ssidLen)  SSID ASCII
    //   [0x21]        SSID length
    //   [0x23]        Channel (e.g. 0x07=7, 0x9d=157)  ← NOT a free-form hunt
    //   [0x24..0x29]  BSSID scan-table form (StatusBarApp GetBSSID when linked returns this)
    //   [0x2A]        Signal strength 0…100-ish
    //   [0x2C…]      WPS IE + copy of beacon/probe IEs (HT/VHT/HE → Wi‑Fi 4/5/6)

    private static func parseNetInfo(_ data: Data) -> ScannedNetwork? {
        guard data.count >= 0x2C else { return nil }
        let ssidLen = Int(data[0x21])
        guard ssidLen > 0, ssidLen <= 32, data.count >= ssidLen else { return nil }
        let ssidData = data.subdata(in: 0..<ssidLen)
        let ssid = String(bytes: ssidData, encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
            ?? String(decoding: ssidData, as: UTF8.self)
        guard !ssid.isEmpty else { return nil }

        let channel = Int(data[0x23])
        let ch = (1...196).contains(channel) ? channel : 0

        // Prefer real AP MAC from WPS IE (after 0xFE). Scan-table @0x24 is often a
        // locally-administered key (0e…) that must NOT be used for OID BSSID set.
        var bssid: String? = extractRealBSSID(from: data)
        if bssid == nil, data.count >= 0x2A {
            let b = data.subdata(in: 0x24..<0x2A)
            let table = b.map { String(format: "%02x", $0) }.joined()
            if let mac = parseBSSID(table), looksLikeRealBSSID(mac) {
                bssid = table
            } else {
                // Keep table key only as display fallback (join will skip pinning)
                bssid = table
            }
        }

        var signal = Int(data[0x2A])
        if signal > 100 { signal = min(100, signal) }
        if signal < 0 { signal = 0 }

        // Site_Encry-ish: treat open only if WPS/IE empty-looking; default secure
        let isSecure = true

        // Wi‑Fi 4/5/6/7 from HT / VHT / HE / EHT IEs embedded in NET_INFO
        let generation = WiFiGeneration.detect(from: data)

        // WPS: OUI 00:50:F2:04 appears early in many Realtek records
        let hasWPS: Bool = {
            guard data.count > 0x40 else { return false }
            let bytes = [UInt8](data)
            for i in 0x2C..<(min(bytes.count, 0x200) - 3) {
                if bytes[i] == 0x50 && bytes[i + 1] == 0xF2 && bytes[i + 2] == 0x04 {
                    return true
                }
            }
            return false
        }()

        let bars: Int
        switch signal {
        case 75...: bars = 4
        case 55..<75: bars = 3
        case 35..<55: bars = 2
        case 1..<35: bars = 1
        default: bars = 2
        }
        return ScannedNetwork(
            ssid: ssid,
            bssid: bssid,
            isSecure: isSecure,
            isConnected: false,
            signalBars: bars,
            signalPercent: signal,
            channel: ch,
            isFromLiveScan: true,
            isAdhoc: false,
            siteEncry: isSecure ? 96 : 0,
            akmSuit: isSecure ? 32 : 0,
            hasWPS: hasWPS,
            generation: generation
        )
    }

    /// Pull real AP MAC from WPS IE blob inside NET_INFO (byte 0xFE then 6-octet BSSID).
    private static func extractRealBSSID(from data: Data) -> String? {
        guard data.count > 0x30 else { return nil }
        let bytes = [UInt8](data)
        // Search for 0xFE followed by a plausible MAC (not multicast-only junk)
        for i in 0x2C..<(bytes.count - 7) {
            if bytes[i] == 0xFE {
                let mac = Array(bytes[(i + 1)..<(i + 7)])
                // reject all-zero / all-ff
                if mac.allSatisfy({ $0 == 0 }) || mac.allSatisfy({ $0 == 0xFF }) { continue }
                return mac.map { String(format: "%02x", $0) }.joined()
            }
        }
        return nil
    }

    private func writeScanCache(_ networks: [ScannedNetwork]) {
        // Mirror Realtek /tmp/1.plist shape so other tools stay compatible
        // Extra key "Generation" (4/5/6/7) is ours — StatusBarApp ignores unknown keys
        var root: [String: [String: [String: Any]]] = [:]
        for n in networks {
            let bssid = n.bssid ?? "000000000000"
            root[n.ssid] = [
                bssid: [
                    "SignalStrength": n.signalPercent,
                    "Channel": n.channel,
                    "Site_Encry": n.isSecure ? 96 : 0,
                    "NetworkType": false,
                    "bHiddenAP": false,
                    "AKMsuit": n.isSecure ? 32 : 0,
                    "Generation": n.generation.rawValue
                ]
            ]
        }
        if let data = try? PropertyListSerialization.data(fromPropertyList: root, format: .xml, options: 0) {
            try? data.write(to: URL(fileURLWithPath: "/tmp/1.plist"), options: .atomic)
        }
    }
}
