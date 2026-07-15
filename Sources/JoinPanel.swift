import SwiftUI
import AppKit

// MARK: - Join panel — live list from /tmp/1.plist (no classic Realtek UI)

struct JoinPanel: View {
    @ObservedObject var model: WiFiModel
    @Environment(\.joinDismiss) private var joinDismiss

    @State private var networks: [ScannedNetwork] = []
    @State private var otherSSID = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var busy = false
    @State private var scanning = false
    @State private var message: String?
    @State private var selected: String?
    @State private var showPasswordForm = false
    @State private var passwordFormSSID = ""
    @State private var cacheInfo = ""
    @State private var showLogs = false
    @State private var joinOpts = JoinOptions()
    @State private var bandFilter: WiFiBandFilter = .all
    /// When true, only show Wi‑Fi 6 / 7 APs (HE/EHT IEs)
    @State private var wifi6Only = false
    @FocusState private var passwordFocused: Bool
    @ObservedObject private var log = RTLog.shared

    private let supportPath = "/Library/Application Support/WLAN/com.realtek.utility.wifi"

    private var filteredNetworks: [ScannedNetwork] {
        networks.filter { net in
            guard bandFilter.matches(net) else { return false }
            if wifi6Only { return net.isWifi6OrNewer }
            return true
        }
    }

