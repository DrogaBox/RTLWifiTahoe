import SwiftUI
import AppKit

// MARK: - Pro

struct SettingsTab: View {
    @ObservedObject var model: WiFiModel
    @ObservedObject private var themes = ThemeStore.shared
    /// Collapsed by default so Settings stays short; user expands Theme / Behavior.
    @State private var themeExpanded = false
    @State private var behaviorExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            collapsibleSection(
                title: L10n.Settings.theme,
                isExpanded: $themeExpanded,
                summary: themes.themeID.label
            ) {
                ThemePickerView(themes: themes)
            }

            section(L10n.Settings.menuBar) {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("", selection: $model.menuBarMode) {
                        ForEach(MenuBarDisplayMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .controlSize(.small)

                    HStack {
                        Text(L10n.Settings.refresh)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Tahoe.text)
                        Spacer()
                        Text(String(format: "%.0fs", model.refreshHz))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Tahoe.accentCyan)
                    }
                    Slider(value: $model.refreshHz, in: 1...5, step: 1)
                        .controlSize(.small)
                        .tint(Tahoe.accentCyan)
                }
            }

            collapsibleSection(
                title: L10n.Settings.behavior,
                isExpanded: $behaviorExpanded,
                summary: behaviorSummary
            ) {
                TahoeToggleRow(
                    title: L10n.Settings.autoReconnect,
                    subtitle: L10n.Settings.autoReconnectSub,
                    isOn: $model.autoReconnect
                )
                TahoeToggleRow(
                    title: L10n.Settings.notifications,
                    subtitle: L10n.Settings.notificationsSub,
                    isOn: $model.showNotifications
                )
                TahoeToggleRow(
                    title: L10n.Settings.scanNearby,
                    subtitle: L10n.Settings.scanNearbySub,
                    isOn: $model.scanEnabled
                )
                TahoeToggleRow(
                    title: L10n.Settings.launchLogin,
                    subtitle: L10n.Settings.launchLoginSub,
                    isOn: $model.launchAtLogin
                )
                TahoeToggleRow(
                    title: L10n.Settings.killClassic,
                    subtitle: L10n.Settings.killClassicSub,
                    isOn: $model.hideClassicUtility
                )
                ActionButton(title: L10n.Settings.quitClassic, icon: "xmark.octagon", accent: Tahoe.accentOrange) {
                    model.purgeClassicUtility()
                }
            }

            section(L10n.Settings.links) {
                HStack(spacing: 6) {
                    ActionButton(title: L10n.Settings.github, icon: "link", accent: Tahoe.accentCyan) {
                        model.openGitHub()
                    }
                    ActionButton(title: L10n.Settings.donate, icon: "heart.fill", accent: Tahoe.accentOrange) {
                        model.openDonate()
                    }
                }
            }

            section(L10n.Settings.tools) {
                VStack(spacing: 6) {
                    ActionButton(title: L10n.Settings.networkSettings, icon: "gearshape", accent: Tahoe.accentCyan) {
                        model.openNetworkSettings()
                    }
                    ActionButton(title: L10n.App.about, icon: "info.circle", accent: Tahoe.accentPurple) {
                        model.showAbout()
                    }
                    ActionButton(title: L10n.App.quit, icon: "xmark.circle", accent: Tahoe.accentRed) {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .animation(.easeOut(duration: 0.18), value: themeExpanded)
        .animation(.easeOut(duration: 0.18), value: behaviorExpanded)
    }

    private var behaviorSummary: String {
        var bits: [String] = []
        if model.autoReconnect { bits.append("Auto") }
        if model.showNotifications { bits.append("Notify") }
        if model.scanEnabled { bits.append("Scan") }
        return bits.isEmpty ? "—" : bits.joined(separator: " · ")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Tahoe.subtext)
                .tracking(0.5)
            VStack(alignment: .leading, spacing: 4) {
                content()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Tahoe.card)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.cardBorder, lineWidth: 1))
            )
        }
    }

    /// Expandable block (Tema / Behavior) — header row toggles body.
    private func collapsibleSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        summary: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                isExpanded.wrappedValue.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Tahoe.accentCyan)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                    Text(title.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Tahoe.subtext)
                        .tracking(0.5)
                    Spacer(minLength: 4)
                    if !isExpanded.wrappedValue, !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Tahoe.text.opacity(0.75))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Tahoe.card)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.cardBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 4) {
                    content()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Tahoe.card)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.cardBorder, lineWidth: 1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
