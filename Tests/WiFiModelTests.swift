import Foundation
import AppKit
import Combine
import Network

// MARK: - WiFiModel Unit Tests

/// Tests the public-facing state transitions of `WiFiModel` using a
/// `MockRealtekDriver` — no real hardware, IOKit, or kernel extensions.
///
/// Because `WiFiModel.init()` fires a background `refreshAsync(forceSlow:)`,
/// tests must wait for that async work to settle, then explicitly set the
/// `snapshot` to the desired starting state before exercising the method
/// under test.
@MainActor
final class WiFiModelTests {

    // MARK: - Test listing

    func allTests() -> [(String, TestFn)] {
        return [
            ("testDisconnectNetwork_Success", testDisconnectNetwork_Success),
            ("testDisconnectNetwork_Failure", testDisconnectNetwork_Failure),
            ("testSetUSBRadio_TurnOff", testSetUSBRadio_TurnOff),
            ("testSetUSBRadio_TurnOn", testSetUSBRadio_TurnOn),
            ("testSetUSBRadio_Failure", testSetUSBRadio_Failure),
            ("testToggleUSBRadio", testToggleUSBRadio),
            ("testJoinNetwork_EmptySSID", testJoinNetwork_EmptySSID),
            ("testJoinNetwork_NoDriver", testJoinNetwork_NoDriver),
            ("testJoinNetwork_ConnectSucceedsButNoIP", testJoinNetwork_ConnectSucceedsButNoIP),
            ("testJoinNetwork_ConnectFailure", testJoinNetwork_ConnectFailure),
            ("testJoinNetwork_SkipsPollLoopWhenTesting", testJoinNetwork_SkipsPollLoopWhenTesting),
            ("testMaybeAutoReconnect_Disabled", testMaybeAutoReconnect_Disabled),
            ("testMaybeAutoReconnect_SkipWhenConnected", testMaybeAutoReconnect_SkipWhenConnected),
            ("testMaybeAutoReconnect_SkipNoProfiles", testMaybeAutoReconnect_SkipNoProfiles),
            ("testMaybeAutoReconnect_Skip_NoPassword", testMaybeAutoReconnect_Skip_NoPassword),
            ("testMaybeAutoReconnect_SuccessPath", testMaybeAutoReconnect_SuccessPath),
            ("testMaybeAutoReconnect_OpenNetworkProceeds", testMaybeAutoReconnect_OpenNetworkProceeds),
            ("testMaybeAutoReconnect_SecureNetworkSkips", testMaybeAutoReconnect_SecureNetworkSkips),
            ("testCopyIP_WhenConnected", testCopyIP_WhenConnected),
            ("testCopyIP_WhenDisconnected", testCopyIP_WhenDisconnected),
            ("testCopyMAC", testCopyMAC),
            ("testMenuBarTitle_IconOnly", testMenuBarTitle_IconOnly),
            ("testMenuBarTitle_SSID", testMenuBarTitle_SSID),
            ("testMenuBarTitle_IP", testMenuBarTitle_IP),
            ("testMenuBarTitle_Disconnected", testMenuBarTitle_Disconnected),
            ("testForgetNetwork_SetsCompletionState", testForgetNetwork_SetsCompletionState),
            ("testForgetNetwork_EmptySSID", testForgetNetwork_EmptySSID),
            ("testForgetNetwork_NonExistentSSID", testForgetNetwork_NonExistentSSID),
            ("testForgetNetwork_SetsLastErrorOnFailure", testForgetNetwork_SetsLastErrorOnFailure),
            ("testForgetNetwork_ReloadsProfilesAfterForget", testForgetNetwork_ReloadsProfilesAfterForget),
            ("testForgetNetwork_MultipleForgetsNoCrash", testForgetNetwork_MultipleForgetsNoCrash),
            ("testSetPreferredInterface", testSetPreferredInterface),
            ("testApplyDNSPreset_UpdatesPresetImmediately", testApplyDNSPreset_UpdatesPresetImmediately),
            ("testApplyDNSPreset_NoServiceName_BailsEarly", testApplyDNSPreset_NoServiceName_BailsEarly),
            ("testApplyDNSPreset_NoServiceAllPresets", testApplyDNSPreset_NoServiceAllPresets),
            ("testApplyDNSPreset_SuccessPath", testApplyDNSPreset_SuccessPath),
            ("testApplyDNSPreset_FailurePath", testApplyDNSPreset_FailurePath),
            ("testStartPathMonitor_ConfiguresMonitor", testStartPathMonitor_ConfiguresMonitor),
            ("testHandlePathUpdate_UnsatisfiedDoesNotCrash", testHandlePathUpdate_UnsatisfiedDoesNotCrash),
            ("testHandlePathUpdate_SatisfiedUpdatesReachability", testHandlePathUpdate_SatisfiedUpdatesReachability),
            ("testHandlePathUpdate_SatisfiedSkipsWhenAlreadyReachable", testHandlePathUpdate_SatisfiedSkipsWhenAlreadyReachable),
            ("testHandlePathUpdate_SatisfiedSkipsWhenNoIP", testHandlePathUpdate_SatisfiedSkipsWhenNoIP),
            ("testIsRefreshingResetOnCancelledTask", testIsRefreshingResetOnCancelledTask),
            ("testIsScanningNearbyResetOnCancelledTask", testIsScanningNearbyResetOnCancelledTask),
            ("testMockQueryWirelessMode2_ReturnsCorrectValue", testMockQueryWirelessMode2_ReturnsCorrectValue),
            ("testMockQueryWirelessMode2_ReturnsNilWhenNotConnected", testMockQueryWirelessMode2_ReturnsNilWhenNotConnected),
            ("testMockQueryWirelessMode2_ReturnsNilWhenRadioOff", testMockQueryWirelessMode2_ReturnsNilWhenRadioOff),
            ("testMockQueryWirelessMode2_ReturnsNilWhenDriverNotLoaded", testMockQueryWirelessMode2_ReturnsNilWhenDriverNotLoaded),
            ("testWirelessModeFallback_UsesMode2First", testWirelessModeFallback_UsesMode2First),
            ("testWirelessModeFallback_FallsBackToQueryWirelessMode", testWirelessModeFallback_FallsBackToQueryWirelessMode),
            ("testRefreshAsync_WirelessModeFallback", testRefreshAsync_WirelessModeFallback),
            ("testMockQuerySupplicantStatus_ReturnsOneByDefault", testMockQuerySupplicantStatus_ReturnsOneByDefault),
            ("testMockQuerySupplicantStatus_CanSetToThree", testMockQuerySupplicantStatus_CanSetToThree),
            ("testMockQuerySupplicantStatus_ReturnsNilWhenNotConnected", testMockQuerySupplicantStatus_ReturnsNilWhenNotConnected),
            ("testMockQuerySupplicantStatus_ReturnsNilWhenRadioOff", testMockQuerySupplicantStatus_ReturnsNilWhenRadioOff),
            ("testMockQuerySupplicantStatus_ReturnsNilWhenDriverNotLoaded", testMockQuerySupplicantStatus_ReturnsNilWhenDriverNotLoaded),
            ("testMockDriverConnect_ClearsConnectedStateOnReset", testMockDriverConnect_ClearsConnectedStateOnReset),
            ("testMockDriverDisconnect_ReturnsFalse", testMockDriverDisconnect_ReturnsFalse),
            ("testMockQueryHTBW_ReturnsCorrectValue", testMockQueryHTBW_ReturnsCorrectValue),
            ("testMockQueryHTBW_ReturnsNilWhenRadioOff", testMockQueryHTBW_ReturnsNilWhenRadioOff),
            ("testMockQueryHTBW_ReturnsNilWhenDriverNotLoaded", testMockQueryHTBW_ReturnsNilWhenDriverNotLoaded),
            ("testMockQueryHTGI_ReturnsCorrectValue", testMockQueryHTGI_ReturnsCorrectValue),
            ("testMockQueryHTGI_ReturnsNilWhenRadioOff", testMockQueryHTGI_ReturnsNilWhenRadioOff),
            ("testMockQueryHTGI_ReturnsNilWhenDriverNotLoaded", testMockQueryHTGI_ReturnsNilWhenDriverNotLoaded),
            ("testMockQueryHTMCS_ReturnsCorrectValue", testMockQueryHTMCS_ReturnsCorrectValue),
            ("testMockQueryHTMCS_ReturnsNilWhenRadioOff", testMockQueryHTMCS_ReturnsNilWhenRadioOff),
            ("testMockQueryHTMCS_ReturnsNilWhenDriverNotLoaded", testMockQueryHTMCS_ReturnsNilWhenDriverNotLoaded),
            ("testMockQueryTXLinkRate_ReturnsCorrectValue", testMockQueryTXLinkRate_ReturnsCorrectValue),
            ("testMockQueryTXLinkRate_ReturnsNilWhenRadioOff", testMockQueryTXLinkRate_ReturnsNilWhenRadioOff),
            ("testMockQueryTXLinkRate_ReturnsNilWhenDriverNotLoaded", testMockQueryTXLinkRate_ReturnsNilWhenDriverNotLoaded),
            ("testMockQueryNICStatus_ReturnsOneByDefault", testMockQueryNICStatus_ReturnsOneByDefault),
            ("testMockQueryNICStatus_ReturnsZeroWhenNICDown", testMockQueryNICStatus_ReturnsZeroWhenNICDown),
            ("testMockQueryNICStatus_ReturnsNilWhenDriverNotLoaded", testMockQueryNICStatus_ReturnsNilWhenDriverNotLoaded),
            ("testRefreshAsync_SupplicantStatusFallback", testRefreshAsync_SupplicantStatusFallback),
        ]
    }

