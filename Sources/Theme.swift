import SwiftUI
import AppKit

// MARK: - Theme IDs

enum AppThemeID: String, CaseIterable, Identifiable {
    case powerGadget = "power"
    case classic = "classic"
    case midnight = "midnight"
    case ember = "ember"
    case matrix = "matrix"
    case rose = "rose"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .powerGadget: return L10n.Theme.powerGadget
        case .classic: return L10n.Theme.classic
        case .midnight: return L10n.Theme.midnight
        case .ember: return L10n.Theme.ember
        case .matrix: return L10n.Theme.matrix
        case .rose: return L10n.Theme.rose
        }
    }

    var subtitle: String {
        switch self {
        case .powerGadget: return L10n.Theme.powerGadgetSub
        case .classic: return L10n.Theme.classicSub
        case .midnight: return L10n.Theme.midnightSub
        case .ember: return L10n.Theme.emberSub
        case .matrix: return L10n.Theme.matrixSub
        case .rose: return L10n.Theme.roseSub
        }
    }

    /// Preview dots for the theme picker
    var swatches: [Color] {
        let p = palette
        return [p.accentCyan, p.accentPurple, p.accentGreen, p.accentOrange]
    }

    var palette: ThemePalette {
        switch self {
        case .powerGadget:
            // Matched to AMD Power Gadget UI (rings: cyan/purple/pink/green, dark glass)
            return ThemePalette(
                background: Color(red: 0.08, green: 0.08, blue: 0.10),
                card: Color(red: 0.13, green: 0.13, blue: 0.16),
                cardElevated: Color(red: 0.17, green: 0.17, blue: 0.21),
                cardBorder: Color.white.opacity(0.12),
                accentCyan: Color(red: 0.20, green: 0.88, blue: 0.98),      // CPU ring
                accentOrange: Color(red: 1.00, green: 0.42, blue: 0.38),    // temp graph
                accentGreen: Color(red: 0.25, green: 0.92, blue: 0.48),     // network / disk
                accentPurple: Color(red: 0.72, green: 0.48, blue: 1.00),    // RAM / VRAM
                accentRed: Color(red: 0.95, green: 0.28, blue: 0.32),       // Salir
                accentYellow: Color(red: 1.0, green: 0.78, blue: 0.30),
                text: Color.white.opacity(0.95),
                subtext: Color.white.opacity(0.55),
                glassOpacity: 0.55,
                baseOpacity: 0.88,
                cornerRadius: 16,
                topSheen: 0.08
            )
        case .classic:
            return ThemePalette(
                background: Color(red: 0.07, green: 0.08, blue: 0.11),
                card: Color(red: 0.12, green: 0.14, blue: 0.19),
                cardElevated: Color(red: 0.15, green: 0.17, blue: 0.23),
                cardBorder: Color.white.opacity(0.10),
                accentCyan: Color(red: 0.0, green: 0.85, blue: 0.95),
                accentOrange: Color(red: 1.0, green: 0.55, blue: 0.10),
                accentGreen: Color(red: 0.10, green: 0.95, blue: 0.45),
                accentPurple: Color(red: 0.65, green: 0.40, blue: 1.0),
                accentRed: Color(red: 1.0, green: 0.32, blue: 0.32),
                accentYellow: Color(red: 1.0, green: 0.82, blue: 0.25),
                text: Color.white.opacity(0.94),
                subtext: Color.white.opacity(0.52),
                glassOpacity: 0.72,
                baseOpacity: 0.94,
                cornerRadius: 14,
                topSheen: 0.06
            )
        case .midnight:
            return ThemePalette(
                background: Color(red: 0.04, green: 0.06, blue: 0.14),
                card: Color(red: 0.08, green: 0.11, blue: 0.22),
                cardElevated: Color(red: 0.11, green: 0.15, blue: 0.28),
                cardBorder: Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.25),
                accentCyan: Color(red: 0.35, green: 0.65, blue: 1.0),
                accentOrange: Color(red: 1.0, green: 0.65, blue: 0.25),
                accentGreen: Color(red: 0.30, green: 0.95, blue: 0.75),
                accentPurple: Color(red: 0.55, green: 0.45, blue: 1.0),
                accentRed: Color(red: 1.0, green: 0.40, blue: 0.50),
                accentYellow: Color(red: 0.95, green: 0.85, blue: 0.40),
                text: Color.white.opacity(0.95),
                subtext: Color.white.opacity(0.50),
                glassOpacity: 0.65,
                baseOpacity: 0.92,
                cornerRadius: 14,
                topSheen: 0.07
            )
        case .ember:
            return ThemePalette(
                background: Color(red: 0.10, green: 0.06, blue: 0.05),
                card: Color(red: 0.18, green: 0.11, blue: 0.09),
                cardElevated: Color(red: 0.22, green: 0.14, blue: 0.11),
                cardBorder: Color(red: 1.0, green: 0.45, blue: 0.20).opacity(0.22),
                accentCyan: Color(red: 1.0, green: 0.72, blue: 0.35),
                accentOrange: Color(red: 1.0, green: 0.48, blue: 0.12),
                accentGreen: Color(red: 0.85, green: 0.90, blue: 0.35),
                accentPurple: Color(red: 1.0, green: 0.40, blue: 0.55),
                accentRed: Color(red: 1.0, green: 0.28, blue: 0.22),
                accentYellow: Color(red: 1.0, green: 0.85, blue: 0.30),
                text: Color(red: 1.0, green: 0.96, blue: 0.92),
                subtext: Color.white.opacity(0.52),
                glassOpacity: 0.50,
                baseOpacity: 0.93,
                cornerRadius: 14,
                topSheen: 0.05
            )
        case .matrix:
            return ThemePalette(
                background: Color(red: 0.02, green: 0.05, blue: 0.03),
                card: Color(red: 0.05, green: 0.10, blue: 0.07),
                cardElevated: Color(red: 0.07, green: 0.14, blue: 0.09),
                cardBorder: Color(red: 0.20, green: 0.90, blue: 0.40).opacity(0.22),
                accentCyan: Color(red: 0.25, green: 1.0, blue: 0.55),
                accentOrange: Color(red: 0.70, green: 0.95, blue: 0.30),
                accentGreen: Color(red: 0.15, green: 0.98, blue: 0.40),
                accentPurple: Color(red: 0.40, green: 0.85, blue: 0.65),
                accentRed: Color(red: 1.0, green: 0.35, blue: 0.35),
                accentYellow: Color(red: 0.75, green: 1.0, blue: 0.35),
                text: Color(red: 0.85, green: 1.0, blue: 0.90),
                subtext: Color(red: 0.45, green: 0.75, blue: 0.55),
                glassOpacity: 0.40,
                baseOpacity: 0.95,
                cornerRadius: 12,
                topSheen: 0.04
            )
        case .rose:
            return ThemePalette(
                background: Color(red: 0.09, green: 0.05, blue: 0.10),
                card: Color(red: 0.16, green: 0.10, blue: 0.18),
                cardElevated: Color(red: 0.20, green: 0.13, blue: 0.23),
                cardBorder: Color(red: 1.0, green: 0.45, blue: 0.75).opacity(0.22),
                accentCyan: Color(red: 1.0, green: 0.55, blue: 0.80),
                accentOrange: Color(red: 1.0, green: 0.50, blue: 0.45),
                accentGreen: Color(red: 0.55, green: 0.95, blue: 0.70),
                accentPurple: Color(red: 0.85, green: 0.40, blue: 1.0),
                accentRed: Color(red: 1.0, green: 0.30, blue: 0.45),
                accentYellow: Color(red: 1.0, green: 0.80, blue: 0.50),
                text: Color.white.opacity(0.95),
                subtext: Color.white.opacity(0.52),
                glassOpacity: 0.60,
                baseOpacity: 0.92,
                cornerRadius: 15,
                topSheen: 0.07
            )
        }
    }
}