    private var count24: Int { networks.filter { $0.band == .g24 }.count }
    private var count5: Int { networks.filter { $0.band == .g5 }.count }
    private var countWifi6: Int { networks.filter { $0.isWifi6OrNewer }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            statusLine
            bandFilterBar

            // Never block the join form on "reading…" — pending Status taps open form first
            if scanning && networks.isEmpty && !showPasswordForm {
                Spacer(minLength: 0)
                VStack(spacing: 10) {
                    ProgressView()
                    Text(L10n.Join.reading)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Tahoe.subtext)
                }
                Spacer(minLength: 0)
            } else if networks.isEmpty && !showPasswordForm {
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 28))
                        .foregroundColor(Tahoe.subtext)
                    Text(message ?? L10n.Join.emptyCache)
                        .font(.system(size: 11))
                        .foregroundColor(Tahoe.subtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Button(L10n.Join.rescan) { Task { await rescan() } }
                        .buttonStyle(.plain)
                        .foregroundColor(Tahoe.accentCyan)
                        .font(.system(size: 12, weight: .semibold))
                }
                Spacer(minLength: 0)
            } else if filteredNetworks.isEmpty {
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 24))
                        .foregroundColor(Tahoe.subtext)
                    Text(wifi6Only ? L10n.Join.noneWifi6 : L10n.tr("join.none_in_band", bandFilter.label))
                        .font(.system(size: 11))
                        .foregroundColor(Tahoe.subtext)
                    Button(L10n.Join.showAll) {
                        bandFilter = .all
                        wifi6Only = false
                    }
                        .buttonStyle(.plain)
                        .foregroundColor(Tahoe.accentCyan)
                        .font(.system(size: 12, weight: .semibold))
                }
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(filteredNetworks) { net in
                            networkRow(net)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }

            // Password / manual form — always visible when needed
            if showPasswordForm {
                passwordForm
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let message, !showPasswordForm || !message.hasPrefix("Ingresá") {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundColor(message.hasPrefix("✓") ? Tahoe.accentGreen : Tahoe.accentOrange)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showLogs {
                logPanel
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            }

            HStack(spacing: 6) {
                ActionButton(
                    title: showPasswordForm ? L10n.Join.cancel : L10n.Join.otherNetwork,
                    icon: showPasswordForm ? "xmark" : "plus",
                    accent: Tahoe.accentPurple
                ) {
                    if showPasswordForm {
                        withAnimation { showPasswordForm = false }
                        password = ""
                        passwordFormSSID = ""
                        message = nil
                    } else {
                        openPasswordForm(ssid: "", prefillPass: "")
                    }
                }
                ActionButton(title: L10n.Join.logs, icon: "doc.text", accent: Tahoe.accentOrange) {
                    withAnimation { showLogs.toggle() }
                }
                ActionButton(title: L10n.Join.scan, icon: "arrow.clockwise", accent: Tahoe.accentCyan) {
                    Task { await rescan() }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        // Fill parent popover (auto-sized height) instead of a fixed panel size
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PanelBackground())
        .preferredColorScheme(.dark)
        .animation(.easeOut(duration: 0.15), value: showPasswordForm)
        .task {
            // 1) Instant: use Status nearby list + open form if user tapped a network
            if !model.nearbyNetworks.isEmpty {
                networks = model.nearbyNetworks
            }
            applyPendingJoinIfNeeded()

            // 2) Background refresh only if we still need a list (no pending form)
            //    Manual "Scan" still runs a full rescan.
            if !showPasswordForm {
                await rescan(showSpinner: networks.isEmpty)
            }
        }
    }

    /// Status “Cercanas” tap → open password/options for that network immediately.
    /// Does **not** wait for driver scan (pending seed already has channel/BSSID).
    @MainActor
    private func applyPendingJoinIfNeeded() {
        guard let pending = model.pendingJoinNetwork else { return }
        model.pendingJoinNetwork = nil

        // Merge pending into list so it appears if missing
        if !networks.contains(where: { $0.ssid == pending.ssid }) {
            networks.insert(pending, at: 0)
        }

        let seed = networks.first(where: {
            $0.ssid == pending.ssid
                && (pending.bssid == nil || $0.bssid == pending.bssid)
        }) ?? networks.first(where: { $0.ssid == pending.ssid }) ?? pending

        let stored = KeychainStore.bestPassword(forSSID: seed.ssid, supportPath: supportPath) ?? ""
        selected = seed.ssid
        openPasswordForm(ssid: seed.ssid, prefillPass: stored, seed: seed)
    }

    private var header: some View {
        HStack {
            Text(L10n.Join.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Tahoe.text)
            Spacer()
            if scanning { ProgressView().controlSize(.small).padding(.trailing, 6) }
            Button { joinDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Tahoe.subtext)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var statusSummary: String {
        if networks.isEmpty {
            return L10n.Join.listHint
        }
        var parts: [String] = []
        if count24 > 0 || count5 > 0 {
            parts.append("\(count24)×2.4")
            parts.append("\(count5)×5")
        }
        if countWifi6 > 0 {
            parts.append("\(countWifi6)×Wi‑Fi 6+")
        }
        let extra = parts.isEmpty ? "" : " · " + parts.joined(separator: " · ")
        return L10n.tr("join.count_summary", filteredNetworks.count, networks.count, extra, cacheInfo)
    }

    private var statusLine: some View {
        Text(statusSummary)
            .font(.system(size: 10))
            .foregroundColor(Tahoe.subtext)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
    }

    private var bandFilterBar: some View {
        HStack(spacing: 6) {
            ForEach(WiFiBandFilter.allCases) { f in
                let on = bandFilter == f
                let count: Int = {
                    switch f {
                    case .all: return networks.count
                    case .g24: return count24
                    case .g5: return count5
                    }
                }()
                Button {
                    bandFilter = f
                } label: {
                    HStack(spacing: 4) {
                        Text(f.label)
                            .font(.system(size: 10, weight: .semibold))
                        if !networks.isEmpty {
                            Text("\(count)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .opacity(0.85)
                        }
                    }
                    .foregroundColor(on ? Color.black.opacity(0.85) : Tahoe.subtext)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(on ? bandChipColor(f) : Tahoe.cardElevated)
                            .overlay(
                                Capsule().stroke(
                                    on ? Color.clear : Tahoe.cardBorder,
                                    lineWidth: 1
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            // Wi‑Fi 6+ toggle (HE / EHT from beacon IEs)
            Button {
                wifi6Only.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(L10n.Join.wifi6Filter)
                        .font(.system(size: 10, weight: .semibold))
                    if !networks.isEmpty {
                        Text("\(countWifi6)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .opacity(0.85)
                    }
                }
                .foregroundColor(wifi6Only ? Color.black.opacity(0.85) : Tahoe.subtext)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(wifi6Only ? Tahoe.accentGreen : Tahoe.cardElevated)
                        .overlay(
                            Capsule().stroke(
                                wifi6Only ? Color.clear : Tahoe.cardBorder,
                                lineWidth: 1
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private func bandChipColor(_ f: WiFiBandFilter) -> Color {
        switch f {
        case .all: return Tahoe.accentCyan
        case .g24: return Tahoe.accentOrange
        case .g5: return Tahoe.accentPurple
        }
    }

    private func bandBadgeColor(_ band: WiFiBand?) -> Color {
        switch band {
        case .g24: return Tahoe.accentOrange
        case .g5: return Tahoe.accentPurple
        case nil: return Tahoe.subtext
        }
    }

    private func generationColor(_ gen: WiFiGeneration) -> Color {
        switch gen {
        case .wifi7: return Tahoe.accentPurple
        case .wifi6: return Tahoe.accentGreen
        case .wifi5: return Tahoe.accentCyan
        case .wifi4: return Tahoe.subtext
        case .legacy, .unknown: return Tahoe.subtext.opacity(0.7)
        }
    }

    private func networkRow(_ net: ScannedNetwork) -> some View {
        Button {
            selected = net.ssid
            Task { await connect(net) }
        } label: {
            HStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < net.signalBars
                                  ? (net.isConnected ? Tahoe.accentGreen : Tahoe.accentCyan)
                                  : Color.white.opacity(0.12))
                            .frame(width: 3, height: 5 + CGFloat(i) * 3)
                    }
                }
                .frame(width: 18, height: 16, alignment: .bottom)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(net.ssid)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Tahoe.text)
                            .lineLimit(1)
                        if net.isConnected {
                            Text(L10n.Join.connected)
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(Tahoe.accentGreen)
                        }
                    }
                    HStack(spacing: 6) {
                        if let band = net.band {
                            Text(band.shortLabel)
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(bandBadgeColor(band))
                        }
                        if net.generation != .unknown {
                            Text(net.generation.chip)
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(generationColor(net.generation))
                        }
                        if net.signalPercent > 0 {
                            Text("\(net.signalPercent)%")
                        }
                        if net.channel > 0 {
                            Text("Ch \(net.channel)")
                        }
                        Text(net.modeBadge)
                        if net.isAdhoc {
                            Text("IBSS")
                        }
                    }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Tahoe.subtext)
                }
                Spacer(minLength: 4)
                if busy && selected == net.ssid {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: net.isAdhoc ? "antenna.radiowaves.left.and.right" : (net.isSecure ? "lock.fill" : "lock.open"))
                        .font(.system(size: 10))
                        .foregroundColor(net.hasWPS ? Tahoe.accentPurple : Tahoe.subtext)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected == net.ssid || passwordFormSSID == net.ssid
                          ? Tahoe.cardElevated : Tahoe.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                        net.isConnected ? Tahoe.accentGreen.opacity(0.45)
                        : (passwordFormSSID == net.ssid ? Tahoe.accentCyan.opacity(0.5) : Tahoe.cardBorder),
                        lineWidth: 1
                    ))
            )
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private var passwordForm: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(passwordFormSSID.isEmpty ? L10n.Join.options : L10n.tr("join.options_for", passwordFormSSID))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Tahoe.accentCyan)
                .lineLimit(1)

            if passwordFormSSID.isEmpty {
                TextField("SSID", text: $otherSSID)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(fieldBG)
                    .foregroundColor(Tahoe.text)
                    .font(.system(size: 12))
            } else {
                Text(L10n.tr("join.red", passwordFormSSID))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Tahoe.text)
                    .padding(.horizontal, 4)
            }

            // Mode: Infra / Ad-hoc / Auto
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Join.networkType)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                Picker("", selection: $joinOpts.networkType) {
                    ForEach(RTNetworkType.allCases) { t in
                        Text(t.shortLabel).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
            }

            // Auth
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Join.security)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                Picker("", selection: $joinOpts.authEnc) {
                    Text(L10n.Join.open).tag(RTAuthEnc.open)
                    Text(L10n.Join.wpa2).tag(RTAuthEnc.wpa2Psk)
                    Text(L10n.Join.wpa).tag(RTAuthEnc.wpaPsk)
                    Text(L10n.Join.wpaNone).tag(RTAuthEnc.wpaPskAes)
                    Text(L10n.Join.wep).tag(RTAuthEnc.wep128)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
                .tint(Tahoe.accentCyan)
            }

            // Band preference
            VStack(alignment: .leading, spacing: 3) {
                Text("BAND")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                Picker("", selection: Binding(
                    get: { joinOpts.forceBand ?? WiFiBand?.none },
                    set: { joinOpts.forceBand = $0 }
                )) {
                    Text("Auto").tag(Optional<WiFiBand>.none)
                    Text(L10n.Band.g24).tag(Optional<WiFiBand>.some(.g24))
                    Text(L10n.Band.g5).tag(Optional<WiFiBand>.some(.g5))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
            }

            // WPS
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Join.wps)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                Picker("", selection: $joinOpts.wps) {
                    ForEach(RTWPSMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
                .tint(Tahoe.accentPurple)
            }

            if joinOpts.wps == .pin {
                TextField(L10n.WPS.pinField, text: $joinOpts.wpsPin)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(fieldBG)
                    .foregroundColor(Tahoe.text)
                    .font(.system(size: 12, design: .monospaced))
            }

            if joinOpts.wps == .none && joinOpts.authEnc.needsPassword {
                HStack {
                    Group {
                        if showPassword {
                            TextField(joinOpts.authEnc == .wep128 || joinOpts.authEnc == .wep64
                                     ? L10n.Join.wepKey : L10n.Join.password, text: $password)
                        } else {
                            SecureField(joinOpts.authEnc == .wep128 || joinOpts.authEnc == .wep64
                                        ? L10n.Join.wepKey : L10n.Join.password, text: $password)
                        }
                    }
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(Tahoe.text)
                    .focused($passwordFocused)
                    .onSubmit { Task { await submitPasswordForm() } }

                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(Tahoe.subtext)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(fieldBG)
            }

            if joinOpts.wps == .pbc {
                Text(L10n.Join.wpsHint)
                    .font(.system(size: 9))
                    .foregroundColor(Tahoe.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if joinOpts.networkType == .adhoc {
                Text(L10n.Join.adhocHint)
                    .font(.system(size: 9))
                    .foregroundColor(Tahoe.accentOrange)
            }

            Button {
                Task { await submitPasswordForm() }
            } label: {
                HStack {
                    if busy { ProgressView().controlSize(.small) }
                    Text(busy ? L10n.Join.connecting : (joinOpts.wps == .pbc ? L10n.Join.joinWpsPbc : L10n.Join.join))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(canSubmitPassword ? Tahoe.accentCyan : Tahoe.accentCyan.opacity(0.4))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(busy || !canSubmitPassword)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Tahoe.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.accentCyan.opacity(0.35), lineWidth: 1))
        )
    }

    private var canSubmitPassword: Bool {
        let ssid = passwordFormSSID.isEmpty
            ? otherSSID.trimmingCharacters(in: .whitespacesAndNewlines)
            : passwordFormSSID
        guard !ssid.isEmpty else { return false }
        if joinOpts.wps == .pbc { return true }
        if joinOpts.wps == .pin {
            let d = joinOpts.wpsPin.filter(\.isNumber)
            return d.count == 4 || d.count == 8
        }
        if !joinOpts.authEnc.needsPassword { return true }
        if joinOpts.authEnc == .wep64 || joinOpts.authEnc == .wep128 {
            return password.count >= 5
        }
        return password.count >= 8
    }

    private func isSSIDSecure(_ ssid: String) -> Bool {
        networks.first(where: { $0.ssid == ssid })?.isSecure ?? true
    }

    private var fieldBG: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Tahoe.cardElevated)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.Join.logs.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Tahoe.accentOrange)
                Spacer()
                Button(L10n.Join.copy) { RTLog.shared.copyToPasteboard() }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Tahoe.accentCyan)
                Button(L10n.Join.file) { RTLog.shared.revealInFinder() }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Tahoe.accentCyan)
            }
            ScrollView {
                Text(log.recentText.isEmpty ? L10n.Join.logsEmpty : log.recentText)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Tahoe.subtext)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 90)
            Text(RTLog.filePath)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(Tahoe.subtext.opacity(0.7))
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Tahoe.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
        )
    }

    // MARK: - Actions

    private func openPasswordForm(ssid: String, prefillPass: String, seed: ScannedNetwork? = nil) {
        passwordFormSSID = ssid
        otherSSID = ssid
        password = prefillPass
        if let seed {
            joinOpts = JoinOptions.default(for: seed)
        } else if ssid.isEmpty {
            joinOpts = JoinOptions()
        }
        message = ssid.isEmpty ? nil : L10n.tr("join.options_for", ssid)
        withAnimation { showPasswordForm = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            passwordFocused = true
        }
    }

    @MainActor
    private func rescan(showSpinner: Bool = true) async {
        if showSpinner { scanning = true }
        if !showPasswordForm { message = nil }
        // Only treat as connected if we have real L2/IP — not sticky kext SSID
        let reallyConnected = model.snapshot.ip != "—"
            || model.snapshot.linkSpeedBps > 0
            || NetProbe.mediaActive(bsd: model.snapshot.bsdName.isEmpty ? "en1" : model.snapshot.bsdName)
        let connectedSSID: String? = {
            guard reallyConnected else { return nil }
            let s = model.snapshot.ssid
            return (s.isEmpty || s == "—") ? nil : s
        }()

        let (live, err) = await RealtekLiveScan.scan(
            classicAppPaths: [
                "/Library/Application Support/WLAN/StatusBarApp.app",
                "/Applications/StatusBarApp.app",
                NSHomeDirectory() + "/Downloads/StatusBarApp.app"
            ],
            currentSSID: connectedSSID
        )

        var merged = live
        for p in model.profiles where !merged.contains(where: { $0.ssid == p.ssid }) {
            // Never inject password-looking profile keys that aren't real SSIDs from scan
            // unless they look like normal network names
            merged.append(ScannedNetwork(
                ssid: p.ssid,
                isSecure: p.hasPassword || true,
                isConnected: p.isDefault && model.snapshot.active,
                signalBars: 2,
                signalPercent: 0,
                channel: p.channel ?? 0,
                isFromLiveScan: false
            ))
        }
        // Keep password form open; don't wipe UI mid-type
        networks = merged

        if let age = RealtekLiveScan.cacheAge() {
            if age < 60 { cacheInfo = L10n.tr("join.updated_ago", Int(age)) }
            else if age < 3600 { cacheInfo = L10n.tr("join.updated_min", Int(age/60)) }
            else { cacheInfo = L10n.Join.cacheOld }
        } else {
            cacheInfo = ""
        }

        if let err, merged.isEmpty, !showPasswordForm { message = err }
        else if merged.isEmpty, !showPasswordForm { message = L10n.Join.noNetworks }
        else if !showPasswordForm { message = nil }
        scanning = false
    }

    @MainActor
    private func connect(_ net: ScannedNetwork) async {
        busy = true
        selected = net.ssid

        // Open networks: join immediately
        // Always open options form so user can pick Infra/Ad-hoc/WPS
        busy = false
        let stored = KeychainStore.bestPassword(forSSID: net.ssid, supportPath: supportPath) ?? ""
        openPasswordForm(ssid: net.ssid, prefillPass: stored, seed: net)
    }

    @MainActor
    private func submitPasswordForm() async {
        let ssid = passwordFormSSID.isEmpty
            ? otherSSID.trimmingCharacters(in: .whitespacesAndNewlines)
            : passwordFormSSID
        guard !ssid.isEmpty else {
            message = L10n.Join.emptySSID
            return
        }

        // Ad-hoc + WPA2 is invalid on Realtek UI — nudge to WPA-None
        if joinOpts.networkType == .adhoc && joinOpts.authEnc == .wpa2Psk {
            joinOpts.authEnc = .wpaPsk
            message = L10n.Join.adhocAuthNudge
        }

        let pass = password
        if joinOpts.wps == .none && joinOpts.authEnc.needsPassword {
            let minL = (joinOpts.authEnc == .wep64 || joinOpts.authEnc == .wep128) ? 5 : 8
            if pass.count < minL {
                message = L10n.tr("join.short_key", minL)
                return
            }
        }

        busy = true
        selected = ssid
        message = joinOpts.wps == .pbc
            ? L10n.tr("join.wps_pbc_wait", ssid)
            : L10n.tr("join.connecting_to", ssid)
        showLogs = true

        let net = networks.first(where: { $0.ssid == ssid })
        if joinOpts.channel == nil, let c = net?.channel, c > 0 {
            joinOpts.channel = UInt32(c)
        }
        if joinOpts.bssid == nil {
            joinOpts.bssid = net?.bssid
        }

        let r = await model.joinNetwork(
            ssid: ssid,
            password: pass,
            useStoredPassword: false,
            channel: joinOpts.channel.map { Int($0) },
            bssid: joinOpts.bssid,
            options: joinOpts
        )
        message = r
        if r.hasPrefix("✓") {
            try? await Task.sleep(nanoseconds: 800_000_000)
            model.refreshNow()
            joinDismiss()
        }
        busy = false
    }
}
