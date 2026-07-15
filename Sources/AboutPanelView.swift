import SwiftUI
import AppKit

// MARK: - About Panel (mini floating window, Power Gadget style)

/// A compact about panel displayed as a small floating NSPanel.
/// Shows app version, driver version, GitHub link, and a close button.
struct AboutPanelView: View {
    let model: WiFiModel

    /// Notification name that AppDelegate listens to for showing the panel.
    static let showNotification = Notification.Name("com.drogabox.rtlwifitahoe.showAbout")

    @State private var contributors: [Contributor] = []
    @State private var contributorsLoading = true
    @State private var certStatuses: [CertStatus] = []
    @State private var certsLoading = true
    @State private var panelWindow: NSWindow?
    @State private var dragStart: CGPoint = .zero
    @State private var initialMouse: CGPoint = .zero

    var body: some View {
        ZStack {
            PanelBackground()

            VStack(spacing: 10) {
                // Capture parent NSPanel reference for dragging
                PanelWindowAccessor { w in
                    if panelWindow == nil { panelWindow = w }
                }
                .frame(width: 0, height: 0)
                // ── Icon ──
                ZStack {
                    Circle()
                        .fill(Tahoe.accentCyan.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "wifi")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Tahoe.accentCyan)
                }
                .padding(.top, 12)

                // ── Title ──
                VStack(spacing: 1) {
                    Text(L10n.App.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Tahoe.text)

                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
                    Text("Version \(version) (Build \(build))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Tahoe.subtext)
                }

                // ── Driver + Chipset ──
                VStack(spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 8))
                            .foregroundColor(Tahoe.accentGreen)
                        Text("Driver:")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Tahoe.subtext)
                        Text(model.snapshot.driverVersion)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Tahoe.text)
                    }
                    if let chipset = Self.chipsetName(from: model.snapshot.usbVendorID, product: model.snapshot.usbProductID) {
                        HStack(spacing: 5) {
                            Image(systemName: "cpu")
                                .font(.system(size: 8))
                                .foregroundColor(Tahoe.accentOrange)
                            Text("Chipset:")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Tahoe.subtext)
                            Text(chipset)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Tahoe.text)
                        }
                    } else {
                        // Fallback: re-query IOKit directly on this thread
                        HStack(spacing: 5) {
                            Image(systemName: "cpu")
                                .font(.system(size: 8))
                                .foregroundColor(Tahoe.accentOrange)
                            Text("Chipset:")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Tahoe.subtext)
                            Text("\(model.snapshot.usbVendorID) \(model.snapshot.usbProductID)")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Tahoe.text)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Tahoe.card)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.cardBorder, lineWidth: 1))
                )

                // ── Enterprise Certificates ──
                if certsLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                } else if !certStatuses.isEmpty {
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "certificate.fill")
                                .font(.system(size: 8))
                                .foregroundColor(Tahoe.accentOrange)
                            Text("Certificates")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Tahoe.subtext)
                        }
                        ForEach(certStatuses, id: \.path) { cert in
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(cert.expired ? Tahoe.accentRed : (cert.daysLeft < 30 ? Tahoe.accentOrange : Tahoe.accentGreen))
                                    .frame(width: 5, height: 5)
                                Text(cert.label)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(Tahoe.text)
                                    .lineLimit(1)
                                Spacer(minLength: 2)
                                if let expires = cert.expires {
                                    Text(EnterpriseCertStore.formatDate(expires))
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(Tahoe.subtext)
                                    Text(cert.daysLeft > 0 ? "\(cert.daysLeft)d" : "—")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(cert.expired ? Tahoe.accentRed : (cert.daysLeft < 30 ? Tahoe.accentOrange : Tahoe.accentGreen))
                                } else if let err = cert.error {
                                    Text(err)
                                        .font(.system(size: 7))
                                        .foregroundColor(Tahoe.accentOrange)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Tahoe.card)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.cardBorder, lineWidth: 1))
                    )
                }

                // ── Contributors ──
                if contributorsLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                } else if !contributors.isEmpty {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 8))
                                .foregroundColor(Tahoe.accentPurple)
                            Text("Contributors")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Tahoe.subtext)
                        }
                        // Top 5 contributors
                        let top5 = contributors.prefix(5)
                        ForEach(top5) { c in
                            HStack(spacing: 6) {
                                AsyncImage(url: URL(string: c.avatarURL)) { phase in
                                    if let img = phase.image {
                                        img.resizable().frame(width: 16, height: 16).clipShape(Circle())
                                    } else {
                                        Circle().fill(Tahoe.card).frame(width: 16, height: 16)
                                    }
                                }
                                Text(c.login)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Tahoe.text)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Text("\(c.contributions)")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Tahoe.accentCyan)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Tahoe.card)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.cardBorder, lineWidth: 1))
                    )
                }

                // ── GitHub ──
                Button {
                    model.openGitHub()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "link")
                            .font(.system(size: 9))
                        Text("github.com/DrogaBox/RTLWifiTahoe")
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(Tahoe.accentCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Tahoe.accentCyan.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.accentCyan.opacity(0.35), lineWidth: 1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // ── Donate (PayPal) ──
                Button {
                    let url = "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mrleisures%40gmail.com&item_name=RTL+Wi-Fi+Tahoe"
                    if let u = URL(string: url) {
                        NSWorkspace.shared.open(u)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                        Text("Donate (PayPal)")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(Tahoe.accentOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Tahoe.accentOrange.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.accentOrange.opacity(0.35), lineWidth: 1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // ── Footer ──
                HStack(spacing: 3) {
                    Text("Powered by")
                        .font(.system(size: 8))
                        .foregroundColor(Tahoe.subtext.opacity(0.7))
                    Text("reverse engineering")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Tahoe.accentOrange)
                    Text("❤️")
                        .font(.system(size: 8))
                }

                // Close button
                Button {
                    NotificationCenter.default.post(name: Self.dismissNotification, object: nil)
                } label: {
                    Text("Close")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Tahoe.accentRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Tahoe.accentRed.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.accentRed.opacity(0.35), lineWidth: 1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 14)
        }
        .frame(width: 260, height: 360)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in
                    guard let w = panelWindow else { return }
                    if dragStart == .zero {
                        dragStart = CGPoint(x: w.frame.origin.x, y: w.frame.origin.y)
                        initialMouse = NSEvent.mouseLocation
                    }
                    let cur = NSEvent.mouseLocation
                    let dx = cur.x - initialMouse.x
                    let dy = cur.y - initialMouse.y  // screen Y goes UP
                    var f = w.frame
                    f.origin.x = dragStart.x + dx
                    f.origin.y = dragStart.y + dy
                    w.setFrameOrigin(f.origin)
                }
                .onEnded { _ in
                    dragStart = .zero
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: ThemeStore.shared.palette.cornerRadius))
        .preferredColorScheme(.dark)
        .task {
            async let contribs = GitHubContributors.fetch()
            // Load enterprise certificate info in background
            let supportDir = "/Library/Application Support/WLAN/com.realtek.utility.wifi"
            async let certs = Task.detached { () -> [CertStatus] in
                EnterpriseCertStore.inspect(supportPath: supportDir)
            }.value

            let (c, cList) = await (contribs, certs)
            contributors = c
            contributorsLoading = false
            certStatuses = cList
            certsLoading = false
        }
    }

    // MARK: - Chipset name lookup

    /// Maps (vendor, product) hex pairs to human-readable chipset names.
    /// Uses combined "vendor:product" keys so we can identify OEM devices
    /// (TP-Link, D-Link, etc.) that embed Realtek chips under their own VID.
    static func chipsetName(from vendor: String, product: String) -> String? {
        guard vendor != "—", product != "—" else {
            rtlog("[chipset] vendor=\"\(vendor)\" or product=\"\(product)\" is empty")
            return nil
        }

        let key = "\(vendor.lowercased()):\(product.lowercased())"
        rtlog("[chipset] looking up: \(key)")
        let known: [String: String] = [
            // Realtek native
            "0x0BDA:0x0179": "RTL8188EU (ETV)",
            "0x0BDA:0x018A": "RTL8188CTV",
            "0x0BDA:0x0823": "RTL8821AU+BT",
            "0x0BDA:0x0A8A": "RTL8188CTV",
            "0x0BDA:0x1E1E": "RTL8188CUS",
            "0x0BDA:0x2003": "RTL8811AU",
            "0x0BDA:0x2005": "RTL8188GU/RTL8710B",
            "0x0BDA:0x2006": "RTL8811CU",
            "0x0BDA:0x2102": "Realtek (RTL8811CU)",
            "0x0BDA:0x2E2E": "RTL8188CUS",
            "0x0BDA:0x317F": "RTL8188RU (Netcore)",
            "0x0BDA:0x318B": "RTL8192FU (Edimax)",
            "0x0BDA:0x5088": "RTL8188CUS",
            "0x0BDA:0x8011": "RTL8188CTV",
            "0x0BDA:0x8152": "RTL8152",
            "0x0BDA:0x8171": "RTL8188SU",
            "0x0BDA:0x8176": "RTL8188CU",
            "0x0BDA:0x8177": "RTL8192CU",
            "0x0BDA:0x8178": "RTL8192CU",
            "0x0BDA:0x8179": "RTL8188EU",
            "0x0BDA:0x817A": "RTL8188CUS",
            "0x0BDA:0x817B": "RTL8188CUS+BT",
            "0x0BDA:0x817F": "RTL8188RU",
            "0x0BDA:0x818A": "RTL8188CUS (VL)",
            "0x0BDA:0x818B": "RTL8192EU",
            "0x0BDA:0x818C": "RTL8192EU+BT",
            "0x0BDA:0x8192": "RTL8192CU",
            "0x0BDA:0x8194": "RTL8192DU",
            "0x0BDA:0x8197": "RTL8192SE",
            "0x0BDA:0x8198": "RTL8192CU",
            "0x0BDA:0x871B": "RTL8710",
            "0x0BDA:0x8723": "RTL8723AE",
            "0x0BDA:0x8811": "RTL8811AU",
            "0x0BDA:0x8812": "RTL8812AU",
            "0x0BDA:0x8813": "RTL8813AU",
            "0x0BDA:0x8814": "RTL8814AU",
            "0x0BDA:0x881A": "RTL8812AU (VS)",
            "0x0BDA:0x881B": "RTL8812AU (VL)",
            "0x0BDA:0x881C": "RTL8812AU (VN)",
            "0x0BDA:0x8821": "RTL8821AU",
            "0x0BDA:0x8822": "RTL8822BU",
            "0x0BDA:0x8823": "RTL8823BS",
            "0x0BDA:0x8832": "RTL8832AU",
            "0x0BDA:0x8852": "RTL8852BU",
            "0x0BDA:0xA179": "RTL8188EU",
            "0x0BDA:0xB711": "RTL8188GU / RTL8710BU",
            "0x0BDA:0xB720": "RTL8723BU+BT",
            "0x0BDA:0xB812": "RTL8812BU",
            "0x0BDA:0xB814": "RTL8814BU",
            "0x0BDA:0xB81A": "RTL8812BU",
            "0x0BDA:0xB82C": "RTL8822BU+BT",
            "0x0BDA:0xC811": "RTL8811CU",
            "0x0BDA:0xC812": "RTL8812CU",
            "0x0BDA:0xC820": "RTL8821CU+BT",
            "0x0BDA:0xC821": "RTL8821CU",
            "0x0BDA:0xC822": "RTL8822CU",
            "0x0BDA:0xC82B": "RTL8812BU",
            "0x0BDA:0xC82C": "RTL8822CU+BT",
            "0x0BDA:0xF192": "RTL8192FU",
            // ASUS
            "0x0B05:0x17AB": "ASUS USB-N13 (RTL8192CU)",
            "0x0B05:0x17BA": "ASUS USB-N10 (RTL8192CU)",
            "0x0B05:0x17C0": "ASUS USB-N10E (RTL8192CU)",
            "0x0B05:0x17D2": "ASUS USB-AC56 (RTL8812AU)",
            "0x0B05:0x1817": "ASUS USB-AC68 (RTL8814AU)",
            "0x0B05:0x1841": "ASUS USB-AC55 (RTL8812BU)",
            "0x0B05:0x184C": "ASUS USB-AC53 Nano (RTL8812BU)",
            "0x0B05:0x1852": "ASUS USB-AC68 FCC (RTL8814AU)",
            "0x0B05:0x1853": "ASUS USB-AC68 CE (RTL8814AU)",
            "0x0B05:0x1870": "ASUS USB-AC68 (RTL8812BU)",
            "0x0B05:0x1874": "ASUS USB-AC55 B1 (RTL8812BU)",
            "0x0B05:0x18E9": "ASUS USB-AC51 (RTL8811CU)",
            "0x0B05:0x18F0": "ASUS USB-N10 (RTL8188EU)",
            "0x0B05:0x18F1": "ASUS USB-N13 (RTL8192FU)",
            // AboCom
            "0x07B8:0x0811": "AboCom (RTL8811AU)",
            "0x07B8:0x8178": "AboCom (RTL8192CU)",
            "0x07B8:0x8179": "AboCom (RTL8188EU)",
            "0x07B8:0x8189": "AboCom (RTL8192CU)",
            "0x07B8:0x818B": "AboCom (RTL8192EU)",
            "0x07B8:0x8812": "AboCom AC (RTL8812AU)",
            // Actiontec
            "0x1668:0x8105": "Actiontec Single Band (RTL8811AU)",
            "0x1668:0x8108": "Actiontec Dual Band (RTL8811AU)",
            // AirTies
            "0x1EDA:0x2520": "AirTies Air2520 (RTL8811AU)",
            "0x1EDA:0x2525": "AirTies Air2525 (RTL8811AU)",
            // Amigo
            "0x0E0B:0x9071": "Amigo (RTL8192CU)",
            // AzureWave
            "0x13D3:0x3357": "AzureWave AW-CU203 (RTL8192CU)",
            // Belkin
            "0x050D:0x1004": "Belkin F5D8053 (RTL8192CU)",
            "0x050D:0x1102": "Belkin F7D2102 (RTL8192CU)",
            "0x050D:0x1105": "Belkin F7D4101 (RTL8192CU)",
            "0x050D:0x1106": "Belkin F9L1106 v2 (RTL8812AU)",
            "0x050D:0x1109": "Belkin F9L1106 v2 (RTL8812AU)",
            "0x050D:0x110A": "Belkin F7D6102 (RTL8192CU)",
            "0x050D:0x120A": "Belkin F9L1101 (RTL8192CU)",
            "0x050D:0x2102": "Belkin F9L1102 (RTL8192CU)",
            "0x050D:0x2103": "Belkin F9L1103 (RTL8192CU)",
            // Buffalo
            "0x0411:0x0242": "Buffalo WIU-2433DM (RTL8811AU)",
            "0x0411:0x025D": "Buffalo WIU-3866D (RTL8812AU)",
            "0x0411:0x029B": "Buffalo WIU-2433DHP (RTL8811AU)",
            "0x0411:0x029D": "Buffalo WLPU-2433DHP (RTL8811AU)",
            // Chicony
            "0x04F2:0xAFF7": "Chicony (RTL8188CUS)",
            "0x04F2:0xAFF8": "Chicony (RTL8188CUS+BT)",
            "0x04F2:0xAFF9": "Chicony (RTL8188CUS)",
            "0x04F2:0xAFFA": "Chicony (RTL8188CUS)",
            "0x04F2:0xAFFB": "Chicony (RTL8188CUS+BT)",
            "0x04F2:0xAFFC": "Chicony (RTL8188CUS+BT)",
            // Compare
            "0xCDAB:0x8010": "Compare 8010 (RTL8192CU)",
            "0xCDAB:0x8011": "Compare 8011 (RTL8192CU)",
            // Corega
            "0x07AA:0x0056": "Corega (RTL8192CU)",
            // D-Link
            "0x2001:0x3307": "D-Link DWA-132 (RTL8192CU)",
            "0x2001:0x3308": "D-Link DWA-121 (RTL8192CU)",
            "0x2001:0x3309": "D-Link DWA-135 (RTL8192CU)",
            "0x2001:0x330A": "D-Link DWA-133 (RTL8192CU)",
            "0x2001:0x330B": "D-Link DWA-123 (RTL8192CU)",
            "0x2001:0x330D": "D-Link DWA-131 B1 (RTL8192CU)",
            "0x2001:0x330E": "D-Link DWA-183 (RTL8812AU)",
            "0x2001:0x330F": "D-Link DWA-125 (RTL8188EU)",
            "0x2001:0x3310": "D-Link DWA-123 (RTL8188EU)",
            "0x2001:0x3311": "D-Link GO USB N150 (RTL8188EU)",
            "0x2001:0x3312": "D-Link DWA-131 C1 (RTL8192EU)",
            "0x2001:0x3313": "D-Link DWA-182 B1 (RTL8812AU)",
            "0x2001:0x3314": "D-Link DWA-171 (RTL8811AU)",
            "0x2001:0x3315": "D-Link DWA-182 C1 (RTL8812AU)",
            "0x2001:0x3316": "D-Link DWA-180 A1 (RTL8812AU)",
            "0x2001:0x3318": "D-Link DWA-172 (RTL8811AU)",
            "0x2001:0x3319": "D-Link DWA-131 E (RTL8192EU)",
            "0x2001:0x331A": "D-Link DWA-192 (RTL8814AU)",
            "0x2001:0x331B": "D-Link DWA-171 rev C (RTL8188EU)",
            "0x2001:0x331C": "D-Link DWA-181 (RTL8812BU)",
            "0x2001:0x331D": "D-Link DWA-171 rev C (RTL8811CU)",
            "0x2001:0x331E": "D-Link DWA-181 (RTL8812BU)",
            "0x2001:0x331F": "D-Link DWA-181 (RTL8812BU)",
            "0x2001:0x3320": "D-Link DWA-193 (RTL8814AU)",
            "0x2001:0x3322": "D-Link DWA-181 (RTL8812BU)",
            // Edimax
            "0x7392:0x7811": "Edimax EW-7811U (RTL8192CU)",
            "0x7392:0x7822": "Edimax EW-7822U (RTL8192CU)",
            "0x7392:0xA611": "Edimax EW-7611ULB (RTL8723BU+BT)",
            "0x7392:0xA811": "Edimax EW-7811UAC (RTL8811AU)",
            "0x7392:0xA812": "Edimax AC600 (RTL8811AU)",
            "0x7392:0xA813": "Edimax GLP (RTL8811AU)",
            "0x7392:0xA822": "Edimax EW-7822UAC (RTL8812AU)",
            "0x7392:0xA833": "Edimax AC1750 (RTL8814AU)",
            "0x7392:0xA834": "Edimax AC1750 (RTL8814AU)",
            "0x7392:0xB611": "Edimax EW-7611UCB (RTL8821AU+BT)",
            "0x7392:0xB722": "Edimax EW-7722UTn (RTL8192FU)",
            "0x7392:0xB811": "Edimax EW-7811GLN (RTL8188EU)",
            "0x7392:0xB822": "Edimax EW-7822UNC (RTL8812BU)",
            "0x7392:0xC822": "Edimax EW-7822UTC (RTL8812BU)",
            "0x7392:0xD822": "Edimax (RTL8812BU)",
            "0x7392:0xE822": "Edimax (RTL8812BU)",
            "0x7392:0xF822": "Edimax (RTL8812BU)",
            // ELECOM
            "0x056E:0x4007": "ELECOM WDC-433DU2 (RTL8811AU)",
            "0x056E:0x4008": "ELECOM WDC-150SU2M (RTL8188EU)",
            "0x056E:0x4009": "ELECOM WDC-300SU2S (RTL8192CU)",
            "0x056E:0x400B": "ELECOM WDC-1300DU3 (RTL8814AU)",
            "0x056E:0x400D": "ELECOM WDC-1300SU3 (RTL8814AU)",
            "0x056E:0x400E": "ELECOM WDC-433SU2M2 (RTL8811AU)",
            "0x056E:0x400F": "ELECOM WDB-433SU2M (RTL8811AU)",
            "0x056E:0x4010": "ELECOM WDC-433DU2H2 (RTL8811AU)",
            "0x056E:0x4011": "ELECOM WDB-867DU3S (RTL8812BU)",
            // EnGenius
            "0x1740:0x0100": "EnGenius AC (RTL8812AU)",
            // Feixun
            "0x4855:0x0090": "Feixun 90 (RTL8192CU)",
            "0x4855:0x0091": "Feixun 91 (RTL8192CU)",
            // Hawking
            "0x0E66:0x0019": "Hawking HWDN3 (RTL8192CU)",
            "0x0E66:0x0020": "Hawking HWUN4 (RTL8192CU)",
            "0x0E66:0x0022": "Hawking (RTL8812AU)",
            "0x0E66:0x0023": "Hawking HD65U (RTL8811AU)",
            "0x0E66:0x0024": "Hawking HW7ACU (RTL8811AU)",
            "0x0E66:0x0025": "Hawking HW12ACU (RTL8812BU)",
            "0x0E66:0x0026": "Hawking HW17ACU (RTL8814AU)",
            // Hercules
            "0x06F8:0xE033": "Hercules HWUp150 (RTL8192CU)",
            "0x06F8:0xE035": "Hercules HWUm300 (RTL8192CU)",
            // HP
            "0x103C:0x1629": "HP (RTL8192CU)",
            // I-O DATA
            "0x04BB:0x094C": "I-O DATA (RTL8192CU)",
            "0x04BB:0x0952": "I-O DATA WN-AC867U (RTL8812AU)",
            "0x04BB:0x0953": "I-O DATA WN-AC433UA (RTL8811AU)",
            "0x04BB:0x0959": "I-O DATA AC433UM (RTL8811AU)",
            "0x04BB:0x095A": "I-O DATA WHG-AC433UM (RTL8811AU)",
            // InFocus
            "0x058C:0xFF20": "InFocus INA-LCKEY (RTL8812AU)",
            // Linksys
            "0x13B1:0x003F": "Linksys WUSB6300 (RTL8812AU)",
            "0x13B1:0x0043": "Linksys WUSB6400M (RTL8812BU)",
            "0x13B1:0x0045": "Linksys WUSB6300 v2 (RTL8822BU)",
            // LiteON
            "0x04CA:0x8602": "LiteON WN8602L (RTL8812BU)",
            // Logitec
            "0x0789:0x016D": "Logitec (RTL8192CU)",
            "0x0789:0x016E": "Logitec LAN-W866ACU3 (RTL8812AU)",
            // Loopcomm
            "0x148F:0x9097": "Loopcomm ACA1 (RTL8812AU)",
            // NEC
            "0x0409:0x0408": "NEC PA-WL900U (RTL8812AU)",
            // NETSCOUT
            "0x2C2B:0x0002": "NETSCOUT (RTL8814AU)",
            // Netgear
            "0x0846:0x9021": "Netgear WNA3100M (RTL8192CU)",
            "0x0846:0x9041": "Netgear WNA1000M (RTL8192CU)",
            "0x0846:0x9051": "Netgear A6200 v2 (RTL8812AU)",
            "0x0846:0x9052": "Netgear A6100 (RTL8811AU)",
            "0x0846:0x9054": "Netgear A7000 (RTL8814AU)",
            "0x0846:0x9055": "Netgear A6150 (RTL8812BU)",
            "0x0846:0xF001": "Netgear N300MA (RTL8192CU)",
            // NetweeN
            "0x4856:0x0091": "NetweeN 91 (RTL8192CU)",
            // PCI
            "0x2019:0x1201": "PCI BT-Micro3H2X (RTL8192CU)",
            "0x2019:0x4902": "PCI GW USLight (RTL8192CU)",
            "0x2019:0xAB2A": "PCI GW USNano2 (RTL8192CU)",
            "0x2019:0xAB2B": "PCI GW USEco300 (RTL8192CU)",
            "0x2019:0xAB2E": "PCI SW WF02-AD15 (RTL8192CU)",
            "0x2019:0xAB30": "PCI GW-900D (RTL8812AU)",
            "0x2019:0xAB32": "PCI GW-450S (RTL8811AU)",
            "0x2019:0xAB33": "PCI GW-300S (RTL8192EU)",
            "0x2019:0xED17": "PCI GW USValue EZ (RTL8192CU)",
            // Proxim
            "0x08C4:0x0115": "Proxim USB-9100 (RTL8812AU)",
            // Sitecom
            "0x0DF6:0x0052": "Sitecom WL-365 (RTL8192CU)",
            "0x0DF6:0x005C": "Sitecom WLA-1001 v1 (RTL8192CU)",
            "0x0DF6:0x0061": "Sitecom WLA-4001 (RTL8192CU)",
            "0x0DF6:0x0070": "Sitecom WLA-2102 (RTL8192CU)",
            "0x0DF6:0x0074": "Sitecom WLA7100 (RTL8812AU)",
            "0x0DF6:0x0076": "Sitecom WLA1100 (RTL8188EU)",
            "0x0DF6:0x0077": "Sitecom WLA-2100 (RTL8192CU)",
            "0x0DF6:0x007A": "Sitecom WLA2104 (RTL8811AU)",
            "0x0DF6:0x007B": "Sitecom WLA8100 (RTL8814AU)",
            // Tenda
            "0x2604:0x0012": "Tenda (RTL8812AU)",
            // TP-Link
            "0x038B:0x0100": "TP-Link (RTL8192CU)",
            "0x2357:0x0101": "TP-Link Archer T4U (RTL8812AU)",
            "0x2357:0x0103": "TP-Link Archer T4UH (RTL8812AU)",
            "0x2357:0x0106": "TP-Link Archer T9UH v1 (RTL8814AU)",
            "0x2357:0x0107": "TP-Link TL-WN822N v5 (RTL8192EU)",
            "0x2357:0x0108": "TP-Link TL-WN823N v4 (RTL8192EU)",
            "0x2357:0x0109": "TP-Link Archer T2U (RTL8192EU)",
            "0x2357:0x010C": "TP-Link Archer T4U (RTL8188EU)",
            "0x2357:0x010D": "TP-Link Archer T2UH (RTL8812AU)",
            "0x2357:0x010E": "TP-Link Archer T2UH (RTL8812AU)",
            "0x2357:0x010F": "TP-Link Archer T2UH (RTL8812AU)",
            "0x2357:0x0111": "TP-Link (RTL8188EU)",
            "0x2357:0x0112": "TP-Link (RTL8811CU)",
            "0x2357:0x0113": "TP-Link (RTL8811CU)",
            "0x2357:0x0114": "TP-Link (RTL8811CU)",
            "0x2357:0x0115": "TP-Link Archer T2U Plus (RTL8812BU)",
            "0x2357:0x0116": "TP-Link (RTL8812BU)",
            "0x2357:0x0117": "TP-Link (RTL8812BU)",
            "0x2357:0x011E": "TP-Link (RTL8811AU)",
            "0x2357:0x011F": "TP-Link Archer T3U (RTL8811AU)",
            "0x2357:0x0120": "TP-Link (RTL8811AU)",
            "0x2357:0x0121": "TP-Link (RTL8811AU)",
            "0x2357:0x0122": "TP-Link (RTL8812AU)",
            "0x2357:0x0126": "TP-Link (RTL8192EU)",
            "0x2357:0x0127": "TP-Link (RTL8188EU)",
            "0x2357:0x0128": "TP-Link (RTL8811CU)",
            "0x2357:0x0129": "TP-Link (RTL8811CU)",
            "0x2357:0x012A": "TP-Link (RTL8188EU)",
            "0x2357:0x012C": "TP-Link (RTL8811CU)",
            "0x2357:0x012D": "TP-Link (RTL8812BU)",
            "0x2357:0x012E": "TP-Link (RTL8812BU)",
            "0x2357:0x012F": "TP-Link (RTL8188EU)",
            "0x2357:0x0132": "TP-Link (RTL8188EU)",
            "0x2357:0x0138": "TP-Link Archer TX20U (RTL8812BU)",
            // TrendNet
            "0x20F4:0x108A": "TrendNet TBW-108UB (RTL8723BU+BT)",
            "0x20F4:0x624D": "TrendNet TEW-624D (RTL8192CU)",
            "0x20F4:0x648B": "TrendNet TEW-648B (RTL8192CU)",
            "0x20F4:0x648C": "TrendNet TEW-648BBM (RTL8188CU)",
            "0x20F4:0x664B": "TrendNet (RTL8192DU)",
            "0x20F4:0x804B": "TrendNet TEW-804B (RTL8811AU)",
            "0x20F4:0x805A": "TrendNet TEW-805UB (RTL8812BU)",
            "0x20F4:0x805B": "TrendNet TEW-805UB (RTL8812AU)",
            "0x20F4:0x808A": "TrendNet TEW-808UBM (RTL8812BU)",
            "0x20F4:0x809A": "TrendNet TEW-809UB (RTL8814AU)",
            // Western Digital
            "0x1058:0x0632": "Western Digital AC (RTL8812AU)",
            // ZyXEL
            "0x0586:0x341F": "ZyXEL (RTL8192CU)",
            "0x0586:0x3426": "ZyXEL AC (RTL8812AU)",
        ]

        if let name = known[key] {
            rtlog("[chipset] matched: \(key) → \(name)")
            return name
        }

        rtlog("[chipset] NOT found in table: \(key), falling back")

        // Known vendor, unknown product
        let vendorNames: [String: String] = [
            "0x0BDA": "Realtek",
            "0x2357": "TP-Link",
            "0x2001": "D-Link",
            "0x7392": "Edimax",
            "0x0B05": "ASUS",
            "0x0846": "Netgear",
            "0x13B1": "Linksys",
            "0x050D": "Belkin",
            "0x8087": "Intel",
        ]
        let v = vendor.lowercased()
        if let vname = vendorNames[v] {
            return "\(vname) \(product)"
        }

        return "\(vendor) \(product)"
    }

    static let dismissNotification = Notification.Name("com.drogabox.rtlwifitahoe.dismissAbout")
}

