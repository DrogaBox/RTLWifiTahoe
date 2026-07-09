import Foundation
import Security

/// App Keychain for Wi‑Fi passwords (macOS-native store).
/// Independent from Realtek ProfilesList.plist; both can coexist.
///
/// Service: com.drogabox.rtlwifitahoe.wifi
/// Account: SSID
enum KeychainStore {
    private static let service = "com.drogabox.rtlwifitahoe.wifi"

    static func password(forSSID ssid: String) -> String? {
        let account = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else { return nil }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        let pass = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pass, !pass.isEmpty else { return nil }
        return pass
    }

    @discardableResult
    static func setPassword(_ password: String, forSSID ssid: String) -> Bool {
        let account = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else { return false }
        let pass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pass.isEmpty, let data = pass.data(using: .utf8) else { return false }

        // Update if exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        var status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            add[kSecAttrLabel as String] = "RTL Wi-Fi · \(account)"
            status = SecItemAdd(add as CFDictionary, nil)
        }
        if status == errSecSuccess {
            rtlog("keychain: saved password for \(account)")
            return true
        }
        rtlog("keychain: save failed status=\(status) ssid=\(account)")
        return false
    }

    @discardableResult
    static func deletePassword(forSSID ssid: String) -> Bool {
        let account = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            rtlog("keychain: deleted password for \(account) status=\(status)")
            return true
        }
        rtlog("keychain: delete failed status=\(status)")
        return false
    }

    /// Prefer Keychain, then Realtek ProfilesList.
    static func bestPassword(forSSID ssid: String, supportPath: String) -> String? {
        if let k = password(forSSID: ssid), !k.isEmpty { return k }
        return RealtekProfiles.password(for: ssid, supportPath: supportPath)
    }
}
