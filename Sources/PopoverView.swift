import SwiftUI
import AppKit

/// Width fixed; height grows down with content (capped to screen).
enum PanelSize {
    static let width: CGFloat = 340
    static let minHeight: CGFloat = 360
    /// Legacy alias for callers that still reference a single height.
    static var height: CGFloat { minHeight }

    /// Max popover height under the menu bar (grows downward).
    static var maxHeight: CGFloat {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return 720 }
        // visibleFrame excludes menu bar / dock — leave a little air
        return max(minHeight, screen.visibleFrame.height - 36)
    }
}

extension Notification.Name {
    /// userInfo["size"] = NSSize — AppDelegate resizes NSPopover
    static let rtlPopoverNeedsSize = Notification.Name("com.drogabox.rtlwifitahoe.popoverSize")
}

/// Reports ideal content height so the popover can grow/shrink.
private struct IdealHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct PopoverView: View {
    @ObservedObject var model: WiFiModel
    @ObservedObject private var themes = ThemeStore.shared
    @State private var tab: Int = 0
    @State private var showJoin = false
    /// True content height from unconstrained layout pass.
    @State private var contentHeight: CGFloat = PanelSize.minHeight

    private var panelHeight: CGFloat {
        // Join overlay needs a usable minimum; otherwise fit content and cap to screen
        let base: CGFloat = showJoin
            ? max(contentHeight, min(560, PanelSize.maxHeight))
            : contentHeight
        return min(max(base, PanelSize.minHeight), PanelSize.maxHeight)
    }

    private var needsScroll: Bool {
        !showJoin && contentHeight > PanelSize.maxHeight + 1
    }

    var body: some View {
        ZStack(alignment: .top) {
            PanelBackground()

            Group {
                if needsScroll {
                    ScrollView(.vertical, showsIndicators: true) {
                        panelBody
                            // Keep measuring ideal height even while scrolling
                            .background(heightReader)
                    }
                } else {
                    panelBody
                        .background(heightReader)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if showJoin {
                JoinPanel(model: model)
                    .transition(.opacity)
            }
        }
        // Width fixed; height = content (grows down), capped to screen
        .frame(width: PanelSize.width, height: panelHeight, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: themes.palette.cornerRadius))
        .preferredColorScheme(.dark)
        // Rebuild chrome when theme changes so all Tahoe.* colors refresh
        .id(themes.themeID)
        .animation(.easeOut(duration: 0.2), value: panelHeight)
        .animation(.easeOut(duration: 0.15), value: showJoin)
        .animation(.easeOut(duration: 0.2), value: themes.themeID)
        .onPreferenceChange(IdealHeightKey.self) { h in
            guard h > 40 else { return }
            if abs(h - contentHeight) > 2 {
                contentHeight = h
                publishSize(height: panelHeightFor(content: h))
            }
        }
        .onChange(of: tab) { _ in
            // Content swap — size updates via preference after layout
        }
        .onChange(of: model.nearbyNetworks.count) { _ in
            // List grew/shrunk — preference will re-fire after layout
        }
        .onChange(of: showJoin) { _ in
            publishSize(height: panelHeight)
        }
        .onPreferenceChange(JoinDismissKey.self) { if $0 { showJoin = false } }
        .environment(\.joinDismiss) {
            showJoin = false
        }
        .onAppear {
            publishSize(height: panelHeight)
        }
    }

    /// Reads the *ideal* height of the body. Uses fixedSize so parent frame
    /// does not clamp the measurement (avoids the fixed-size feedback loop).
    private var heightReader: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: IdealHeightKey.self, value: geo.size.height)
        }
    }

    private var panelBody: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Picker("", selection: $tab) {
                Text(L10n.Tab.status).tag(0)
                Text(L10n.Tab.profiles).tag(1)
                Text(L10n.Tab.settings).tag(2)
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Group {
                switch tab {
                case 0: StatusTab(model: model, showJoin: $showJoin)
                case 1: ProfilesTab(model: model, showJoin: $showJoin)
                default: SettingsTab(model: model)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        // Critical: size to content, not to the outer popover frame
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: PanelSize.width, alignment: .top)
    }

    private func panelHeightFor(content h: CGFloat) -> CGFloat {
        let base: CGFloat = showJoin
            ? max(h, min(560, PanelSize.maxHeight))
            : h
        return min(max(base, PanelSize.minHeight), PanelSize.maxHeight)
    }

    private func publishSize(height: CGFloat) {
        let size = NSSize(width: PanelSize.width, height: height)
        NotificationCenter.default.post(
            name: .rtlPopoverNeedsSize,
            object: nil,
            userInfo: ["size": size]
        )
    }

    private var header: some View {
        let hasIP = model.snapshot.ip != "—"
        let associating = model.snapshot.associating
        let headerColor: Color = hasIP ? Tahoe.accentGreen : (associating ? Tahoe.accentOrange : Tahoe.accentRed)
        let headerIcon = hasIP ? "wifi" : (associating ? "wifi.exclamationmark" : "wifi.slash")
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(headerColor.opacity(0.22))
                    .frame(width: 30, height: 30)
                Image(systemName: headerIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(headerColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.App.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Tahoe.text)
                Text(model.statusText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Tahoe.subtext)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            // Compact power + refresh (same size, side by side)
            HStack(spacing: 6) {
                Button {
                    model.toggleUSBRadio()
                } label: {
                    Group {
                        if model.radioBusy {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: model.snapshot.radioOn
                                  ? "power.circle.fill" : "power")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(model.snapshot.radioOn
                                                 ? Tahoe.accentOrange
                                                 : Tahoe.accentGreen)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            model.snapshot.radioOn
                            ? Tahoe.accentOrange.opacity(0.15)
                            : Tahoe.accentGreen.opacity(0.18)
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!model.snapshot.driverLoaded || model.radioBusy)
                .help(model.snapshot.radioOn ? L10n.App.powerOff : L10n.App.powerOn)

                Button {
                    model.refreshNow()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Tahoe.accentCyan)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Tahoe.cardElevated))
                }
                .buttonStyle(.plain)
                .help(L10n.App.refresh)
            }
        }
    }
}

// MARK: - Join dismiss env

private struct JoinDismissKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = nextValue() || value }
}

private struct JoinDismissEnv: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var joinDismiss: () -> Void {
        get { self[JoinDismissEnv.self] }
        set { self[JoinDismissEnv.self] = newValue }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(accent.opacity(0.14))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.4), lineWidth: 1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