struct ThemePalette {
    var background: Color
    var card: Color
    var cardElevated: Color
    var cardBorder: Color
    var accentCyan: Color
    var accentOrange: Color
    var accentGreen: Color
    var accentPurple: Color
    var accentRed: Color
    var accentYellow: Color
    var text: Color
    var subtext: Color
    var glassOpacity: Double
    var baseOpacity: Double
    var cornerRadius: CGFloat
    var topSheen: Double
}

// MARK: - Theme store (persisted, live switch)

/// Theme store — not MainActor-isolated so Tahoe.* statics can read it from any context.
final class ThemeStore: ObservableObject {
    static var shared = ThemeStore()

    @Published var themeID: AppThemeID {
        didSet {
            UserDefaults.standard.set(themeID.rawValue, forKey: "app_theme")
        }
    }

    var palette: ThemePalette { themeID.palette }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "app_theme") ?? AppThemeID.powerGadget.rawValue
        themeID = AppThemeID(rawValue: raw) ?? .powerGadget
    }
}

// MARK: - Tahoe accessors (always follow active theme)
// Live refresh: root PopoverView uses .id(ThemeStore.shared.themeID).

enum Tahoe {
    private static var p: ThemePalette { ThemeStore.shared.palette }

    static var background: Color { p.background }
    static var card: Color { p.card }
    static var cardElevated: Color { p.cardElevated }
    static var cardBorder: Color { p.cardBorder }
    static var accentCyan: Color { p.accentCyan }
    static var accentOrange: Color { p.accentOrange }
    static var accentGreen: Color { p.accentGreen }
    static var accentPurple: Color { p.accentPurple }
    static var accentRed: Color { p.accentRed }
    static var accentYellow: Color { p.accentYellow }
    static var text: Color { p.text }
    static var subtext: Color { p.subtext }
    static var cornerRadius: CGFloat { p.cornerRadius }
}