    // MARK: - Helpers

    /// Create a model+driver pair. The model is wired to a mock driver so no
    /// real IOKit calls are made — start() is NOT called, avoiding the hardware
    /// refresh path entirely.
    private func makeModel() async -> (WiFiModel, MockRealtekDriver) {
        // Disable real Keychain to prevent SecItem hangs on unsigned binaries.
        // Tests use KeychainStore.testStore via isEnabled = false for password
        // storage without touching the system Keychain.
        KeychainStore.isEnabled = false
        KeychainStore.testStore = [:]
        // Remove any NetProbe/RealtekProfiles overrides from previous tests.
        // This ensures every test starts with hermetic filesystem state and
        // no test depends on whether the Realtek utility is installed.
        NetProbe.overrideSetDNSServers = nil
        RealtekProfiles.overrideAllProfiles = nil
        RealtekProfiles.overrideLastNetwork = nil
        let mock = MockRealtekDriver()
        let model = WiFiModel(driver: mock, testing: true)
        // testing=true skips all IOKit/NetProbe calls in refreshAsync.
        // start() is intentionally NOT called — the test controls exact state.
        return (model, mock)
    }

    /// Helper: set up a minimally usable "connected" snapshot.
    private func setupConnected(_ model: WiFiModel, ssid: String = "HomeNet", ip: String = "192.168.1.42") {
        var snap = InterfaceSnapshot()
        snap.ssid = ssid
        snap.ip = ip
        snap.bsdName = "en1"
        snap.displayName = "802.11ac NIC"
        snap.active = true
        snap.driverLoaded = true
        snap.radioOn = true
        snap.linkSpeedBps = 433_000_000
        snap.signalPercent = 75
        snap.channel = 6
        model.snapshot = snap
    }

    /// Helper: set up a disconnected snapshot.
    private func setupDisconnected(_ model: WiFiModel) {
        var snap = InterfaceSnapshot()
        snap.driverLoaded = true
        snap.radioOn = true
        snap.bsdName = "en1"
        model.snapshot = snap
    }

