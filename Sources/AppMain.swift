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
    private var customPanel: NSPanel!
    private var model: WiFiModel!
    private var timer: Timer?
    private var sizeObserver: NSObjectProtocol?
    private var eventMonitor: Any?
    private var localEventMonitor: Any?

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

        // --- Custom Floating Panel ---
        let contentRect = NSRect(x: 0, y: 0, width: PanelSize.width, height: PanelSize.minHeight)
        customPanel = NSPanel(contentRect: contentRect,
                              styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                              backing: .buffered,
                              defer: false)
        customPanel.level = .popUpMenu
        customPanel.hasShadow = true
        customPanel.isOpaque = false
        customPanel.backgroundColor = .clear
        
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

        // UI-only tick — WiFiModel owns all IO refresh (avoid double timers / double scans).
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
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
        customPanel.contentViewController = host
    }

    private func applyPopoverSize(_ size: NSSize) {
        let w = PanelSize.width
        let h = min(max(size.height, PanelSize.minHeight), PanelSize.maxHeight)
        let next = NSSize(width: w, height: h)
        let currentFrame = customPanel.frame
        guard abs(currentFrame.height - next.height) > 1 || abs(currentFrame.width - next.width) > 1 else { return }
        
        var newFrame = currentFrame
        newFrame.origin.y = currentFrame.maxY - next.height
        newFrame.size = next
        
        customPanel.setFrame(newFrame, display: true, animate: false)
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
        guard let button = statusItem.button, let window = button.window else { return }

        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if customPanel.isVisible {
            model.setPopoverVisible(false)
            closePanel()
        } else {
            model.setPopoverVisible(true)
            // One light refresh when opening — not every menu-bar tick
            model.refreshLight()
            updateStatusItem()
            // Recreate hosting controller so SwiftUI state is fresh & fast
            installPopoverContent()
            
            let size = NSSize(width: PanelSize.width, height: PanelSize.minHeight)
            let buttonFrame = button.convert(button.bounds, to: nil)
            let windowFrame = window.convertToScreen(buttonFrame)
            let x = windowFrame.midX - (size.width / 2)
            let y = windowFrame.minY - size.height - 4
            customPanel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: true)
            
            customPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            setupEventMonitors()
            
            // Second pass after SwiftUI lays out nearby list / tabs
            DispatchQueue.main.async { [weak self] in
                self?.syncPopoverSizeFromHost()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.syncPopoverSizeFromHost()
            }
        }
    }

    private func syncPopoverSizeFromHost() {
        guard let view = customPanel.contentViewController?.view else { return }
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
    @objc private func quit() { NSApp.terminate(nil) }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func closePanel() {
        customPanel.orderOut(nil)
        removeEventMonitors()
    }

    private func setupEventMonitors() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanelAndUpdateState()
        }
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            if event.window != self.customPanel && event.window != self.statusItem.button?.window {
                self.closePanelAndUpdateState()
            }
            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let localMonitor = localEventMonitor {
            NSEvent.removeMonitor(localMonitor)
            localEventMonitor = nil
        }
    }
    
    private func closePanelAndUpdateState() {
        if customPanel.isVisible {
            model.setPopoverVisible(false)
            closePanel()
        }
    }
}
