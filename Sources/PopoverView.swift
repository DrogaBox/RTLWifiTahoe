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
                Text(L10n.Tab.pro).tag(2)
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Group {
                switch tab {
                case 0: StatusTab(model: model, showJoin: $showJoin)
                case 1: ProfilesTab(model: model, showJoin: $showJoin)
                default: ProTab(model: model)
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
                                  ? "power" : "power.circle.fill")
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

// MARK: - Status

struct StatusTab: View {
    @ObservedObject var model: WiFiModel
    @Binding var showJoin: Bool

    private var statusBadge: some View {
        let hasIP = model.snapshot.ip != "—"
        let associating = model.snapshot.associating
        let title: String
        let color: Color
        if hasIP {
            title = L10n.Status.active
            color = Tahoe.accentGreen
        } else if associating {
            title = L10n.Status.linking
            color = Tahoe.accentOrange
        } else {
            title = L10n.Status.down
            color = Tahoe.accentRed
        }
        return Text(title)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.18)))
    }

    var body: some View {
        // Natural height — parent popover grows downward to fit
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.snapshot.ssid)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Tahoe.text)
                        .lineLimit(1)
                    Text("\(model.snapshot.displayName) · \(model.snapshot.bsdName.isEmpty ? "—" : model.snapshot.bsdName)")
                        .font(.system(size: 10))
                        .foregroundColor(Tahoe.subtext)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                statusBadge
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(card)

            SignalMeter(
                level: model.snapshot.signalLevel,
                linkMbps: model.snapshot.linkMbps,
                hasIP: model.snapshot.ip != "—",
                associating: model.snapshot.associating,
                signalPercent: model.snapshot.signalPercent > 0 ? model.snapshot.signalPercent : nil,
                channel: model.snapshot.channel
            )

            HStack(spacing: 6) {
                rateChip(L10n.Status.rx, model.snapshot.rxMbps, Tahoe.accentCyan)
                rateChip(L10n.Status.tx, model.snapshot.txMbps, Tahoe.accentPurple)
            }

            VStack(spacing: 5) {
                InfoRow(
                    leftTitle: L10n.Status.ip, leftValue: model.snapshot.ipDisplay, leftAccent: Tahoe.accentCyan,
                    rightTitle: L10n.Status.mask,
                    rightValue: model.snapshot.netmaskDisplay,
                    rightAccent: model.snapshot.netmask != "—" ? Tahoe.accentCyan : Tahoe.subtext
                )
                InfoRow(
                    leftTitle: L10n.Status.router,
                    leftValue: model.snapshot.routerDisplay,
                    leftAccent: model.snapshot.router != "—" ? Tahoe.accentOrange : Tahoe.subtext,
                    rightTitle: L10n.Status.internet,
                    rightValue: model.snapshot.internetDisplay,
                    rightAccent: model.snapshot.internetReachable
                        ? Tahoe.accentGreen
                        : (model.snapshot.gatewayReachable ? Tahoe.accentOrange : Tahoe.accentRed)
                )
                InfoRow(
                    leftTitle: L10n.Status.mac, leftValue: model.snapshot.mac, leftAccent: Tahoe.accentGreen,
                    rightTitle: L10n.Status.dns,
                    rightValue: model.snapshot.dnsDisplay,
                    rightAccent: model.snapshot.dns.isEmpty && model.snapshot.dnsIsAutomatic
                        ? Tahoe.subtext : Tahoe.accentPurple
                )
            }

            // Router detail — full width so model name is readable (not crammed in InfoRow)
            if model.snapshot.router != "—" {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.router.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Tahoe.accentOrange)
                        Text(model.snapshot.routerModel != "—"
                             ? model.snapshot.routerModel
                             : L10n.Status.gateway)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Tahoe.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 10) {
                        Label {
                            Text(model.snapshot.router)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Tahoe.accentOrange)
                        } icon: {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 9))
                                .foregroundColor(Tahoe.subtext)
                        }
                        if model.snapshot.routerMAC != "—" {
                            Label {
                                Text(model.snapshot.routerMAC)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Tahoe.subtext)
                            } icon: {
                                Image(systemName: "barcode")
                                    .font(.system(size: 9))
                                    .foregroundColor(Tahoe.subtext)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .labelStyle(.titleAndIcon)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(card)
            }

            nearbySection

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    ActionButton(title: L10n.App.copyIP, icon: "doc.on.doc", accent: Tahoe.accentCyan) {
                        model.copyIP()
                    }
                    if model.snapshot.ip != "—" {
                        ActionButton(
                            title: model.disconnectBusy ? L10n.Status.disconnecting : L10n.App.disconnect,
                            icon: "wifi.slash",
                            accent: Tahoe.accentOrange
                        ) {
                            model.disconnectNetwork()
                        }
                    } else {
                        ActionButton(title: L10n.App.router, icon: "globe", accent: Tahoe.accentOrange) {
                            model.openRouter()
                        }
                    }
                    ActionButton(title: L10n.App.join, icon: "wifi", accent: Tahoe.accentGreen) {
                        showJoin = true
                    }
                }
                if let err = model.lastError {
                    Text(err)
                        .font(.system(size: 9))
                        .foregroundColor(Tahoe.accentRed)
                        .lineLimit(2)
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .onAppear {
            if model.scanEnabled {
                model.scanNearby(force: false)
            }
        }
    }

    // MARK: Nearby list

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(L10n.Status.nearby)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                    .tracking(0.4)
                if model.isScanningNearby {
                    ProgressView().controlSize(.mini)
                } else {
                    Text(model.nearbyScanAgeText)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Tahoe.subtext.opacity(0.85))
                }
                Spacer(minLength: 4)
                Text(model.scanEnabled ? L10n.Status.scanOn : L10n.Status.scanOff)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(model.scanEnabled ? Tahoe.accentCyan : Tahoe.accentOrange)
                Toggle("", isOn: $model.scanEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Tahoe.accentCyan))
                    .controlSize(.mini)
                    .labelsHidden()
                    .help(model.scanEnabled
                          ? "Escaneo de redes activo (tocá para apagar)"
                          : "Escaneo apagado (tocá para activar)")
                if model.scanEnabled {
                    Button {
                        model.scanNearby(force: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Tahoe.accentCyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isScanningNearby)
                    .help("Escanear ahora")
                }
            }

            if !model.scanEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(Tahoe.accentOrange)
                    Text(L10n.Status.scanDisabled)
                        .font(.system(size: 10))
                        .foregroundColor(Tahoe.subtext)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(card)
            } else if model.nearbyNetworks.isEmpty {
                HStack(spacing: 8) {
                    if model.isScanningNearby {
                        ProgressView().controlSize(.small)
                        Text(L10n.Status.scanning)
                    } else {
                        Image(systemName: "wifi.exclamationmark")
                            .foregroundColor(Tahoe.subtext)
                        Text(L10n.Status.noNetworks)
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(Tahoe.subtext)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(card)
            } else {
                VStack(spacing: 3) {
                    ForEach(model.nearbyNetworks.prefix(12)) { net in
                        nearbyRow(net)
                    }
                    if model.nearbyNetworks.count > 12 {
                        Text(L10n.tr("status.more_networks", model.nearbyNetworks.count - 12))
                            .font(.system(size: 9))
                            .foregroundColor(Tahoe.subtext)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func nearbyRow(_ net: ScannedNetwork) -> some View {
        Button {
            // Open Join overlay on this SSID (password form), not Profiles tab
            model.pendingJoinNetwork = net
            showJoin = true
        } label: {
            HStack(spacing: 8) {
                // Signal bars
                HStack(alignment: .bottom, spacing: 1.5) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(i < net.signalBars
                                  ? (net.isConnected ? Tahoe.accentGreen : Tahoe.accentCyan)
                                  : Color.white.opacity(0.12))
                            .frame(width: 2.5, height: 4 + CGFloat(i) * 2.5)
                    }
                }
                .frame(width: 14, height: 14, alignment: .bottom)

                Text(net.ssid)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Tahoe.text)
                    .lineLimit(1)

                Spacer(minLength: 2)

                if let band = net.band {
                    Text(band.shortLabel)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(band == .g24 ? Tahoe.accentOrange : Tahoe.accentPurple)
                }
                if net.generation != .unknown {
                    Text(net.generation.shortBadge)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(net.generation >= .wifi6 ? Tahoe.accentGreen : Tahoe.subtext)
                }
                if net.channel > 0 {
                    Text("Ch\(net.channel)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(Tahoe.subtext)
                }
                if net.isConnected {
                    Text("●")
                        .font(.system(size: 8))
                        .foregroundColor(Tahoe.accentGreen)
                } else if net.isSecure {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Tahoe.subtext)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(net.isConnected ? Tahoe.cardElevated : Tahoe.card)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(
                        net.isConnected ? Tahoe.accentGreen.opacity(0.4) : Tahoe.cardBorder,
                        lineWidth: 1
                    ))
            )
        }
        .buttonStyle(.plain)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Tahoe.card)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.cardBorder, lineWidth: 1))
    }

    private func rateChip(_ title: String, _ mbps: Double, _ accent: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Tahoe.subtext)
            Text(String(format: "%.2f Mbps", mbps))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Tahoe.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
        )
    }

    private func shortMedia(_ m: String) -> String {
        if m == "—" || m.isEmpty { return "—" }
        if m.count <= 14 { return m }
        return String(m.prefix(12)) + "…"
    }

    private func shortDriver(_ v: String) -> String {
        // 1830.32.b27.11192020 → 1830.32.b27
        let parts = v.split(separator: ".")
        if parts.count >= 3 {
            return parts.prefix(3).joined(separator: ".")
        }
        return v.count > 16 ? String(v.prefix(14)) + "…" : v
    }
}