// MARK: - Glass / panel chrome

/// Solid dark shell + light material edge (not washed-out ultraThin).
struct GlassBackground: NSViewRepresentable {
    var cornerRadius: CGFloat = 14

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        v.isEmphasized = true
        v.wantsLayer = true
        v.layer?.cornerRadius = cornerRadius
        v.layer?.masksToBounds = true
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.state = .active
        nsView.layer?.cornerRadius = cornerRadius
    }
}

struct PanelBackground: View {
    @ObservedObject private var themes = ThemeStore.shared

    var body: some View {
        let p = themes.palette
        let r = p.cornerRadius
        return ZStack {
            RoundedRectangle(cornerRadius: r)
                .fill(p.background.opacity(p.baseOpacity))
            GlassBackground(cornerRadius: r)
                .clipShape(RoundedRectangle(cornerRadius: r))
                .opacity(p.glassOpacity)
            RoundedRectangle(cornerRadius: r)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(p.topSheen), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            RoundedRectangle(cornerRadius: r)
                .stroke(p.cardBorder, lineWidth: 1)
        }
        .id(themes.themeID)
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var accent: Color = Tahoe.accentCyan

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Tahoe.subtext)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Tahoe.cardElevated)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
        )
    }
}

/// Compact 2-column key/value row (no heavy pills)
struct InfoRow: View {
    let leftTitle: String
    let leftValue: String
    let leftAccent: Color
    let rightTitle: String
    let rightValue: String
    let rightAccent: Color
    var monospacedValues: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            cell(leftTitle, leftValue, leftAccent)
            cell(rightTitle, rightValue, rightAccent)
        }
    }

    private func cell(_ t: String, _ v: String, _ a: Color) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(t)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Tahoe.subtext)
                Text(v)
                    .font(.system(size: 12, weight: .semibold, design: monospacedValues ? .monospaced : .rounded))
                    .foregroundColor(a)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Tahoe.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
        )
    }
}

struct TahoeToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Tahoe.text)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(Tahoe.subtext)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Tahoe.accentCyan))
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Theme picker chips (Settings tab)

struct ThemePickerView: View {
    @ObservedObject var themes: ThemeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(AppThemeID.allCases) { id in
                let on = themes.themeID == id
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        themes.themeID = id
                    }
                } label: {
                    HStack(spacing: 10) {
                        // Swatch row
                        HStack(spacing: 3) {
                            ForEach(0..<id.swatches.count, id: \.self) { i in
                                Circle()
                                    .fill(id.swatches[i])
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(5)
                        .background(
                            Capsule().fill(Color.black.opacity(0.25))
                        )

                        VStack(alignment: .leading, spacing: 1) {
                            Text(id.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Tahoe.text)
                            Text(id.subtitle)
                                .font(.system(size: 9))
                                .foregroundColor(Tahoe.subtext)
                        }
                        Spacer(minLength: 4)
                        if on {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Tahoe.accentCyan)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(on ? Tahoe.cardElevated : Tahoe.card.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(on ? Tahoe.accentCyan.opacity(0.55) : Tahoe.cardBorder, lineWidth: on ? 1.5 : 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
