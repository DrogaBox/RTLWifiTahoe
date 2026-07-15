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

    var body: some View {
        ZStack {
            PanelBackground()

            VStack(spacing: 10) {
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

                // ── Driver ──
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
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Tahoe.card)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Tahoe.cardBorder, lineWidth: 1))
                )

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
        .frame(width: 260, height: 310)
        .clipShape(RoundedRectangle(cornerRadius: ThemeStore.shared.palette.cornerRadius))
        .preferredColorScheme(.dark)
        .task {
            contributors = await GitHubContributors.fetch()
            contributorsLoading = false
        }
    }

    static let dismissNotification = Notification.Name("com.drogabox.rtlwifitahoe.dismissAbout")
}

// MARK: - Wrapper: Manages an NSPanel lifecycle for the about view

@MainActor
final class AboutPanelController {
    private var panel: NSPanel?
    /// Strong reference kept until the panel closes so NSWindow's weak delegate doesn't dangle.
    private var dismissDelegate: PanelDismissDelegate?
    private var dismissObserver: Any?

    func show(model: WiFiModel) {
        // If already visible, just bring to front
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let content = AboutPanelView(model: model)
        let host = NSHostingController(rootView: content)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 310),
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
            let y = screenFrame.midY - 130
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
