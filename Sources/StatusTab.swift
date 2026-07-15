import SwiftUI
import AppKit

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
