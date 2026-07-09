import Foundation
import UserNotifications

/// Thin wrapper around UserNotifications (macOS native banners).
@MainActor
enum AppNotify {
    private static var requested = false

    static func requestAuthorizationIfNeeded() {
        guard !requested else { return }
        requested = true
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { ok, err in
            if let err {
                rtlog("notify: auth error \(err.localizedDescription)")
            } else {
                rtlog("notify: auth \(ok ? "granted" : "denied")")
            }
        }
    }

    static func post(title: String, body: String, id: String = UUID().uuidString) {
        guard WiFiModel.shared.showNotifications else { return }
        requestAuthorizationIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: "rtlwifi.\(id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { err in
            if let err {
                rtlog("notify: deliver failed \(err.localizedDescription)")
            }
        }
    }

    static func connected(ssid: String, ip: String) {
        post(
            title: L10n.tr("notify.connected_title"),
            body: L10n.tr("notify.connected_body", ssid, ip),
            id: "connected.\(ssid)"
        )
    }

    static func disconnected(ssid: String?) {
        let body: String
        if let ssid, !ssid.isEmpty, ssid != "—" {
            body = L10n.tr("notify.disconnected_body_ssid", ssid)
        } else {
            body = L10n.tr("notify.disconnected_body")
        }
        post(title: L10n.tr("notify.disconnected_title"), body: body, id: "disconnected")
    }

    static func reconnecting(ssid: String) {
        post(
            title: L10n.tr("notify.reconnecting_title"),
            body: L10n.tr("notify.reconnecting_body", ssid),
            id: "reconnect.\(ssid)"
        )
    }
}