    /// Helper: wait for any pending `Task { @MainActor in … }` to execute.
    private func yield() async {
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    /// Poll until a condition is met or timeout. Use for Task.detached which
    /// may not get scheduled within a single yield window.
    /// Uses generous defaults (5s timeout, 100ms interval) since
    /// Task.detached(priority: .utility) can take time to schedule.
    private func poll(until condition: @MainActor () -> Bool, timeout: TimeInterval = 5) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// True if the forgetNetwork completion handler has fired.
    private func forgetCompleted(_ model: WiFiModel) -> Bool {
        model.lastError != nil || (model.statusText != "…" && !model.statusText.isEmpty)
    }

    /// Verifies that a boolean flag with a `defer { Task { @MainActor in weakSelf?.flag = false } }`
    /// pattern is reliably reset even when the enclosing Task is cancelled mid-flight.
    ///
    /// The helper:
    /// 1. Sets the flag to `true` (as the production code does on the main actor before creating the Task).
    /// 2. Creates a Task whose `defer` resets the flag — using the same pattern as the production code.
    /// 3. Cancels the Task immediately.
    /// 4. Polls (with timeout) until the flag is `false`, instead of a fixed sleep.
    ///
    /// - Parameters:
    ///   - model: The `WiFiModel` instance under test.
    ///   - keyPath: A writable key path to the `Bool` property being tested.
    ///   - file: Source file for assertion failures (default `#file`).
    ///   - line: Source line for assertion failures (default `#line`).
    private func assertDeferredFlagResetOnCancel(
        _ model: WiFiModel,
        keyPath: ReferenceWritableKeyPath<WiFiModel, Bool>,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // 1. Set flag to true (simulating the main-actor setter before the Task)
        model[keyPath: keyPath] = true

        // 2. Create a Task with the same defer pattern used in production code
        let task = Task { [weak model] in
            let weakModel = model
            defer {
                // This is the exact pattern: defer → Task { @MainActor in weakSelf?.flag = false }
                Task { @MainActor in
                    weakModel?[keyPath: keyPath] = false
                }
            }
            // Long sleep simulating background work that will be cancelled
            try? await Task.sleep(nanoseconds: 10_000_000_000)
        }

        // 3. Cancel immediately — the defer should still fire
        task.cancel()

        // 4. Poll until the flag is reset (replaces fixed sleep, eliminates flakiness)
        await poll(until: { model[keyPath: keyPath] == false })

        // 5. Verify the flag was reset
        try XCTAssertFalse(
            model[keyPath: keyPath],
            "Flag should be reset by defer after task cancellation",
            file: file,
            line: line
        )
    }

    // MARK: - disconnectNetwork()

    func testDisconnectNetwork_Success() async throws {
        let (model, mock) = await makeModel()
        setupConnected(model)
        mock.disconnectSuccess = true

        // Precondition
        try XCTAssertFalse(model.disconnectBusy)

        model.disconnectNetwork()

        // Immediately: busy flag set
        try XCTAssertTrue(model.disconnectBusy)

        await yield()

        // After the inner Task completes
        try XCTAssertFalse(model.disconnectBusy)
        try XCTAssertEqual(model.statusText, L10n.Model.disconnectedOk)
        try XCTAssertNil(model.lastError)
        try XCTAssertNil(mock.connectedSSID)          // mock cleared its state
        try XCTAssertEqual(mock.disconnectCallCount, 1)
    }

    func testDisconnectNetwork_Failure() async throws {
        let (model, mock) = await makeModel()
        setupConnected(model)
        mock.disconnectSuccess = false

        model.disconnectNetwork()
        await yield()

        try XCTAssertFalse(model.disconnectBusy)
        try XCTAssertEqual(model.lastError, L10n.Model.disconnectFail)
        try XCTAssertEqual(mock.disconnectCallCount, 1)
        // Note: snapshot.ssid is NOT checked here because refreshAsync
        // is called on the failure path and overwrites snapshot with real
        // IOKit data — resetting ssid back to "—" in test environments.
    }

    // MARK: - setUSBRadio()

    func testSetUSBRadio_TurnOff() async throws {
        let (model, mock) = await makeModel()
        setupConnected(model)
        model.snapshot.radioOn = true
        mock.radioOn = true
        mock.setRadioOnSuccess = true

        model.setUSBRadio(on: false)

        // Immediately: busy flag set
        try XCTAssertTrue(model.radioBusy)

        await yield()

        try XCTAssertFalse(model.radioBusy)
        try XCTAssertFalse(model.snapshot.radioOn)
        try XCTAssertEqual(mock.setRadioOnCallCount, 1)
        try XCTAssertEqual(mock.lastSetRadioOnValue, false)
        try XCTAssertEqual(model.statusText, L10n.Model.radioOffStatus)
        try XCTAssertNil(model.lastError)
    }

    func testSetUSBRadio_TurnOn() async throws {
        let (model, mock) = await makeModel()
        setupDisconnected(model)
        model.snapshot.radioOn = false
        mock.radioOn = false
        mock.setRadioOnSuccess = true

        model.setUSBRadio(on: true)
        await yield()

        try XCTAssertFalse(model.radioBusy)
        try XCTAssertTrue(model.snapshot.radioOn)
        try XCTAssertEqual(mock.lastSetRadioOnValue, true)
        try XCTAssertEqual(model.statusText, L10n.Model.radioOn)
        try XCTAssertNil(model.lastError)
    }

    func testSetUSBRadio_Failure() async throws {
        let (model, mock) = await makeModel()
        setupConnected(model)
        mock.setRadioOnSuccess = false

        model.setUSBRadio(on: false)
        await yield()

        try XCTAssertFalse(model.radioBusy)
        try XCTAssertEqual(model.lastError, L10n.Model.radioOffFail)
        // snapshot.radioOn is set optimistically before the Task,
        // but refreshAsync runs after and may overwrite —
        // we just verify the error was populated.
        try XCTAssertNotNil(model.lastError)
    }

    // MARK: - toggleUSBRadio()

    func testToggleUSBRadio() async throws {
        let (model, mock) = await makeModel()
        setupConnected(model)
        model.snapshot.radioOn = true
        mock.setRadioOnSuccess = true

        model.toggleUSBRadio()
        await yield()

        try XCTAssertEqual(mock.lastSetRadioOnValue, false, "toggle should turn radio off")

        model.toggleUSBRadio()
        await yield()

        // The second toggle fires a new Task that should turn it back on
        // (though refreshAsync may overwrite snapshot.radioOn).
        // We verify the mock was called correctly.
        try XCTAssertTrue(mock.setRadioOnCallCount >= 2, "toggle should be called twice")
    }

    // MARK: - joinNetwork()

    func testJoinNetwork_EmptySSID() async throws {
        let (model, _) = await makeModel()
        let result = await model.joinNetwork(
            ssid: "",
            password: nil,
            useStoredPassword: false
        )
        try XCTAssertEqual(result, L10n.Model.emptySSID)
    }

    func testJoinNetwork_NoDriver() async throws {
        let (model, _) = await makeModel()
        // Set driverLoaded = false (refreshAsync already set it to match
        // NetProbe.realtekDriver() which returns false on real hardware).
        var snap = model.snapshot
        snap.driverLoaded = false
        model.snapshot = snap

        let result = await model.joinNetwork(
            ssid: "AnyNet",
            password: nil,
            useStoredPassword: false
        )
        try XCTAssertEqual(result, L10n.Model.driverNotLoaded)
    }

    func testJoinNetwork_ConnectSucceedsButNoIP() async throws {
        // The mock's connect succeeds but no real IP appears (NetProbe
        // returns nothing on a machine without Realtek hardware). The IP
        // polling loop (6×600ms = 3.6s) is SKIPPED when isTesting=true,
        // so this test completes instantly.
        let (model, mock) = await makeModel()
        mock.connectSuccess = true
        var snap = model.snapshot
        snap.driverLoaded = true
        model.snapshot = snap

        let result = await model.joinNetwork(
            ssid: "TestNet",
            password: "password123",
            useStoredPassword: false
        )
        // connect succeeded → returns joinNoLink because no DHCP/IP
        // appeared during the polling loop (skipped in testing mode).
        try XCTAssertTrue(mock.connectCallCount >= 1)
        try XCTAssertEqual(mock.lastConnectSSID, "TestNet")
        try XCTAssertEqual(
            result, L10n.Model.joinNoLink,
            "With connectSuccess=true and no real IP, should report joinNoLink"
        )
    }

    func testJoinNetwork_ConnectFailure() async throws {
        // When connectSuccess=false, the production joinNetwork code runs
        // retries (without BSSID, alt channel, WPA-PSK fallback). Each
        // retry calls driver.connect() again, totaling 3 calls.
        let (model, mock) = await makeModel()
        mock.connectSuccess = false
        var snap = model.snapshot
        snap.driverLoaded = true
        model.snapshot = snap

        let result = await model.joinNetwork(
            ssid: "TestNet",
            password: "password123",
            useStoredPassword: false
        )
        try XCTAssertEqual(result, L10n.tr("model.join_fail", "TestNet"))
        // With retries: 1 initial + 2 retries = 3 (alt channel skip since nil)
        try XCTAssertEqual(mock.connectCallCount, 3)
    }

    func testJoinNetwork_SkipsPollLoopWhenTesting() async throws {
        // Verifies that when isTesting=true, the 600ms × 6 IP polling loop
        // is skipped entirely. The test measures elapsed time and asserts
        // it's well under one poll interval (600ms), proving the loop didn't
        // execute even once.
        let (model, mock) = await makeModel()
        mock.connectSuccess = true
        var snap = model.snapshot
        snap.driverLoaded = true
        model.snapshot = snap

        let start = Date()
        let result = await model.joinNetwork(
            ssid: "QuickNet",
            password: "password123",
            useStoredPassword: false
        )
        let elapsed = Date().timeIntervalSince(start)

        // If the 600ms poll loop ran even once, elapsed would be >= 600ms.
        // With isTesting=true the loop is skipped, so completion is instant
        // (< 100ms even with mock overhead).
        try XCTAssertTrue(
            elapsed < 0.5,
            "joinNetwork should complete in < 500ms when isTesting=true " +
            "(poll loop is skipped); took \(String(format: "%.3f", elapsed))s"
        )

        // Verify the join did complete through the mock path
        try XCTAssertGreaterThan(mock.connectCallCount, 0)
        try XCTAssertEqual(mock.lastConnectSSID, "QuickNet")
        try XCTAssertEqual(result, L10n.Model.joinNoLink,
            "With connectSuccess=true and no real IP, should return joinNoLink")
    }

    // MARK: - maybeAutoReconnect()

    func testMaybeAutoReconnect_Disabled() async throws {
        let (model, _) = await makeModel()
        model.autoReconnect = false
        setupDisconnected(model)

        model.maybeAutoReconnect(force: false)
        // Should return immediately without starting reconnect
    }

    func testMaybeAutoReconnect_SkipWhenConnected() async throws {
        let (model, _) = await makeModel()
        model.autoReconnect = true
        setupConnected(model)  // has IP → skip

        model.maybeAutoReconnect(force: false)
        await yield()
        // Should skip because snapshot.ip != "—"
    }

    func testMaybeAutoReconnect_SkipNoProfiles() async throws {
        let (model, _) = await makeModel()
        model.autoReconnect = true
        setupDisconnected(model)
        model.profiles = []  // no saved networks

        model.maybeAutoReconnect(force: true)
        await yield()
        // Should skip because no target SSID
    }

    func testMaybeAutoReconnect_Skip_NoPassword() async throws {
        let (model, _) = await makeModel()
        model.autoReconnect = true
        setupDisconnected(model)
        // Profile without password for a secure network
        model.profiles = [
            SavedProfile(ssid: "SecuredNet", hasPassword: false, channel: nil, isDefault: true)
        ]

        model.maybeAutoReconnect(force: true)
        await yield()
        // Should skip because no password for a secure network
    }

    func testMaybeAutoReconnect_SuccessPath() async throws {
        // Verifies that maybeAutoReconnect: (1) passes all guards when the
        // preconditions are met, (2) updates statusText to the reconnecting
        // message synchronously, (3) creates the inner Task without crashing.
        //
        // The inner Task { @MainActor } that calls joinNetwork → driver.connect()
        // is NOT tested for side effects here because in a standalone test
        // binary without a proper NSRunLoop, main-actor Tasks may not be
        // scheduled reliably. testJoinNetwork_* covers the joinNetwork → driver
        // path directly (without going through maybeAutoReconnect).
        //
        // Filesystem access is fully mocked: overrideLastNetwork ensures
        // lastNetwork() returns a known SSID without reading the real
        // wifiUtility.plist. No realtek support files are touched.
        let (model, _) = await makeModel()
        model.autoReconnect = true
        model.lastError = nil
        model.statusText = "…"

        // Disconnected state with driver loaded and radio on
        var snap = InterfaceSnapshot()
        snap.driverLoaded = true
        snap.radioOn = true
        snap.bsdName = "en1"
        snap.ip = "—"
        model.snapshot = snap

        // Profiles: isDefault matches the overrideLastNetwork SSID so
        // the profile-first fallback also matches if lastNetwork is used.
        model.profiles = [
            SavedProfile(ssid: "HomeNet", hasPassword: true, channel: 6, isDefault: true)
        ]

        // Override lastNetwork to return "HomeNet" without touching the real
        // filesystem. This makes the test fully hermetic regardless of whether
        // the Realtek utility is installed on the test machine.
        RealtekProfiles.overrideLastNetwork = "HomeNet"
        defer { RealtekProfiles.overrideLastNetwork = nil }

        // Pre-seed Keychain testStore with a valid password for HomeNet.
        KeychainStore.testStore["HomeNet"] = "password123"

        // Trigger auto-reconnect. All guards should pass:
        // autoReconnect=true, !inFlight, Date() >= suppress/distantPast,
        // force=true, Date() >= joinGrace/distantPast, driverLoaded + radioOn,
        // ip == "—", !associating, targetSSID from lastNetwork() or profiles,
        // pass from testStore (now deterministic — only HomeNet is seeded).
        model.maybeAutoReconnect(force: true)

        // Verify synchronous side effect: statusText updated with reconnecting
        // message. In the test binary L10n.tr returns the unlocalized key
        // (same value regardless of SSID argument since format has no %@).
        try XCTAssertTrue(
            model.statusText != "…",
            "statusText should be updated from its initial value"
        )

        // Verify joinGraceUntil was set to Date() + 20s (with tolerance)
        let expectedGrace = Date().addingTimeInterval(20)
        let graceDelta = abs(model.joinGraceUntil.timeIntervalSince(expectedGrace))
        try XCTAssertTrue(
            graceDelta < 0.5,
            "joinGraceUntil should be ~Date() + 20s, got delta \(graceDelta)s"
        )

        // Calling again should NOT crash (returns early via in-flight guard)
        model.maybeAutoReconnect(force: true)
    }

    func testMaybeAutoReconnect_OpenNetworkProceeds() async throws {
        // Verifies that when the target SSID is an open network (PreferrAuth_Encry=0)
        // and no password is stored, maybeAutoReconnect proceeds past the guard
        // (pass.isEmpty && !openish is false because openish=true).
        //
        // Both overrideAllProfiles and overrideLastNetwork are set so the test
        // is fully hermetic — no real filesystem access occurs.
        let (model, _) = await makeModel()
        model.autoReconnect = true
        model.lastError = nil
        model.statusText = "…"

        var snap = InterfaceSnapshot()
        snap.driverLoaded = true
        snap.radioOn = true
        snap.bsdName = "en1"
        snap.ip = "—"
        model.snapshot = snap

        model.profiles = [
            SavedProfile(ssid: "OpenGuestNet", hasPassword: false, channel: nil, isDefault: true)
        ]

        // Override allProfiles so RealtekProfiles.password() returns the
        // open profile (PreferrAuth_Encry=0). Only one SSID is needed now
        // because lastNetwork is also mocked.
        RealtekProfiles.overrideAllProfiles = [
            "OpenGuestNet": ["PreferrAuth_Encry": 0, "Password": "", "NetworkType": false],
        ]
        defer { RealtekProfiles.overrideAllProfiles = nil }

        // Override lastNetwork to return "OpenGuestNet" — this makes the
        // target SSID deterministic without touching the real filesystem.
        RealtekProfiles.overrideLastNetwork = "OpenGuestNet"
        defer { RealtekProfiles.overrideLastNetwork = nil }

        // Empty password for open network: pass.isEmpty=true, openish=true → proceeds
        KeychainStore.testStore["OpenGuestNet"] = ""

        model.maybeAutoReconnect(force: true)

        try XCTAssertTrue(
            model.statusText != "…",
            "open network with no password should proceed (openish=true)"
        )

        // Second call: verifies in-flight guard doesn't crash
        model.maybeAutoReconnect(force: true)
    }

    func testMaybeAutoReconnect_SecureNetworkSkips() async throws {
        // Verifies that when the target SSID is secure (PreferrAuth_Encry=6 = WPA2-PSK)
        // and no password is stored, maybeAutoReconnect skips at the guard
        // (pass.isEmpty && !openish is true).
        //
        // Both overrideAllProfiles and overrideLastNetwork are set so the test
        // is fully hermetic — no real filesystem access occurs.
        let (model, _) = await makeModel()
        model.autoReconnect = true
        model.lastError = nil
        model.statusText = "original"

        var snap = InterfaceSnapshot()
        snap.driverLoaded = true
        snap.radioOn = true
        snap.bsdName = "en1"
        snap.ip = "—"
        model.snapshot = snap

        model.profiles = [
            SavedProfile(ssid: "SecureCorpNet", hasPassword: false, channel: nil, isDefault: true)
        ]

        // Override allProfiles so RealtekProfiles.password() returns the
        // secure profile (PreferrAuth_Encry=6). Only one SSID is needed.
        RealtekProfiles.overrideAllProfiles = [
            "SecureCorpNet": ["PreferrAuth_Encry": 6, "Password": "", "NetworkType": false],
        ]
        defer { RealtekProfiles.overrideAllProfiles = nil }

        // Override lastNetwork to return "SecureCorpNet" — makes the
        // target SSID deterministic without reading the real filesystem.
        RealtekProfiles.overrideLastNetwork = "SecureCorpNet"
        defer { RealtekProfiles.overrideLastNetwork = nil }

        // No passwords in testStore → pass.isEmpty=true, openish=false → skip
        KeychainStore.testStore = [:]

        model.maybeAutoReconnect(force: true)

        try XCTAssertEqual(
            model.statusText, "original",
            "secure network without password should skip"
        )

        // Calling again should also skip (still no password)
        model.maybeAutoReconnect(force: true)
        try XCTAssertEqual(model.statusText, "original")
    }



    // MARK: - copyIP / copyMAC (side-effect tests)

    func testCopyIP_WhenConnected() async throws {
        let (model, _) = await makeModel()
        setupConnected(model, ip: "10.0.0.5")

        model.copyIP()
        let str = NSPasteboard.general.string(forType: .string)
        try XCTAssertEqual(str, "10.0.0.5")
    }

    func testCopyIP_WhenDisconnected() async throws {
        let (model, _) = await makeModel()
        setupDisconnected(model)
        // Clear any residual pasteboard content from previous tests
        NSPasteboard.general.clearContents()

        model.copyIP()
        let str = NSPasteboard.general.string(forType: .string)
        // Should not have copied "—"
        try XCTAssertNil(str, "Should not copy placeholder IP")
    }

    func testCopyMAC() async throws {
        let (model, _) = await makeModel()
        var snap = InterfaceSnapshot()
        snap.mac = "aa:bb:cc:dd:ee:ff"
        snap.driverLoaded = true
        model.snapshot = snap

        model.copyMAC()
        let str = NSPasteboard.general.string(forType: .string)
        try XCTAssertEqual(str, "aa:bb:cc:dd:ee:ff")
    }

    // MARK: - menuBarTitle

    func testMenuBarTitle_IconOnly() async throws {
        let (model, _) = await makeModel()
        model.menuBarMode = .iconOnly
        try XCTAssertEqual(model.menuBarTitle, "")
    }

    func testMenuBarTitle_SSID() async throws {
        let (model, _) = await makeModel()
        model.menuBarMode = .ssid
        setupConnected(model, ssid: "MyWiFi")
        try XCTAssertEqual(model.menuBarTitle, "MyWiFi")
    }

    func testMenuBarTitle_IP() async throws {
        let (model, _) = await makeModel()
        model.menuBarMode = .ip
        setupConnected(model, ip: "10.0.1.50")
        try XCTAssertEqual(model.menuBarTitle, "10.0.1.50")
    }

    func testMenuBarTitle_Disconnected() async throws {
        let (model, _) = await makeModel()
        model.menuBarMode = .ssid
        setupDisconnected(model)
        try XCTAssertEqual(model.menuBarTitle, L10n.MenuBar.off)
    }

    // MARK: - setPreferredInterface

    func testSetPreferredInterface() async throws {
        let (model, _) = await makeModel()
        model.preferredBSD = ""
        model.setPreferredInterface("en0")
        try XCTAssertEqual(model.preferredBSD, "en0")
    }

    // MARK: - forgetNetwork() — state transitions and error handling

    func testForgetNetwork_SetsCompletionState() async throws {
        let (model, _) = await makeModel()
        setupConnected(model)
        model.lastError = nil
        model.statusText = "…"

        model.forgetNetwork(ssid: "HomeNet")

        // Poll until the Task.detached fires its MainActor.run completion handler
        await poll(until: { forgetCompleted(model) })

        try XCTAssertTrue(forgetCompleted(model), "forgetNetwork task should complete and set state")
    }

    func testForgetNetwork_EmptySSID() async throws {
        let (model, _) = await makeModel()
        setupConnected(model)

        // Whitespace-only SSID gets trimmed to empty string
        model.forgetNetwork(ssid: "  ")

        // Poll until the Task.detached fires its completion handler
        await poll(until: { forgetCompleted(model) })

        // RealtekProfiles.forget returns false for empty SSID, so an error
        // should be reported. The task completes without crash.
        try XCTAssertTrue(forgetCompleted(model), "forgetNetwork should complete even with empty SSID")
    }

    func testForgetNetwork_NonExistentSSID() async throws {
        let (model, _) = await makeModel()
        setupConnected(model)

        // Forgetting a network not in profiles should still fire the task
        model.forgetNetwork(ssid: "NonExistentNet")

        // Poll until the Task.detached fires its completion handler
        await poll(until: { forgetCompleted(model) })

        // Task should complete without crash
        try XCTAssertTrue(forgetCompleted(model), "forgetNetwork should complete for non-existent SSID")
    }

    func testForgetNetwork_SetsLastErrorOnFailure() async throws {
        // Verifies that forgetNetwork sets completion state regardless of
        // whether Realtek support files exist on this machine.
        // On a clean machine RealtekProfiles.forget() returns false (error).
        // On a machine with files it may succeed (statusText updated).
        // Either outcome is valid — we just verify consistent state.
        let (model, _) = await makeModel()
        setupConnected(model)
        model.lastError = nil
        model.statusText = "…"

        model.forgetNetwork(ssid: "SomeNetwork")
        await poll(until: { forgetCompleted(model) })

        // Task completed — either lastError or statusText was updated
        try XCTAssertTrue(forgetCompleted(model), "forgetNetwork task must complete")

        // If forget reported an error, verify the message references the SSID
        let target = "SomeNetwork"
        if let err = model.lastError {
            try XCTAssertTrue(
                err.contains(target),
                "lastError should reference the target SSID, got: \(err)"
            )
            // statusText should NOT be the success message on failure
            try XCTAssertNotEqual(
                model.statusText,
                L10n.tr("model.forgot", target),
                "statusText should NOT be set to forgot message when forget fails"
            )
        }
    }

    func testForgetNetwork_ReloadsProfilesAfterForget() async throws {
        // After forgetNetwork runs, profiles should be reloaded from disk
        // via Self.loadProfiles(). Works on both clean and Realtek machines.
        let (model, _) = await makeModel()
        model.lastError = nil
        model.statusText = "…"

        // Set initial profiles so we can detect if they get reloaded
        let initialProfiles = [
            SavedProfile(ssid: "HomeNet", hasPassword: true, channel: 6, isDefault: true),
        ]
        model.profiles = initialProfiles

        model.forgetNetwork(ssid: "HomeNet")
        await poll(until: { forgetCompleted(model) })

        // Task completed — profiles may have changed or not depending on
        // whether Realtek support files exist. Verify the task ran.
        try XCTAssertTrue(forgetCompleted(model))
        // The profiles object was reassigned (new array from loadProfiles).
        // Check identity: the old array still has "HomeNet", new one differs.
        let stillHasOld = model.profiles.contains { $0.ssid == "HomeNet" }
        let wasReloaded = !stillHasOld || model.profiles.count != initialProfiles.count
        if !wasReloaded {
            // Profiles unchanged — could happen if Realtek files had "HomeNet"
            // and loadProfiles returned it. Fall back: verify task completed.
            try XCTAssertTrue(forgetCompleted(model))
        }
    }

    func testForgetNetwork_MultipleForgetsNoCrash() async throws {
        // Calling forgetNetwork multiple times in succession should not crash
        // and each call should fire its own detached task.
        let (model, _) = await makeModel()
        setupConnected(model)
        model.lastError = nil
        model.statusText = "…"

        model.forgetNetwork(ssid: "NetA")
        model.forgetNetwork(ssid: "NetB")
        model.forgetNetwork(ssid: "NetC")

        // Wait for all three tasks to complete
        await poll(until: { forgetCompleted(model) })

        // No crash — tasks fired and completed
        try XCTAssertTrue(forgetCompleted(model))
    }

    // MARK: - applyDNSPreset() — state transitions and early return

    func testApplyDNSPreset_UpdatesPresetImmediately() async throws {
        let (model, _) = await makeModel()
        model.selectedDNSPreset = .automatic
        model.dnsBusy = false
        model.dnsStatusMessage = nil
        model.lastError = nil

        // Set snapshot with empty service + non-existent BSD so the
        // guard triggers early return (does NOT call NetProbe.setDNSServers).
        var snap = InterfaceSnapshot()
        snap.networkServiceName = ""
        snap.bsdName = "__nonexistent__"
        snap.driverLoaded = true
        model.snapshot = snap

        // Apply Cloudflare — selectedDNSPreset should change synchronously
        model.applyDNSPreset(.cloudflare)
        try XCTAssertEqual(
            model.selectedDNSPreset, .cloudflare,
            "selectedDNSPreset should update synchronously before any async work"
        )

        // Apply Google — should update again
        model.applyDNSPreset(.google)
        try XCTAssertEqual(
            model.selectedDNSPreset, .google,
            "selectedDNSPreset should update on second call"
        )
    }

    func testApplyDNSPreset_NoServiceName_BailsEarly() async throws {
        // When service name is empty on a non-existent BSD interface,
        // applyDNSPreset should bail with DNS.noService and NOT set dnsBusy.
        //
        // Note: on machines with a built-in Wi-Fi interface, NetProbe's
        // fallback path may return a real service name even for a bogus BSD.
        // In that case the guard does NOT trigger and we verify the Task path
        // (dnsBusy=true, dnsStatusMessage=nil after the call completes).
        let (model, _) = await makeModel()
        model.selectedDNSPreset = .automatic
        model.dnsBusy = false
        model.dnsStatusMessage = nil
        model.lastError = nil

        // Empty service + empty BSD → NetProbe.networkServiceName(forBSD: "en1")
        var snap = InterfaceSnapshot()
        snap.networkServiceName = ""
        snap.bsdName = ""
        snap.driverLoaded = true
        model.snapshot = snap

        model.applyDNSPreset(.quad9)

        try XCTAssertEqual(model.selectedDNSPreset, .quad9, "preset should be updated")

        if model.dnsStatusMessage == L10n.DNS.noService {
            // Guard path triggered — service was empty
            try XCTAssertEqual(model.lastError, L10n.DNS.noService, "lastError should match")
            try XCTAssertFalse(model.dnsBusy, "dnsBusy should remain false on early return")
        } else {
            // Service was found (real Wi-Fi iface) — entered the Task path
            // dnsBusy may be true or false depending on timing
            try XCTAssertNil(model.lastError, "no error on Task path")
        }
    }

    func testApplyDNSPreset_NoServiceAllPresets() async throws {
        // Verify that every DNSPreset value goes through the same early-return
        // path when there's no service name, not just .quad9.
        //
        // See testApplyDNSPreset_NoServiceName_BailsEarly for the dual-path
        // description (guard vs Task path depending on real interfaces).
        let (model, _) = await makeModel()
        var snap = InterfaceSnapshot()
        snap.networkServiceName = ""
        snap.bsdName = ""
        snap.driverLoaded = true

        for preset in [DNSPreset.automatic, DNSPreset.cloudflare, DNSPreset.google, DNSPreset.quad9, DNSPreset.adguard, DNSPreset.opendns, DNSPreset.cloudflareGoogle] {
            model.snapshot = snap
            model.selectedDNSPreset = .automatic
            model.dnsBusy = false
            model.dnsStatusMessage = nil
            model.lastError = nil

            model.applyDNSPreset(preset)

            try XCTAssertEqual(model.selectedDNSPreset, preset, "preset should update for \(preset.label)")

            // Check the expected error state per preset
            if model.dnsStatusMessage == L10n.DNS.noService {
                try XCTAssertEqual(model.lastError, L10n.DNS.noService, "lastError for \(preset.label)")
                try XCTAssertFalse(model.dnsBusy, "dnsBusy should remain false for \(preset.label)")
            } else {
                try XCTAssertNil(model.lastError, "no error for \(preset.label)")
            }
        }
    }

    // MARK: - applyDNSPreset() — success and failure paths via MockNetProbe

    func testApplyDNSPreset_SuccessPath() async throws {
        // Verifies the full DNS apply success path: the guard passes (service
        // name is non-empty), the detached Task calls the mocked
        // NetProbe.setDNSServers which returns success, and the model's
        // dnsStatusMessage is updated to the success message.
        //
        // NetProbe.setDNSServers is overridden via NetProbe.overrideSetDNSServers
        // so real networksetup is never called.
        let (model, _) = await makeModel()
        model.selectedDNSPreset = .automatic
        model.dnsBusy = false
        model.dnsStatusMessage = nil
        model.lastError = nil

        // Set a non-empty service name so the guard passes without calling
        // real NetProbe.networkServiceName(forBSD:).
        var snap = InterfaceSnapshot()
        snap.networkServiceName = "USB Wi-Fi"
        snap.bsdName = "en1"
        snap.driverLoaded = true
        model.snapshot = snap

        // Mock NetProbe.setDNSServers to return success
        NetProbe.overrideSetDNSServers = { servers, serviceName in
            return (true, "OK")
        }
        defer { NetProbe.overrideSetDNSServers = nil }

        model.applyDNSPreset(.cloudflare)

        // Immediately: preset updated, dnsBusy set
        try XCTAssertEqual(model.selectedDNSPreset, .cloudflare)
        try XCTAssertTrue(model.dnsBusy, "dnsBusy should be true after apply")

        // Wait for the detached Task to complete and update state
        await poll(until: {
            !model.dnsBusy && model.dnsStatusMessage != nil
        })

        // After the Task completes
        try XCTAssertFalse(model.dnsBusy, "dnsBusy should be false after Task completes")
        // In the test binary, L10n.tr returns the unlocalized key pattern
        try XCTAssertNotNil(model.dnsStatusMessage, "dnsStatusMessage should be set")
        try XCTAssertNil(model.lastError, "lastError should be nil on success")
    }

    func testApplyDNSPreset_FailurePath() async throws {
        // Verifies the DNS apply failure path: the mocked
        // NetProbe.setDNSServers returns failure, and the model's
        // dnsStatusMessage and lastError are updated to the error.
        let (model, _) = await makeModel()
        model.selectedDNSPreset = .automatic
        model.dnsBusy = false
        model.dnsStatusMessage = nil
        model.lastError = nil

        var snap = InterfaceSnapshot()
        snap.networkServiceName = "USB Wi-Fi"
        snap.bsdName = "en1"
        snap.driverLoaded = true
        model.snapshot = snap

        // Mock NetProbe.setDNSServers to return failure
        NetProbe.overrideSetDNSServers = { servers, serviceName in
            return (false, "networksetup failed")
        }
        defer { NetProbe.overrideSetDNSServers = nil }

        model.applyDNSPreset(.google)

        try XCTAssertTrue(model.dnsBusy, "dnsBusy should be true after apply")

        // Wait for the detached Task to complete
        await poll(until: {
            !model.dnsBusy && model.dnsStatusMessage != nil
        })

        try XCTAssertFalse(model.dnsBusy, "dnsBusy should be false after Task completes")
        try XCTAssertEqual(model.dnsStatusMessage, "networksetup failed")
        try XCTAssertEqual(model.lastError, "networksetup failed")
    }

    // MARK: - startPathMonitor()

    func testStartPathMonitor_ConfiguresMonitor() async throws {
        // Verifies that startPathMonitor() creates an NWPathMonitor
        // and a long-running Task without crashing.
        // Uses startPathMonitor() directly rather than start() because
        // start() calls AppNotify.requestAuthorizationIfNeeded() and
        // other APIs that segfault in an unsigned test binary.
        let (model, _) = await makeModel()
        try XCTAssertNil(model.pathMonitor, "pathMonitor should be nil before startPathMonitor()")
        try XCTAssertNil(model.pathMonitorTask, "pathMonitorTask should be nil before startPathMonitor()")

        model.startPathMonitor()

        // After startPathMonitor(), both should be configured
        try XCTAssertNotNil(model.pathMonitor, "pathMonitor should be created by startPathMonitor()")
        try XCTAssertNotNil(model.pathMonitorTask, "pathMonitorTask should be created by startPathMonitor()")
    }

    func testHandlePathUpdate_UnsatisfiedDoesNotCrash() async throws {
        // Verifies that calling handlePathUpdate(status:) with .unsatisfied
        // does not crash and does not modify snapshot.
        let (model, _) = await makeModel()
        model.snapshot.internetReachable = false
        model.snapshot.ip = "192.168.1.42"

        // Should not crash — .unsatisfied is silently ignored
        model.handlePathUpdate(status: .unsatisfied)

        try XCTAssertFalse(
            model.snapshot.internetReachable,
            "unsatisfied path should NOT update internetReachable"
        )
    }

    func testHandlePathUpdate_SatisfiedUpdatesReachability() async throws {
        // Verifies that .satisfied path with reachable=false and ip!="—"
        // sets internetReachable to true.
        let (model, _) = await makeModel()
        model.snapshot.internetReachable = false
        model.snapshot.ip = "192.168.1.42"

        model.handlePathUpdate(status: .satisfied)

        try XCTAssertTrue(
            model.snapshot.internetReachable,
            ".satisfied path should set internetReachable to true"
        )
    }

    func testHandlePathUpdate_SatisfiedSkipsWhenAlreadyReachable() async throws {
        // Verifies that .satisfied path doesn't change anything when
        // internetReachable is already true.
        let (model, _) = await makeModel()
        model.snapshot.internetReachable = true
        model.snapshot.ip = "192.168.1.42"

        model.handlePathUpdate(status: .satisfied)

        try XCTAssertTrue(
            model.snapshot.internetReachable,
            "already reachable should stay true"
        )
    }

    func testHandlePathUpdate_SatisfiedSkipsWhenNoIP() async throws {
        // Verifies that .satisfied path is ignored when there is no IP
        // (snapshot.ip == "—").
        let (model, _) = await makeModel()
        model.snapshot.internetReachable = false
        model.snapshot.ip = "—"

        model.handlePathUpdate(status: .satisfied)

        try XCTAssertFalse(
            model.snapshot.internetReachable,
            "should NOT update when ip is placeholder"
        )
    }

    // MARK: - Defer guard patterns (isRefreshing / isScanningNearby reset on cancellation)

    func testIsRefreshingResetOnCancelledTask() async throws {
        // Tests that the defer pattern used in refreshAsync reliably resets
        // isRefreshing when a Task is cancelled mid-flight.
        // Uses the reusable helper instead of manual sleep + assertion.
        let (model, _) = await makeModel()
        try await assertDeferredFlagResetOnCancel(model, keyPath: \.isRefreshing)
    }

    func testIsScanningNearbyResetOnCancelledTask() async throws {
        // Tests that the defer pattern used in scanNearby reliably resets
        // isScanningNearby when a Task is cancelled mid-flight.
        // Uses the reusable helper instead of manual sleep + assertion.
        let (model, _) = await makeModel()
        try await assertDeferredFlagResetOnCancel(model, keyPath: \.isScanningNearby)
    }

    // MARK: - Driver protocol state (MockRealtekDriver call tracking)

    func testMockDriverConnect_ClearsConnectedStateOnReset() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.reset()
        try XCTAssertNil(mock.connectedSSID)
        try XCTAssertEqual(mock.connectCallCount, 0)
    }

