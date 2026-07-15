// UNUSED — types are inline in WiFiModel.swift
import Foundation
@preconcurrency import Security

// MARK: - Certificate status for Enterprise 802.1X

/// Describes the status of an enterprise certificate (CA or client).
struct CertStatus: Equatable {
    let label: String       // e.g. "CA Cert", "Client Cert"
    let path: String        // file path from profile1x.rtl
    let expires: Date?      // nil = could not parse
    let expired: Bool
    let daysLeft: Int
    let error: String?      // non-nil if load failed entirely
}

/// Loads and inspects enterprise certificates referenced in profile1x.rtl
/// and stored in the Keychain. Mirrors StatusBarApp's `WiFiPasswordEncrypt`
/// certificate inspection methods (`certificateContentFromCerFile:`,
/// `checkCertificateExpire:`, `certificateFromKeychain`).
enum EnterpriseCertStore {

    /// Inspect all certificates referenced in the current profile1x.rtl.
    /// Returns a sorted list: CA cert first, then client cert, then private key.
    static func inspect(supportPath: String) -> [CertStatus] {
        let entries = parseProfile1x(supportPath: supportPath)
        guard !entries.isEmpty else { return [] }

        var results: [CertStatus] = []

        for entry in entries {
            // CA Certificate
            if let caPath = entry["ca_cert"] as? String, !caPath.isEmpty {
                let status = inspectFile(at: caPath, label: "CA Cert")
                results.append(status)
            }

            // Client Certificate
            if let clientPath = entry["client_cert"] as? String, !clientPath.isEmpty {
                let status = inspectFile(at: clientPath, label: "Client Cert")
                results.append(status)
            }

            // Private Key (check expiry of associated cert in .p12/.pfx)
            if let keyPath = entry["private_key"] as? String, !keyPath.isEmpty {
                let status = inspectPrivateKey(at: keyPath)
                results.append(status)
            }
        }

        // Also scan Keychain for any identity certificates that might be relevant
        let keychainCerts = inspectKeychainIdentities()
        results.append(contentsOf: keychainCerts)

        return results
    }

