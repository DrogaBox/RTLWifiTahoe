import SwiftUI

// MARK: - Signal level (0…4)

enum SignalLevel: Int, CaseIterable, Comparable {
    case none = 0
    case weak = 1
    case fair = 2
    case good = 3
    case excellent = 4

    static func < (lhs: SignalLevel, rhs: SignalLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Map signal quality + association → bars.
    /// Prefer live **signalPercent** (OID 0x0D010206, 0…100) when available;
    /// fall back to IOLinkSpeed only if percent is missing.
    static func from(
        signalPercent: Int?,
        linkSpeedBps: UInt64,
        hasIP: Bool,
        associating: Bool
    ) -> SignalLevel {
        if let p = signalPercent, p > 0 {
            switch p {
            case 75...: return .excellent
            case 55..<75: return .good
            case 35..<55: return .fair
            case 1..<35: return .weak
            default: break
            }
        }
        if hasIP {
            switch linkSpeedBps {
            case 500_000_000...: return .excellent
            case 150_000_000...: return .good
            case 50_000_000...:  return .fair
            case 1...:           return .weak
            default:             return .fair  // has IP but speed not reported yet
            }
        }
        if associating { return .weak }
        return .none
    }

    /// 0…4 bars from 0…100 percent (scan list style).
    static func fromPercent(_ p: Int) -> SignalLevel {
        switch p {
        case 75...: return .excellent
        case 55..<75: return .good
        case 35..<55: return .fair
        case 1..<35: return .weak
        default: return .none
        }
    }

    var label: String {
        switch self {
        case .none: return L10n.Signal.none
        case .weak: return L10n.Signal.weak
        case .fair: return L10n.Signal.fair
        case .good: return L10n.Signal.good
        case .excellent: return L10n.Signal.excellent
        }
    }

    /// Prefer "Linking" when we are associating without an IP.
    func statusLabel(associating: Bool, hasIP: Bool) -> String {
        if associating && !hasIP { return L10n.Signal.linking }
        return label
    }

    var color: Color {
        switch self {
        case .none: return .red
        case .weak: return .orange
        case .fair: return .yellow
        case .good: return .cyan
        case .excellent: return .green
        }
    }

    /// SF Symbol always visible in MenuBarExtra (Canvas is unreliable there).
    var menuBarSymbol: String {
        switch self {
        case .none: return "wifi.slash"
        case .weak: return "wifi.exclamationmark"
        case .fair, .good, .excellent: return "wifi"
        }
    }
}