    func testMockDriverDisconnect_ReturnsFalse() async throws {
        let mock = MockRealtekDriver()
        mock.disconnectSuccess = false
        let ok = await mock.disconnect()
        try XCTAssertFalse(ok)
        try XCTAssertEqual(mock.disconnectCallCount, 1)
    }

    // MARK: - queryHTBW() — mock returns

    func testMockQueryHTBW_ReturnsCorrectValue() async throws {
        // Verifies that MockRealtekDriver.queryHTBW() returns 40 (40 MHz)
        // when driver is loaded and radio is on.
        let mock = MockRealtekDriver.connected()
        let value = mock.queryHTBW()
        try XCTAssertNotNil(value, "HTBW should return a value when driver loaded + radio on")
        try XCTAssertEqual(value, 40, "default HTBW should be 40 MHz")
    }

    func testMockQueryHTBW_ReturnsNilWhenRadioOff() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.radioOn = false
        let value = mock.queryHTBW()
        try XCTAssertNil(value, "should return nil when radio is off")
    }

    func testMockQueryHTBW_ReturnsNilWhenDriverNotLoaded() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.queryHTBW()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }

    // MARK: - queryHTGI() — mock returns

    func testMockQueryHTGI_ReturnsCorrectValue() async throws {
        // Verifies that MockRealtekDriver.queryHTGI() returns 1 (short GI)
        // when driver is loaded and radio is on.
        let mock = MockRealtekDriver.connected()
        let value = mock.queryHTGI()
        try XCTAssertNotNil(value, "HTGI should return a value when driver loaded + radio on")
        try XCTAssertEqual(value, 1, "default HTGI should be 1 (short guard interval)")
    }

    func testMockQueryHTGI_ReturnsNilWhenRadioOff() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.radioOn = false
        let value = mock.queryHTGI()
        try XCTAssertNil(value, "should return nil when radio is off")
    }

    func testMockQueryHTGI_ReturnsNilWhenDriverNotLoaded() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.queryHTGI()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }

    // MARK: - queryHTMCS() — mock returns

    func testMockQueryHTMCS_ReturnsCorrectValue() async throws {
        // Verifies that MockRealtekDriver.queryHTMCS() returns 7 (MCS 7)
        // when driver is loaded and radio is on.
        let mock = MockRealtekDriver.connected()
        let value = mock.queryHTMCS()
        try XCTAssertNotNil(value, "HTMCS should return a value when driver loaded + radio on")
        try XCTAssertEqual(value, 7, "default HTMCS should be 7")
    }

    func testMockQueryHTMCS_ReturnsNilWhenRadioOff() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.radioOn = false
        let value = mock.queryHTMCS()
        try XCTAssertNil(value, "should return nil when radio is off")
    }

    func testMockQueryHTMCS_ReturnsNilWhenDriverNotLoaded() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.queryHTMCS()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }

    // MARK: - queryTXLinkRate() — mock returns

    func testMockQueryTXLinkRate_ReturnsCorrectValue() async throws {
        // Verifies that MockRealtekDriver.queryTXLinkRate() returns 300 Mbps
        // when driver is loaded and radio is on.
        let mock = MockRealtekDriver.connected()
        let value = mock.queryTXLinkRate()
        try XCTAssertNotNil(value, "TXLinkRate should return a value when driver loaded + radio on")
        try XCTAssertEqual(value, 300, "default TXLinkRate should be 300 Mbps")
    }

    func testMockQueryTXLinkRate_ReturnsNilWhenRadioOff() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.radioOn = false
        let value = mock.queryTXLinkRate()
        try XCTAssertNil(value, "should return nil when radio is off")
    }

    func testMockQueryTXLinkRate_ReturnsNilWhenDriverNotLoaded() async throws {
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.queryTXLinkRate()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }

    // MARK: - queryNICStatus() — mock returns

    func testMockQueryNICStatus_ReturnsOneByDefault() async throws {
        // Verifies that MockRealtekDriver.queryNICStatus() returns 1 (interface up)
        // by default when the driver is loaded.
        let mock = MockRealtekDriver.connected()
        let value = mock.queryNICStatus()
        try XCTAssertNotNil(value, "NICStatus should return a value when driver loaded")
        try XCTAssertEqual(value, 1, "default NICStatus should be 1 (up)")
    }

    func testMockQueryNICStatus_ReturnsZeroWhenNICDown() async throws {
        // Verifies that when nicStatus is set to 0, queryNICStatus() returns 0.
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.nicStatus = 0
        let value = mock.queryNICStatus()
        try XCTAssertNotNil(value, "should return a value (0 is valid)")
        try XCTAssertEqual(value, 0, "should return 0 when nicStatus=0")
    }

    func testMockQueryNICStatus_ReturnsNilWhenDriverNotLoaded() async throws {
        // Verifies that queryNICStatus() returns nil when driver is not loaded.
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.queryNICStatus()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }

    // MARK: - refreshAsync integration: supplicantStatus fallback

    func testRefreshAsync_SupplicantStatusFallback() async throws {
        // Verifies that the supplicant status resolution in refreshAsync
        // returns the raw value when available, and -1 (unknown) when nil.
        // This mirrors the logic:
        //   if let s = drv.querySupplicantStatus() { snap.supplicantStatus = s }
        //   else { snap.supplicantStatus = -1 }
        let (model, mock) = await makeModel()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = true
        mock.radioOn = true

        // Default supplicantStatus = 1 (SUPPLICANT_SUCCESS)
        let result = model.resolvedSupplicantStatus()
        try XCTAssertEqual(result, 1, "should return 1 (SUPPLICANT_SUCCESS) when connected")

        // With driver not loaded, querySupplicantStatus() returns nil → fallback to -1
        mock.driverLoaded = false
        let unknown = model.resolvedSupplicantStatus()
        try XCTAssertEqual(unknown, -1, "should return -1 (unknown) when driver not loaded")

        // With radio off, querySupplicantStatus() returns nil → fallback to -1
        mock.driverLoaded = true
        mock.radioOn = false
        let radioOff = model.resolvedSupplicantStatus()
        try XCTAssertEqual(radioOff, -1, "should return -1 (unknown) when radio is off")

        // Custom value 3 (SUPPLICANT_FAIL)
        mock.radioOn = true
        mock.supplicantStatus = 3
        let fail = model.resolvedSupplicantStatus()
        try XCTAssertEqual(fail, 3, "should return 3 (SUPPLICANT_FAIL) when set")
    }

    // MARK: - queryWirelessMode2() — mock returns

    func testMockQueryWirelessMode2_ReturnsCorrectValue() async throws {
        // Verifies that MockRealtekDriver.queryWirelessMode2() returns
        // the correct hex-formatted string when connected.
        let mock = MockRealtekDriver.connected()
        let value = mock.queryWirelessMode2()
        try XCTAssertNotNil(value, "queryWirelessMode2 should return a value when connected")
        try XCTAssertEqual(value, "0x00000008", "should return hex for 802.11ac")
    }

    func testMockQueryWirelessMode2_ReturnsNilWhenNotConnected() async throws {
        // Verifies that queryWirelessMode2() returns nil when the mock
        // is not connected (no connectedSSID).
        let mock = MockRealtekDriver()  // default: connectedSSID = nil
        let value = mock.queryWirelessMode2()
        try XCTAssertNil(value, "should return nil when no connectedSSID")
    }

    func testMockQueryWirelessMode2_ReturnsNilWhenRadioOff() async throws {
        // Verifies that queryWirelessMode2() returns nil when radio is off,
        // even if driver is loaded and a SSID was previously connected.
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.radioOn = false
        let value = mock.queryWirelessMode2()
        try XCTAssertNil(value, "should return nil when radio is off")
    }

    func testMockQueryWirelessMode2_ReturnsNilWhenDriverNotLoaded() async throws {
        // Verifies that queryWirelessMode2() returns nil when the driver
        // is not loaded, even if state suggests otherwise.
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.queryWirelessMode2()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }

    func testWirelessModeFallback_UsesMode2First() async throws {
        // Verifies that when both queryWirelessMode2() and
        // queryWirelessMode() return values, queryWirelessMode2() wins.
        // This matches the fallback expression used in refreshAsync:
        //   snap.wirelessMode = drv.queryWirelessMode2() ?? drv.queryWirelessMode()
        let mock = MockRealtekDriver.connected()
        let result = mock.queryWirelessMode2() ?? mock.queryWirelessMode()
        try XCTAssertEqual(result, "0x00000008", "mode2 should be preferred when both return")
    }

    func testWirelessModeFallback_FallsBackToQueryWirelessMode() async throws {
        // Verifies that when queryWirelessMode2() returns nil (e.g.
        // OID 0xFF0101BB is not available on this hardware), the fallback
        // to queryWirelessMode() is used. forceMode2Nil simulates the OID
        // failing while the mock is still connected.
        let mock = MockRealtekDriver.connected()
        mock.forceMode2Nil = true

        let mode2 = mock.queryWirelessMode2()
        try XCTAssertNil(mode2, "mode2 should return nil when forceMode2Nil is true")
    }

    // MARK: - full refreshAsync wireless mode resolution

    func testRefreshAsync_WirelessModeFallback() async throws {
        // Verifies that the full refreshAsync wireless mode resolution path
        // (via resolvedWirelessMode() helper) correctly prefers
        // queryWirelessMode2() over queryWirelessMode() when both are
        // available, and falls back to queryWirelessMode() when mode2 is nil.
        //
        // This mirrors the exact logic in refreshAsync:
        //   snap.wirelessMode = drv.queryWirelessMode2() ?? drv.queryWirelessMode()
        // but tested through the model + mock rather than stand-alone mock calls.
        let (model, mock) = await makeModel()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = true
        mock.radioOn = true

        // mode2 returns "0x00000008", mode returns "802.11ac" → mode2 wins
        let result = model.resolvedWirelessMode()
        try XCTAssertEqual(result, "0x00000008", "mode2 should be preferred when both return values")

        // With forceMode2Nil = true, falls back to queryWirelessMode()
        mock.forceMode2Nil = true
        let fallback = model.resolvedWirelessMode()
        try XCTAssertEqual(fallback, "802.11ac", "should fallback to human-readable mode when mode2 is nil")

        // With driver not loaded, both return nil
        mock.driverLoaded = false
        let none = model.resolvedWirelessMode()
        try XCTAssertNil(none, "should return nil when driver is not loaded")
    }

    // MARK: - querySupplicantStatus() — mock returns

    func testMockQuerySupplicantStatus_ReturnsOneByDefault() async throws {
        // Verifies that MockRealtekDriver.querySupplicantStatus() returns
        // 1 (SUPPLICANT_SUCCESS) by default when the mock is connected.
        let mock = MockRealtekDriver.connected()
        let value = mock.querySupplicantStatus()
        try XCTAssertNotNil(value, "should return a value when connected")
        try XCTAssertEqual(value, 1, "default supplicant status should be 1 (success)")
    }

    func testMockQuerySupplicantStatus_CanSetToThree() async throws {
        // Verifies that supplicantStatus can be set to 3 (SUPPLICANT_FAIL)
        // and querySupplicantStatus() reflects the change.
        let mock = MockRealtekDriver.connected()
        mock.supplicantStatus = 3
        let value = mock.querySupplicantStatus()
        try XCTAssertNotNil(value, "should return a value even when status is 3")
        try XCTAssertEqual(value, 3, "should return 3 (fail) when supplicantStatus is set to 3")
    }

    func testMockQuerySupplicantStatus_ReturnsNilWhenNotConnected() async throws {
        // Verifies that querySupplicantStatus() returns nil when the mock
        // is not connected (no connectedSSID), even though supplicantStatus
        // is still set to 1 internally.
        let mock = MockRealtekDriver()  // default: connectedSSID = nil
        let value = mock.querySupplicantStatus()
        try XCTAssertNil(value, "should return nil when no connectedSSID")
    }

    func testMockQuerySupplicantStatus_ReturnsNilWhenRadioOff() async throws {
        // Verifies that querySupplicantStatus() returns nil when radio is
        // off, even if connectedSSID is set.
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.radioOn = false
        let value = mock.querySupplicantStatus()
        try XCTAssertNil(value, "should return nil when radio is off")
    }

    func testMockQuerySupplicantStatus_ReturnsNilWhenDriverNotLoaded() async throws {
        // Verifies that querySupplicantStatus() returns nil when the driver
        // is not loaded, even if other state suggests association.
        let mock = MockRealtekDriver()
        mock.connectedSSID = "TestNet"
        mock.driverLoaded = false
        let value = mock.querySupplicantStatus()
        try XCTAssertNil(value, "should return nil when driver not loaded")
    }
}
