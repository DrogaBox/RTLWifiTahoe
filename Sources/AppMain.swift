import SwiftUI
import AppKit

@main
struct RTLWifiTahoeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No MenuBarExtra — classic NSStatusItem is reliable on all setups
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var model: WiFiModel!
    private var timer: Timer?
    private var sizeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model = WiFiModel.shared

        // --- Status item (always visible) ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let img = NSImage(systemSymbolName: "wifi", accessibilityDescription: "RTL Wi‑Fi")
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            button.image = img?.withSymbolConfiguration(config)
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // --- Popover panel (height auto-grows downward with content) ---
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: PanelSize.width, height: PanelSize.minHeight)
        installPopoverContent()

        sizeObserver = NotificationCenter.default.addObserver(
            forName: .rtlPopoverNeedsSize,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let size = note.userInfo?["size"] as? NSSize else { return }
            Task { @MainActor in
                self.applyPopoverSize(size)
            }
        }

        updateStatusItem()

        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.model.refreshLight()
                self?.updateStatusItem()
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }

        // Only purge classic utility when the user opted in (Pro toggle or first-launch dialog)
        if model.hideClassicUtility {
            model.purgeClassicUtility()
        }

        // First-launch: ask whether to replace StatusBarApp (P2-5)
        if !UserDefaults.standard.bool(forKey: "classic_app_prompt_shown") {
            UserDefaults.standard.set(true, forKey: "classic_app_prompt_shown")
            // Defer so status item is ready before modal
            DispatchQueue.main.async { [weak self] in
                self?.askAboutClassicUtility()
            }
        }
    }

    private func askAboutClassicUtility() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Replace Realtek StatusBarApp?")
        alert.informativeText = String(localized: """
            RTL Wi-Fi Tahoe can replace the classic Realtek StatusBarApp for day-to-day Wi-Fi management. \
            If you accept, Tahoe will quit StatusBarApp and prevent it from launching at login. \
            You can change this later under Settings.
            """)
        alert.alertStyle = .informational
        alert.addButton(withTitle: String(localized: "Replace StatusBarApp"))
        alert.addButton(withTitle: String(localized: "Keep Both"))
        let res = alert.runModal()
        if res == .alertFirstButtonReturn {
            model.hideClassicUtility = true
            model.purgeClassicUtility()
        }
    }

    private func installPopoverContent() {
        let root = PopoverView(model: model)
            .frame(width: PanelSize.width)
        let host = NSHostingController(rootView: root)
        // Let SwiftUI report intrinsic height so the popover can grow
        if #available(macOS 13.0, *) {
            host.sizingOptions = [.intrinsicContentSize]
        }
        popover.contentViewController = host
    }

    private func applyPopoverSize(_ size: NSSize) {
        let w = PanelSize.width
        let h = min(max(size.height, PanelSize.minHeight), PanelSize.maxHeight)
        let next = NSSize(width: w, height: h)
        guard abs(popover.contentSize.height - next.height) > 1
                || abs(popover.contentSize.width - next.width) > 1 else { return }
        popover.contentSize = next
        if let host = popover.contentViewController {
            host.preferredContentSize = next
            host.view.setFrameSize(next)
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        let level = model.snapshot.signalLevel
        let symbol = level.menuBarSymbol
        let base = NSImage(systemSymbolName: symbol, accessibilityDescription: level.label)
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.image = base?.withSymbolConfiguration(config)
        button.image?.isTemplate = true

        let t = model.menuBarTitle
        button.title = t.isEmpty ? "" : " \(t)"

        if level == .none {
            button.toolTip = L10n.MenuBar.disconnectedTip
        } else {
            var parts: [String] = [L10n.App.name, level.label]
            if model.snapshot.signalPercent > 0 {
                parts.append("\(model.snapshot.signalPercent)%")
            }
            if model.snapshot.linkMbps > 0 {
                parts.append(String(format: "%.0f Mbps", model.snapshot.linkMbps))
            }
            if model.snapshot.channel > 0 {
                parts.append("Ch \(model.snapshot.channel)")
            }
            let ssid = model.snapshot.ssid
            if !ssid.isEmpty, ssid != "—" { parts.append(ssid) }
            button.toolTip = parts.joined(separator: " · ")
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            model.refreshLight()
            updateStatusItem()
            // Recreate hosting controller so SwiftUI state is fresh & fast
            installPopoverContent()
            popover.contentSize = NSSize(width: PanelSize.width, height: PanelSize.minHeight)
            // preferredEdge .minY → popover opens / grows downward from the menu bar
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
            // Second pass after SwiftUI lays out nearby list / tabs
            DispatchQueue.main.async { [weak self] in
                self?.syncPopoverSizeFromHost()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.syncPopoverSizeFromHost()
            }
        }
    }

    private func syncPopoverSizeFromHost() {
        guard let view = popover.contentViewController?.view else { return }
        var fit = view.fittingSize
        if fit.height < 1 {
            fit = view.intrinsicContentSize
        }
        if fit.height < 1 {
            fit = NSSize(width: PanelSize.width, height: PanelSize.minHeight)
        }
        applyPopoverSize(NSSize(width: PanelSize.width, height: fit.height))
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: L10n.App.refresh, action: #selector(refresh), keyEquivalent: "r")
        menu.addItem(withTitle: L10n.App.copyIP, action: #selector(copyIP), keyEquivalent: "c")
        if model.snapshot.ip != "—" {
            menu.addItem(withTitle: L10n.App.disconnect, action: #selector(disconnect), keyEquivalent: "d")
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: L10n.App.about, action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: L10n.App.quit, action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in self?.statusItem.menu = nil }
    }

    @objc private func refresh() {
        model.refreshNow()
        updateStatusItem()
    }
    @objc private func copyIP() { model.copyIP() }
    @objc private func disconnect() { model.disconnectNetwork() }
    @objc private func showAbout() { model.showAbout() }
    @objc private func quit() { NSApp.terminate(nil) }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
