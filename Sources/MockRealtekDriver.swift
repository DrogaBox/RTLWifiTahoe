import Foundation

// MARK: - MockRealtekDriver

/// A test/preview double for `RealtekDriverProtocol` that returns canned answers
/// without touching IOKit or real hardware. Allows SwiftUI previews to render
/// realistic UI state on any Mac.
final class MockRealtekDriver: RealtekDriverProtocol {
    // MARK: Configurable canned state

    /// BSD name the mock pretends to drive.
    var currentBSD: String = "en1"

    /// Simulated driver loaded state.
    var driverLoaded: Bool = true

    /// Simulated radio on/off.
    var radioOn: Bool = true

    /// Simulated connected SSID. `nil` = not associated.
    var connectedSSID: String? = nil

    /// Simulated signal percent 0…100.
    var signalPercent: Int = 0

    /// Simulated channel (1…196).
    var channel: Int = 6

    /// Simulated link speed in bps. > 0 → PHY linked.
    var linkSpeedBps: UInt64 = 0

    /// Simulated scan results.
    var scanResults: [ScannedNetwork] = MockRealtekDriver.defaultScanResults()

    /// Whether `setRadioOn` succeeds.
    var setRadioOnSuccess: Bool = true

    /// Whether `disconnect` succeeds.
    var disconnectSuccess: Bool = true

    /// Whether `connect` succeeds.
    var connectSuccess: Bool = true

    /// Whether `open` succeeds.
    var openSuccess: Bool = true

    /// WPS hardware PBC flag.
    var wpsHardwarePressed: Bool = false

    // MARK: Call tracking for test assertions

    private(set) var openCallCount: Int = 0
    private(set) var scanCallCount: Int = 0
    private(set) var connectCallCount: Int = 0
    private(set) var disconnectCallCount: Int = 0
    private(set) var setRadioOnCallCount: Int = 0
    private(set) var lastConnectSSID: String = ""
    private(set) var lastConnectPassword: String = ""
    private(set) var lastSetRadioOnValue: Bool = false
    private(set) var lastSetRadioOnBSD: String? = nil

    // MARK: - RealtekDriverProtocol

    @discardableResult
    func open() -> Bool {
        openCallCount += 1
        return openSuccess
    }

    func querySignalPercent() -> Int? {
        guard driverLoaded, radioOn, connectedSSID != nil else { return nil }
        return signalPercent
    }

    func queryAssociatedChannel() -> Int {
        guard driverLoaded, radioOn else { return 0 }
        return channel
    }

    func currentSSID() -> String? {
        guard driverLoaded, radioOn else { return nil }
        return connectedSSID
    }

    func scanNetworks() async -> [ScannedNetwork] {
        scanCallCount += 1
        guard driverLoaded, radioOn else { return [] }
        return scanResults
    }

    @discardableResult
    func connect(
        ssid: String,
        password: String,
        preferWPA2: Bool = true,
        channel: UInt32? = nil,
        bssid: String? = nil,
        options: JoinOptions? = nil
    ) async -> Bool {
        connectCallCount += 1
        lastConnectSSID = ssid
        lastConnectPassword = password
        if connectSuccess {
            connectedSSID = ssid
            signalPercent = 75
            linkSpeedBps = 300_000_000
        }
        return connectSuccess
    }

    func wpsHardwarePBCPressed() -> Bool {
        wpsHardwarePressed
    }

    @discardableResult
    func disconnect() async -> Bool {
        disconnectCallCount += 1
        if disconnectSuccess {
            connectedSSID = nil
            signalPercent = 0
            linkSpeedBps = 0
        }
        return disconnectSuccess
    }

    func logLinkSnapshot(tag: String) {
        // no‑op in mock
    }

    @discardableResult
    func setRadioOn(_ on: Bool, bsd: String? = nil) async -> Bool {
        setRadioOnCallCount += 1
        lastSetRadioOnValue = on
        lastSetRadioOnBSD = bsd
        if setRadioOnSuccess {
            radioOn = on
        }
        return setRadioOnSuccess
    }

    func isRadioOff() -> Bool? {
        guard driverLoaded else { return nil }
        return !radioOn
    }

    // MARK: - Reset

    func reset() {
        currentBSD = "en1"
        driverLoaded = true
        radioOn = true
        connectedSSID = nil
        signalPercent = 0
        channel = 6
        linkSpeedBps = 0
        scanResults = Self.defaultScanResults()
        setRadioOnSuccess = true
        disconnectSuccess = true
        connectSuccess = true
        openSuccess = true
        wpsHardwarePressed = false
        openCallCount = 0
        scanCallCount = 0
        connectCallCount = 0
        disconnectCallCount = 0
        setRadioOnCallCount = 0
        lastConnectSSID = ""
        lastConnectPassword = ""
        lastSetRadioOnValue = false
        lastSetRadioOnBSD = nil
    }

    // MARK: - Default scan data

    private static func defaultScanResults() -> [ScannedNetwork] {
        [
            ScannedNetwork(
                ssid: "HomeNet",
                bssid: "0c84dcaa0001",
                isSecure: true,
                signalBars: 4,
                signalPercent: 92,
                channel: 6,
                isFromLiveScan: true,
                generation: .wifi6
            ),
            ScannedNetwork(
                ssid: "Neighbor-Fi",
                bssid: "1234abcd5678",
                isSecure: true,
                signalBars: 2,
                signalPercent: 45,
                channel: 1,
                isFromLiveScan: true,
                generation: .wifi5
            ),
            ScannedNetwork(
                ssid: "Airport Free WiFi",
                bssid: "aabbccddeeff",
                isSecure: false,
                signalBars: 1,
                signalPercent: 30,
                channel: 11,
                isFromLiveScan: true,
                generation: .wifi4
            ),
        ]
    }
}

// MARK: - Preview helpers

extension MockRealtekDriver {
    /// Returns a mock configured as if connected to a network with IP.
    static func connected(ssid: String = "HomeNet", ip: String = "192.168.1.42") -> MockRealtekDriver {
        let mock = MockRealtekDriver()
        mock.connectedSSID = ssid
        mock.signalPercent = 78
        mock.channel = 6
        mock.linkSpeedBps = 433_000_000
        return mock
    }

    /// Returns a mock in a linking/associating state.
    static func linking(ssid: String = "LinkingNet") -> MockRealtekDriver {
        let mock = MockRealtekDriver()
        mock.connectedSSID = ssid
        mock.signalPercent = 0
        mock.linkSpeedBps = 0
        return mock
    }

    /// Returns a mock with radio turned off.
    static func radioOff() -> MockRealtekDriver {
        let mock = MockRealtekDriver()
        mock.radioOn = false
        return mock
    }

    /// Returns a mock with the driver not loaded (no USB adapter).
    static func noDriver() -> MockRealtekDriver {
        let mock = MockRealtekDriver()
        mock.driverLoaded = false
        return mock
    }
}
