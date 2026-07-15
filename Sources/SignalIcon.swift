import SwiftUI
import AppKit

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
    /// Channel bandwidth 20/40/80/160 MHz (0 = unknown)
    var channelWidthMHz: Int = 0
    /// Guard interval: true = short (400ns), nil = unknown
    var giShort: Bool? = nil
    /// MCS index 0–31, nil = unknown
    var mcsIndex: Int? = nil

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
            var chStr = "Ch \(channel)"
            if channelWidthMHz >= 40 {
                chStr += " · \(channelWidthMHz)MHz"
            }
            parts.append(chStr)
        }
        if let gi = giShort {
            parts.append(gi ? "Short GI" : "Long GI")
        }
        if let mcs = mcsIndex {
            parts.append("MCS \(mcs)")
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
