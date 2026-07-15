// UNUSED — types are inline in WiFiModel.swift
import Foundation
import ServiceManagement

// MARK: - Login item

enum LoginItemHelper {
    static let label = "com.drogabox.rtlwifitahoe"
    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                    rtlog("login: registered via SMAppService")
                } else {
                    try service.unregister()
                    rtlog("login: unregistered via SMAppService")
                }
                return
            } catch {
                rtlog("login: SMAppService failed: \(error.localizedDescription)")
                fallbackLaunchctl(enabled: enabled)
            }
        } else {
            fallbackLaunchctl(enabled: enabled)
        }
    }

    private static func fallbackLaunchctl(enabled: Bool) {
        let fm = FileManager.default
        if enabled {
            let exe = Bundle.main.bundleURL.path
            let dict: [String: Any] = [
                "Label": label,
                "ProgramArguments": ["/usr/bin/open", "-a", exe],
                "RunAtLoad": true
            ]
            let url = plistURL
            try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
                try? data.write(to: url)
            }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            p.arguments = ["load", "-w", url.path]
            try? p.run()
        } else {
            let url = plistURL
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            p.arguments = ["unload", "-w", url.path]
            try? p.run()
            try? fm.removeItem(at: url)
        }
    }
}