    /// Read and parse profile1x.rtl into individual network={…} blocks,
    /// extracting key=value pairs per block.
    private static func parseProfile1x(supportPath: String) -> [[String: Any]] {
        let path = supportPath + "/profile1x.rtl"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Find all network={…} blocks (brace-balanced)
        var blocks: [String] = []
        var search = text.startIndex
        while search < text.endIndex,
              let start = text.range(of: "network={", range: search..<text.endIndex) {
            var depth = 0
            var i = start.lowerBound
            var end = text.endIndex
            while i < text.endIndex {
                let ch = text[i]
                if ch == "{" { depth += 1 }
                else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        end = text.index(after: i)
                        break
                    }
                }
                i = text.index(after: i)
            }
            blocks.append(String(text[start.lowerBound..<end]))
            search = end
        }

        // Parse each block into a dictionary
        var entries: [[String: Any]] = []
        for block in blocks {
            var dict: [String: Any] = [:]
            for line in block.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard let eqIdx = trimmed.firstIndex(of: "=") else { continue }
                let key = String(trimmed[..<eqIdx]).trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[trimmed.index(after: eqIdx)...])
                    .trimmingCharacters(in: .whitespaces)
                // Strip surrounding quotes
                if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                    value = String(value.dropFirst().dropLast())
                }
                guard !key.isEmpty else { continue }
                dict[key] = value
            }
            if !dict.isEmpty {
                entries.append(dict)
            }
        }
        return entries
    }

    /// Inspect a certificate file on disk (.cer, .pem, .der).
    /// Uses Security framework to load and parse the certificate, then check expiry.
    private static func inspectFile(at path: String, label: String) -> CertStatus {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return CertStatus(label: label, path: path, expires: nil,
                              expired: false, daysLeft: 0, error: "File not found")
        }

        // Try loading as DER/PEM certificate
        guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            // PEM often has headers — try stripping them
            if let pemStr = String(data: data, encoding: .utf8),
               let derData = derFromPEM(pemStr),
               let cert2 = SecCertificateCreateWithData(nil, derData as CFData) {
                return certificateStatus(cert: cert2, label: label, path: path)
            }
            return CertStatus(label: label, path: path, expires: nil,
                              expired: false, daysLeft: 0, error: "Could not parse certificate")
        }

        return certificateStatus(cert: cert, label: label, path: path)
    }

    /// Inspect a private key file (.p12/.pfx) — we can't easily check expiry
    /// without the passphrase, so we note the file exists.
    private static func inspectPrivateKey(at path: String) -> CertStatus {
        let url = URL(fileURLWithPath: path)
        let exists = FileManager.default.fileExists(atPath: path)
        if !exists {
            return CertStatus(label: "Private Key", path: path, expires: nil,
                              expired: false, daysLeft: 0, error: "File not found")
        }
        // .p12/.pfx can't be checked without passphrase — report file exists
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let mod = attrs[.modificationDate] as? Date {
            let days = Calendar.current.dateComponents([.day], from: mod, to: Date()).day ?? 0
            return CertStatus(label: "Private Key", path: path, expires: mod,
                              expired: false, daysLeft: 0,
                              error: days > 365 ? "File may be old (\(days) days)" : nil)
        }
        return CertStatus(label: "Private Key", path: path, expires: nil,
                          expired: false, daysLeft: 0, error: nil)
    }

    /// Scan the Keychain for identity certificates (SecIdentityRef) that may
    /// be used for 802.1X. Returns any certificates with their expiry info.
    private static func inspectKeychainIdentities() -> [CertStatus] {
        var results: [CertStatus] = []

        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        guard status == errSecSuccess, let identities = items as? [SecIdentity] else {
            return results
        }

        for identity in identities {
            var certRef: SecCertificate?
            SecIdentityCopyCertificate(identity, &certRef)
            guard let cert = certRef else { continue }
            guard let summary = SecCertificateCopySubjectSummary(cert) as String?,
                  !summary.isEmpty else { continue }

            // Check expiry
            if let values = SecCertificateCopyValues(cert, [kSecOIDInvalidityDate as String] as CFArray, nil) as? [String: Any],
               let invalidity = values[kSecOIDInvalidityDate as String] as? [String: Any],
               let dateValue = invalidity["value"] as? CFAbsoluteTime {
                let expires = Date(timeIntervalSinceReferenceDate: dateValue)
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                let expired = daysLeft <= 0

                results.append(CertStatus(
                    label: "Keychain: \(summary.prefix(32))",
                    path: "(Keychain)",
                    expires: expires,
                    expired: expired,
                    daysLeft: max(daysLeft, 0),
                    error: expired ? "EXPIRED" : (daysLeft < 30 ? "Expires soon" : nil)
                ))
            } else {
                // No invalidity date = check not possible
                results.append(CertStatus(
                    label: "Keychain: \(summary.prefix(32))",
                    path: "(Keychain)",
                    expires: nil,
                    expired: false,
                    daysLeft: 0,
                    error: "No expiry info"
                ))
            }
        }
        return results
    }

    // MARK: - Helpers

    private static func certificateStatus(cert: SecCertificate, label: String, path: String) -> CertStatus {
        // Read invalidity date (notAfter) from the certificate
        if let values = SecCertificateCopyValues(cert, [kSecOIDInvalidityDate as String] as CFArray, nil) as? [String: Any],
           let invalidity = values[kSecOIDInvalidityDate as String] as? [String: Any],
           let dateValue = invalidity["value"] as? CFAbsoluteTime {
            let expires = Date(timeIntervalSinceReferenceDate: dateValue)
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
            let expired = daysLeft <= 0

            return CertStatus(
                label: label,
                path: path,
                expires: expires,
                expired: expired,
                daysLeft: max(daysLeft, 0),
                error: expired ? "EXPIRED" : (daysLeft < 30 ? "Expires in \(daysLeft)d" : nil)
            )
        }

        // Try invalidity date as a date string
        if let values = SecCertificateCopyValues(cert, [kSecOIDInvalidityDate as String] as CFArray, nil) as? [String: Any],
           let invalidity = values[kSecOIDInvalidityDate as String] as? [String: Any],
           let dateStr = invalidity["value"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let expires = formatter.date(from: dateStr) {
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                let expired = daysLeft <= 0
                return CertStatus(
                    label: label,
                    path: path,
                    expires: expires,
                    expired: expired,
                    daysLeft: max(daysLeft, 0),
                    error: expired ? "EXPIRED" : (daysLeft < 30 ? "Expires in \(daysLeft)d" : nil)
                )
            }
        }

        return CertStatus(label: label, path: path, expires: nil,
                          expired: false, daysLeft: 0, error: "No expiry date")
    }

    /// Strip PEM headers and return raw DER data.
    private static func derFromPEM(_ pem: String) -> Data? {
        var lines = pem.components(separatedBy: "\n")
        // Remove header/footer lines
        lines = lines.filter { !$0.hasPrefix("-----BEGIN") && !$0.hasPrefix("-----END") }
        let b64 = lines.joined()
        return Data(base64Encoded: b64)
    }

    /// Format a date for display.
    static func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