// MARK: - DNS section (Profiles tab)

struct DNSSectionView: View {
    @ObservedObject var model: WiFiModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(L10n.DNS.title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                    .tracking(0.4)
                if model.dnsBusy {
                    ProgressView().controlSize(.mini)
                } else if model.snapshot.dnsIsAutomatic {
                    Text(L10n.DNS.dhcp)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Tahoe.accentCyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Tahoe.accentCyan.opacity(0.15)))
                } else if let p = model.snapshot.matchedDNSPreset, p != .automatic {
                    Text(p.shortLabel)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Tahoe.accentPurple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Tahoe.accentPurple.opacity(0.15)))
                }
                Spacer(minLength: 0)
            }

            Text(model.snapshot.dnsDisplay)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Tahoe.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            let columns = [GridItem(.adaptive(minimum: 72), spacing: 5)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
                ForEach(DNSPreset.allCases) { preset in
                    let on = model.selectedDNSPreset == preset
                    Button {
                        model.applyDNSPreset(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(preset.shortLabel)
                                .font(.system(size: 10, weight: .bold))
                            Text(preset == .automatic ? "DHCP" : (preset.servers.first ?? ""))
                                .font(.system(size: 8, design: .monospaced))
                                .opacity(0.85)
                        }
                        .foregroundColor(on ? Color.black.opacity(0.85) : Tahoe.subtext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(on ? Tahoe.accentPurple : Tahoe.cardElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(on ? Color.clear : Tahoe.cardBorder, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(model.dnsBusy
                              || (model.snapshot.networkServiceName.isEmpty && model.snapshot.bsdName.isEmpty))
                    .help(preset.label + " — " + preset.detail)
                }
            }

            if let msg = model.dnsStatusMessage {
                Text(msg)
                    .font(.system(size: 9))
                    .foregroundColor(msg.hasPrefix("DNS →") || msg.hasPrefix("OK")
                                     ? Tahoe.accentGreen : Tahoe.accentOrange)
                    .lineLimit(2)
            }
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

// MARK: - Profiles

struct ProfilesTab: View {
    @ObservedObject var model: WiFiModel
    @Binding var showJoin: Bool
    @State private var confirmForget: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Profiles.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Tahoe.subtext)
                .padding(.horizontal, 12)

            if model.profiles.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 22))
                        .foregroundColor(Tahoe.subtext)
                    Text(L10n.Profiles.empty)
                        .font(.system(size: 11))
                        .foregroundColor(Tahoe.subtext)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 6) {
                    ForEach(model.profiles) { p in
                        HStack(spacing: 8) {
                            Button {
                                showJoin = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: p.isDefault ? "star.fill" : "wifi")
                                        .font(.system(size: 12))
                                        .foregroundColor(p.isDefault ? Tahoe.accentOrange : Tahoe.accentCyan)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(p.ssid)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Tahoe.text)
                                            .lineLimit(1)
                                        Text(p.hasPassword ? L10n.Profiles.withPassword : L10n.Profiles.open)
                                            .font(.system(size: 9))
                                            .foregroundColor(Tahoe.subtext)
                                    }
                                    Spacer(minLength: 4)
                                    if p.isDefault {
                                        Text(L10n.Profiles.last)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Tahoe.accentOrange)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                confirmForget = p.ssid
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Tahoe.accentRed)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Tahoe.accentRed.opacity(0.15)))
                            }
                            .buttonStyle(.plain)
                            .help(L10n.tr("profiles.forget_help", p.ssid))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Tahoe.card)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
                        )
                    }
                }
                .padding(.horizontal, 12)
            }

            // DNS presets live under Profiles
            DNSSectionView(model: model)
                .padding(.horizontal, 12)

            HStack(spacing: 6) {
                ActionButton(title: L10n.App.join, icon: "plus.circle", accent: Tahoe.accentGreen) {
                    showJoin = true
                }
                ActionButton(title: L10n.Profiles.folder, icon: "folder", accent: Tahoe.accentCyan) {
                    model.revealProfilesFolder()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .confirmationDialog(
            L10n.Profiles.forgetTitle,
            isPresented: Binding(
                get: { confirmForget != nil },
                set: { if !$0 { confirmForget = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let ssid = confirmForget {
                Button(L10n.tr("profiles.forget_action", ssid), role: .destructive) {
                    model.forgetNetwork(ssid: ssid)
                    confirmForget = nil
                }
                Button(L10n.Profiles.cancel, role: .cancel) {
                    confirmForget = nil
                }
            }
        } message: {
            Text(L10n.Profiles.forgetMessage)
        }
    }
}

// MARK: - Pro

struct ProTab: View {
    @ObservedObject var model: WiFiModel
    @ObservedObject private var themes = ThemeStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            section(L10n.Pro.theme) {
                ThemePickerView(themes: themes)
            }

            section(L10n.Pro.menuBar) {
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
                        Text(L10n.Pro.refresh)
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

            section(L10n.Pro.behavior) {
                TahoeToggleRow(
                    title: L10n.Pro.autoReconnect,
                    subtitle: L10n.Pro.autoReconnectSub,
                    isOn: $model.autoReconnect
                )
                TahoeToggleRow(
                    title: L10n.tr("pro.notifications"),
                    subtitle: L10n.tr("pro.notifications_sub"),
                    isOn: $model.showNotifications
                )
                TahoeToggleRow(
                    title: L10n.Pro.scanNearby,
                    subtitle: L10n.Pro.scanNearbySub,
                    isOn: $model.scanEnabled
                )
                TahoeToggleRow(
                    title: L10n.Pro.launchLogin,
                    subtitle: L10n.Pro.launchLoginSub,
                    isOn: $model.launchAtLogin
                )
                TahoeToggleRow(
                    title: L10n.Pro.killClassic,
                    subtitle: L10n.Pro.killClassicSub,
                    isOn: $model.hideClassicUtility
                )
                ActionButton(title: L10n.Pro.quitClassic, icon: "xmark.octagon", accent: Tahoe.accentOrange) {
                    model.purgeClassicUtility()
                }
            }

            section(L10n.Pro.tools) {
                VStack(spacing: 6) {
                    ActionButton(title: L10n.Pro.networkSettings, icon: "gearshape", accent: Tahoe.accentCyan) {
                        model.openNetworkSettings()
                    }
                    ActionButton(title: L10n.App.quit, icon: "xmark.circle", accent: Tahoe.accentRed) {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
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
}
