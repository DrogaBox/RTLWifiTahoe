// NOTE: This file intentionally avoids `import SwiftUI` at the top so it
// compiles in test targets that don't link SwiftUI. The Animation extension
// at the bottom is conditionally compiled via `#if canImport(SwiftUI)`.

// MARK: - Duration helpers

// MARK: - Duration constants for UI delays

extension Duration {
    /// Brief pause before focusing the password field in the join form (150 ms).
    /// Lets the form animation settle before the keyboard / focus ring appears.
    static let joinFocusDelay: Duration = .milliseconds(150)

    /// Wait after a successful join before refreshing and dismissing (800 ms).
    /// Gives the user a moment to see the success message before the panel closes.
    static let joinDismissDelay: Duration = .milliseconds(800)
}

// MARK: - Scan / driver polling delays

extension Duration {
    /// Interval between OID progress queries while waiting for a scan to finish (250 ms).
    /// Used in `scanNetworks()` loop and `waitScanIdle()`.
    static let scanPoll: Duration = .milliseconds(250)

    /// Interval between OID progress queries before starting a connect (200 ms).
    /// `waitScanIdle()` polls the kext until scan-in-progress returns 0.
    static let scanIdlePoll: Duration = .milliseconds(200)

    /// Total timeout for a scan to complete (5 s).
    /// After this, `scanNetworks()` proceeds even if scan hasn't finished.
    static let scanTimeout: Duration = .seconds(5)

    /// Maximum time to spend enumerating BSS entries (8 s).
    static let scanMaxEnumTime: Duration = .seconds(8)

    /// Max iterations of the scan-progress polling loop.
    static let scanPollMaxRetries: Int = 30

    /// Max BSS entries to iterate (cap to avoid pathological 512-entry loops).
    static let scanMaxBSS: UInt32 = 128

    /// Fallback BSS count when the OID query returns zero.
    static let scanDefaultBSS: UInt32 = 64

    /// Interval between link-status polls after starting a connect (600 ms).
    /// Pokes OID / ifconfig to detect PHY link-up.
    static let connectPoll: Duration = .milliseconds(600)

    /// Number of link-status polls after connect before giving up.
    static let connectPollRetries: Int = 10

    /// Maximum time to wait for scan to become idle before starting a connect (5 s).
    static let connectIdleTimeout: Duration = .seconds(5)
}

// MARK: - Disconnect / radio delays

extension Duration {
    /// Pause after sending OID_802_11_DISASSOCIATE in `disconnect()` (250 ms).
    static let disconnectSettle: Duration = .milliseconds(250)

    /// Pause after disassociate step in the connect path before setting infra mode (350 ms).
    static let postDisassociate: Duration = .milliseconds(350)

    /// Pause after toggling RF state via `setRadioOn()` before re-checking (200 ms).
    static let radioSettle: Duration = .milliseconds(200)
}

// MARK: - WPS polling delays

extension Duration {
    /// Interval between hardware WPS button flag polls (2 s).
    /// During PBC, checks OID 0xFF819029 for non-zero every 2s, up to ~20s.
    static let wpsPoll: Duration = .seconds(2)

    /// Max iterations of the WPS hardware flag polling loop.
    static let wpsPollMaxRetries: Int = 10
}

// MARK: - Wake / reconnection delays

extension Duration {
    /// Delay after system wake before attempting auto-reconnect (3 s).
    /// Gives the USB radio / kext time to settle before polling link state.
    static let wakeRefreshDelay: Duration = .seconds(3)
}

// MARK: - Animation constants (SwiftUI only)

#if canImport(SwiftUI)
import SwiftUI

extension Animation {
    /// Ease-out for overlay transitions (showJoin, password form toggles).
    static let overlayTransition: Animation = .easeOut(duration: 0.15)

    /// Ease-out for collapsible section expansion (theme list, behavior list).
    static let sectionExpand: Animation = .easeOut(duration: 0.18)

    /// Ease-out for panel resize, theme switches, and general structural changes.
    static let panelResize: Animation = .easeOut(duration: 0.2)

    /// Ease-out for signal-level meter updates (smooth bar changes).
    static let signalUpdate: Animation = .easeOut(duration: 0.25)
}
#endif