// MARK: - NSViewRepresentable to capture the parent NSWindow

private struct PanelWindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { [weak v] in
            onWindow(v?.window)
        }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            onWindow(nsView?.window)
        }
    }
}

// MARK: - Wrapper: Manages an NSPanel lifecycle for the about view

@MainActor
final class AboutPanelController {
    /// Singleton so repeated clicks reuse the existing panel instead of creating duplicates.
    private static let shared = AboutPanelController()

    @MainActor
    static func show(model: WiFiModel) {
        shared._show(model: model)
    }

    private var panel: NSPanel?
    private var dismissDelegate: PanelDismissDelegate?
    private var dismissObserver: Any?

    private func _show(model: WiFiModel) {
        // If already visible, just bring to front
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let content = AboutPanelView(model: model)
        let host = NSHostingController(rootView: content)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 360),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.contentViewController = host

        // Center on screen
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - 130
        let y = screenFrame.midY - 180
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Observe dismiss notification
        dismissObserver = NotificationCenter.default.addObserver(
            forName: AboutPanelView.dismissNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak panel] _ in
            panel?.orderOut(nil)
            self?.panel = nil
            self?.dismissDelegate = nil
            self?.dismissObserver = nil
        }

        dismissDelegate = PanelDismissDelegate { [weak self] in
            if let obs = self?.dismissObserver {
                NotificationCenter.default.removeObserver(obs)
            }
            self?.dismissObserver = nil
            self?.dismissDelegate = nil
            self?.panel = nil
        }
        panel.delegate = dismissDelegate

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }
}

/// Cleans up observers when the panel is closed by the user (e.g. clicking outside).
private final class PanelDismissDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) { onClose() }
}

// MARK: - Previews

// #Preview("About Panel") {
//     let model = WiFiModel.preview()
//     model.snapshot.driverVersion = "1.2.3-rtl"
//     AboutPanelView(model: model)
//         .frame(width: 260, height: 310)
//         .preferredColorScheme(.dark)
// }
