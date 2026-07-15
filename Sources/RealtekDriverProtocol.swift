import Foundation

// MARK: - RealtekDriverProtocol

/// Abstracts the low-level Realtek RtWlanU kext driver so the rest of the app
/// can be tested without hardware, and SwiftUI previews can show real UI state
/// without a physical USB Wi‑Fi adapter.
protocol RealtekDriverProtocol: AnyObject {
    /// BSD name (e.g. "en1") the driver should target for ifconfig / OID lookups.
    var currentBSD: String { get set }

    /// Open the IOKit user client connection to the RtWlanU kext. No‑op if already open.
    @discardableResult
    func open() -> Bool

    /// Live signal quality 0…100 from OID 0x0D010206. `nil` if not associated or query failed.
    func querySignalPercent() -> Int?

    /// Current RF channel from kext (1…196). 0 if unknown.
    func queryAssociatedChannel() -> Int

    /// Currently associated SSID via OID 0xFF070102. `nil` if not associated.
    func currentSSID() -> String?

    /// Full scan: start scan, wait, enumerate BSS list via GetNetworkAtIndex.
    func scanNetworks() async -> [ScannedNetwork]

    /// Associate using the RtWlanU kext OID sequence.
    @discardableResult
    func connect(
        ssid: String,
        password: String,
        preferWPA2: Bool,
        channel: UInt32?,
        bssid: String?,
        options: JoinOptions?
    ) async -> Bool

    /// Hardware WPS PBC flag via OID 0xFF819029. `true` when button has been pressed on the adapter.
    func wpsHardwarePBCPressed() -> Bool

    /// Disassociate from the current BSS. Does not turn RF off.
    @discardableResult
    func disconnect() async -> Bool

    /// Log current IOKit/ifconfig link state snapshot (diagnostics, no password).
    func logLinkSnapshot(tag: String)

    /// Set USB Wi‑Fi radio on (`true`) or off (`false`). Syncs soft‑state file + ifconfig.
    @discardableResult
    func setRadioOn(_ on: Bool, bsd: String?) async -> Bool

    /// Query RF off flag. `true` = radio off, `false` = on, `nil` = query failed.
    func isRadioOff() -> Bool?
}
