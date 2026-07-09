import SwiftUI
import AppKit

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
        case .none: return Tahoe.accentRed
        case .weak: return Tahoe.accentOrange
        case .fair: return Tahoe.accentYellow
        case .good: return Tahoe.accentCyan
        case .excellent: return Tahoe.accentGreen
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

// MARK: - Menu bar: SF Symbol + optional bars overlay (template-safe)

/// Reliable menu-bar glyph. Uses SF Symbol (always shows) + tiny strength dots.
struct SignalBarsIcon: View {
    let level: SignalLevel
    var size: CGFloat = 16

    var body: some View {
        // Primary: SF Symbol — MenuBarExtra renders these correctly as template images
        Image(systemName: level.menuBarSymbol)
            .font(.system(size: size * 0.95, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .imageScale(.medium)
            // Accessibility / strength cue via overlay dots under the icon
            .overlay(alignment: .bottom) {
                if level != .none {
                    HStack(spacing: 1.5) {
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .fill(i < level.rawValue ? Color.primary : Color.primary.opacity(0.25))
                                .frame(width: 2.2, height: 2.2)
                        }
                    }
                    .offset(y: 5)
                }
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityLabel(Text(level.label))
    }
}

/// NSImage template bars — used if we need AppKit status item fallback.
enum SignalMenuImage {
    static func template(level: SignalLevel, pointSize: CGFloat = 18) -> NSImage {
        if level == .none {
            let img = NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No Wi‑Fi")!
            img.isTemplate = true
            return img
        }
        let img = NSImage(systemSymbolName: "wifi", accessibilityDescription: level.label)!
        img.isTemplate = true
        // Strength encoded only via tooltip; SF Symbol stays crisp in menu bar
        return img
    }
}

// MARK: - Status panel meter (full color OK inside popover window)

struct SignalMeter: View {
    let level: SignalLevel
    let linkMbps: Double
    var hasIP: Bool = false
    var associating: Bool = false
    /// Live quality 0…100 from kext (nil = unknown)
    var signalPercent: Int? = nil
    /// Associated RF channel if known
    var channel: Int = 0

    private var title: String {
        level.statusLabel(associating: associating, hasIP: hasIP)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let p = signalPercent, p > 0 {
            parts.append("\(p)%")
        }
        if hasIP {
            if linkMbps > 0 {
                parts.append(String(format: "%.0f Mbps", linkMbps))
            } else if parts.isEmpty {
                parts.append(L10n.Signal.connected)
            }
        } else if associating {
            parts.append(L10n.Signal.associating)
        } else if parts.isEmpty {
            parts.append(L10n.Signal.disconnected)
        }
        if channel > 0 {
            parts.append("Ch \(channel)")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < level.rawValue ? level.color : Color.white.opacity(0.14))
                        .frame(width: 7, height: 10 + CGFloat(i) * 4)
                }
            }
            .frame(width: 36, height: 26, alignment: .bottom)
            .animation(.easeOut(duration: 0.25), value: level)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(level.color)
                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Tahoe.subtext)
            }

            Spacer(minLength: 4)

            if let p = signalPercent, p > 0 {
                Text("\(p)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(level.color)
            } else {
                Image(systemName: level.menuBarSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(level.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Tahoe.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.cardBorder, lineWidth: 1))
        )
    }
}
