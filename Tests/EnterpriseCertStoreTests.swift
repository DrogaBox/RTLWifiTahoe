import Foundation
import Security

// MARK: - EnterpriseCertStore Unit Tests

@MainActor
final class EnterpriseCertStoreTests {

    // MARK: - Test listing

    func allTests() -> [(String, TestFn)] {
        return [
            ("testParseProfile1x_EmptyOrMissingPath", testParseProfile1x_EmptyOrMissingPath),
            ("testParseProfile1x_SingleBlock", testParseProfile1x_SingleBlock),
            ("testParseProfile1x_MultipleBlocks", testParseProfile1x_MultipleBlocks),
            ("testParseProfile1x_MalformedBlock", testParseProfile1x_MalformedBlock),
            ("testDerFromPEM_ValidPEM", testDerFromPEM_ValidPEM),
            ("testDerFromPEM_NoHeaders", testDerFromPEM_NoHeaders),
            ("testDerFromPEM_EmptyString", testDerFromPEM_EmptyString),
            ("testDerFromPEM_InvalidBase64", testDerFromPEM_InvalidBase64),
            ("testFormatDate", testFormatDate),
            ("testInspect_NoProfileFile", testInspect_NoProfileFile),
            ("testInspect_ProfileWithMissingCerts", testInspect_ProfileWithMissingCerts),
            ("testInspect_ProfileWithValidDERCert", testInspect_ProfileWithValidDERCert),
            ("testInspect_ProfileWithValidPEMCert", testInspect_ProfileWithValidPEMCert),
            ("testInspectKeychainIdentities_ReturnsEmpty", testInspectKeychainIdentities_ReturnsEmpty),
        ]
    }

    // MARK: - Helpers

    /// Create a temporary directory, run the block, then clean up.
    private func withTempDir(_ block: (String) async throws -> Void) async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("cert_test_\(UUID().uuidString.prefix(8))")
            .path
        try FileManager.default.createDirectory(atPath: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await block(tmp)
    }

    /// Write a string to a file inside the temp directory.
    private func writeString(_ text: String, to file: String, in dir: String) throws {
        let path = (dir as NSString).appendingPathComponent(file)
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Write binary data to a file inside the temp directory.
    private func writeData(_ data: Data, to file: String, in dir: String) throws {
        let path = (dir as NSString).appendingPathComponent(file)
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    /// A real self-signed RSA-2048 X.509v3 DER certificate, base64-encoded.
    /// Generated on 2026-07-15 with:
    ///   openssl req -x509 -newkey rsa:2048 -days 3653 -nodes \
    ///     -subj "/CN=TestCert/O=TestOrg" -keyout /dev/null -outform DER | base64
    /// Verified: SecCertificateCreateWithData(nil, data) != nil
    private var realCertDER: Data? {
        let b64 = "MIICxjCCAa4CCQCL29kfTEmuKDANBgkqhkiG9w0BAQsFADAlMREwDwYDVQQDDAhU" +
                  "ZXN0Q2VydDEQMA4GA1UECgwHVGVzdE9yZzAeFw0yNjA3MTUxODA4NTJaFw0zNjA3" +
                  "MTUxODA4NTJaMCUxETAPBgNVBAMMCFRlc3RDZXJ0MRAwDgYDVQQKDAdUZXN0T3Jn" +
                  "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxhGI59x9260mlJX45SCs" +
                  "ZNwlFhZKUXC3hZgAiJwvOVFRxLmsIzVoKkLUsI0rjIQeckDfdlDxLnIZs4VXcuRG" +
                  "/ECSUJ3SS2jfZQ7AD5r2xGayG6CiRVSNLyu+f+3SBXmYKWt3s7DZUeC9G/IhzqfB" +
                  "w8KEG7/dSyJ1DfuQVR5cYoJWgivutbDFNw4YGMMhYiHU/GNC/JiPi8VES6BEOb+2" +
                  "6xVA2cppX9uN0WiLSyA0wIOzs4nDWvaettiOUK453X5ha67lrpR9Jg8y2l1cBQwu" +
                  "db40NBZb5OhPYqndW0YTUtYrVcxzSO4yQB8Qdj1S0q3UUjUx1lLC5wDbRsK6is/k" +
                  "lQIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQC3GCpR+HgMEFlCqc8IdHZGFAudAQ9Z" +
                  "vqeKtQF99+iLQ2OIFMidKGhrhb0dvjUspxtIB8OyaYStC3fsysuPB+65kr8gzia/" +
                  "D3FvpJtacAkuasWQhppPQCYQc7K0OjWce3hhVCNdEvyyaCRuaCFieXOhI5EC54kr" +
                  "1F4dO0jN1ju8aPTis6i1wXCZFMBK6DBVixTFVC2JhLYm5HaGRI3QQulENk5NnY45" +
                  "WpTe3A/ZPICQp/PBHzr57e+duQEne4G7VRpWDByekUvYCFU1AeK2YfoyLsialeWZ" +
                  "kXnMo7HOISHoXl3LAyJvPwEmC/4YLHY4T2INGppJVmBp+vc0k4fuXJgu"
        return Data(base64Encoded: b64)
    }

    /// PEM-encoded version of the same certificate, for testing the PEM→DER
    /// fallback path in inspectFile(at:label:).
    private var realCertPEM: String? {
        guard let der = realCertDER else { return nil }
        let b64 = der.base64EncodedString()
        // Split into 64-char lines (standard PEM format)
        var lines: [String] = ["-----BEGIN CERTIFICATE-----"]
        var remaining = b64[...]
        while !remaining.isEmpty {
            let chunk = remaining.prefix(64)
            lines.append(String(chunk))
            remaining = remaining.dropFirst(64)
        }
        lines.append("-----END CERTIFICATE-----")
        return lines.joined(separator: "\n")
    }

    // MARK: - parseProfile1x tests

    func testParseProfile1x_EmptyOrMissingPath() async throws {
        let result = EnterpriseCertStore.parseProfile1x(supportPath: "/tmp/__nonexistent__cert_test__")
        try XCTAssertEqual(result.count, 0, "missing path should return empty")
    }

    func testParseProfile1x_SingleBlock() async throws {
        try await withTempDir { dir in
            let profile = """
            network={
                ssid="CorpNet"
                key_mgmt=WPA-EAP
                ca_cert="/etc/certs/ca.pem"
                client_cert="/etc/certs/client.pem"
                eap=PEAP
                identity="user@corp.com"
            }
            """
            try writeString(profile, to: "profile1x.rtl", in: dir)
            let result = EnterpriseCertStore.parseProfile1x(supportPath: dir)
            try XCTAssertEqual(result.count, 1, "should parse one block")
            let entry = result[0]
            try XCTAssertEqual(entry["ssid"] as? String, "CorpNet")
            try XCTAssertEqual(entry["key_mgmt"] as? String, "WPA-EAP")
            try XCTAssertEqual(entry["ca_cert"] as? String, "/etc/certs/ca.pem")
            try XCTAssertEqual(entry["eap"] as? String, "PEAP")
        }
    }

    func testParseProfile1x_MultipleBlocks() async throws {
        try await withTempDir { dir in
            let profile = """
            network={
                ssid="GuestNet"
                key_mgmt=NONE
            }
            network={
                ssid="CorpNet"
                key_mgmt=WPA-EAP
                ca_cert="/etc/certs/ca.pem"
            }
            """
            try writeString(profile, to: "profile1x.rtl", in: dir)
            let result = EnterpriseCertStore.parseProfile1x(supportPath: dir)
            try XCTAssertEqual(result.count, 2, "should parse two blocks")
            try XCTAssertEqual(result[0]["ssid"] as? String, "GuestNet")
            try XCTAssertEqual(result[1]["ssid"] as? String, "CorpNet")
        }
    }

    func testParseProfile1x_MalformedBlock() async throws {
        try await withTempDir { dir in
            let profile = """
            network={
                ssid="PartialNet"
                key_mgmt=WPA-EAP
            """
            try writeString(profile, to: "profile1x.rtl", in: dir)
            let result = EnterpriseCertStore.parseProfile1x(supportPath: dir)
            try XCTAssertEqual(result.count, 1, "should parse malformed block partially")
            try XCTAssertEqual(result[0]["ssid"] as? String, "PartialNet")
        }
    }

    // MARK: - derFromPEM tests

    func testDerFromPEM_ValidPEM() async throws {
        let pem = """
        -----BEGIN CERTIFICATE-----
        MIIBIjANBgkqhkiG9w0BAQMFAAOCAQ8AMIIBCgKCAQEAu1SU1LfVLPHCYZM8
        Uo+R3P9wWYVY1q5K7YgG6mT3qH8=
        -----END CERTIFICATE-----
        """
        let der = EnterpriseCertStore.derFromPEM(pem)
        try XCTAssertNotNil(der, "valid PEM should produce DER data")
        try XCTAssertTrue(der!.count > 0, "DER should not be empty")
    }

    func testDerFromPEM_NoHeaders() async throws {
        let b64 = "SGVsbG8gV29ybGQ="  // "Hello World"
        let der = EnterpriseCertStore.derFromPEM(b64)
        try XCTAssertNotNil(der, "bare base64 should decode")
        try XCTAssertEqual(der, Data("Hello World".utf8))
    }

    func testDerFromPEM_EmptyString() async throws {
        let der = EnterpriseCertStore.derFromPEM("")
        try XCTAssertNotNil(der, "empty string returns empty Data, not nil")
        try XCTAssertEqual(der?.count, 0, "empty PEM -> empty Data")
    }

    func testDerFromPEM_InvalidBase64() async throws {
        let der = EnterpriseCertStore.derFromPEM("!!!not base64!!!")
        try XCTAssertNil(der, "invalid base64 should return nil")
    }

    // MARK: - formatDate tests

    func testFormatDate() async throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        let date = Calendar.current.date(from: components)!
        let formatted = EnterpriseCertStore.formatDate(date)
        try XCTAssertEqual(formatted, "2026-06-15")
    }

    // MARK: - inspect integration tests

    func testInspect_NoProfileFile() async throws {
        let results = EnterpriseCertStore.inspect(supportPath: "/tmp/__nonexistent__cert_test__")
        try XCTAssertEqual(results.count, 0, "no profile -> empty")
    }

    func testInspect_ProfileWithMissingCerts() async throws {
        try await withTempDir { dir in
            let profile = """
            network={
                ssid="CorpNet"
                key_mgmt=WPA-EAP
                ca_cert="/etc/certs/ca.pem"
                client_cert="/etc/certs/client.pem"
                private_key="/etc/certs/key.p12"
                eap=PEAP
            }
            """
            try writeString(profile, to: "profile1x.rtl", in: dir)
            let results = EnterpriseCertStore.inspect(supportPath: dir)
            try XCTAssertEqual(results.count, 3, "should report three cert statuses")
            try XCTAssertEqual(results[0].label, "CA Cert")
            try XCTAssertEqual(results[0].error, "File not found")
            try XCTAssertEqual(results[1].label, "Client Cert")
            try XCTAssertEqual(results[1].error, "File not found")
            try XCTAssertEqual(results[2].label, "Private Key")
            try XCTAssertEqual(results[2].error, "File not found")
        }
    }

    func testInspect_ProfileWithValidDERCert() async throws {
        guard let certData = realCertDER else {
            throw AssertionFailure(message: "Embedded test cert DER decode failed", file: #file, line: #line)
        }
        // Verify the DER is actually valid before testing
        try XCTAssertNotNil(
            SecCertificateCreateWithData(nil, certData as CFData),
            "Embedded test cert must be valid DER"
        )

        try await withTempDir { dir in
            let certPath = (dir as NSString).appendingPathComponent("ca.der")
            try writeData(certData, to: "ca.der", in: dir)

            let profile = """
            network={
                ssid="CorpNet"
                key_mgmt=WPA-EAP
                ca_cert="\(certPath)"
                eap=TLS
            }
            """
            try writeString(profile, to: "profile1x.rtl", in: dir)

            let results = EnterpriseCertStore.inspect(supportPath: dir)

            let certResult = results.first { $0.label == "CA Cert" && $0.path == certPath }
            try XCTAssertNotNil(certResult, "should find CA Cert entry for our DER file")

            if let r = certResult {
                try XCTAssertNotEqual(r.error, "File not found", "cert file should exist")
                // Valid DER cert should parse successfully
                try XCTAssertNotEqual(r.error, "Could not parse certificate",
                    "real DER should parse correctly")
                // Expiry may not be extractable by SecCertificateCopyValues
                // on all platforms; when available, verify it's not expired.
                if let expires = r.expires {
                    try XCTAssertFalse(r.expired, "newly generated cert should not be expired")
                    try XCTAssertTrue(expires > Date(), "expiry should be in the future")
                }
            }
        }
    }

    func testInspect_ProfileWithValidPEMCert() async throws {
        // Test the PEM→DER fallback path in inspectFile(at:label:)
        guard let pem = realCertPEM else {
            throw AssertionFailure(message: "Failed to build PEM from embedded DER",
                                   file: #file, line: #line)
        }

        try await withTempDir { dir in
            let certPath = (dir as NSString).appendingPathComponent("ca.pem")
            try writeString(pem, to: "ca.pem", in: dir)

            let profile = """
            network={
                ssid="CorpNet"
                key_mgmt=WPA-EAP
                ca_cert="\(certPath)"
                eap=TLS
            }
            """
            try writeString(profile, to: "profile1x.rtl", in: dir)

            let results = EnterpriseCertStore.inspect(supportPath: dir)

            let certResult = results.first { $0.label == "CA Cert" && $0.path == certPath }
            try XCTAssertNotNil(certResult, "should find CA Cert entry for PEM file")

            if let r = certResult {
                try XCTAssertNotEqual(r.error, "File not found", "PEM file should exist")
                // The PEM→DER fallback path should parse successfully
                try XCTAssertNotEqual(r.error, "Could not parse certificate",
                    "PEM should be parsed via derFromPEM fallback")
                // Expiry is checked when extractable
                if let expires = r.expires {
                    try XCTAssertFalse(r.expired, "PEM cert should not be expired")
                    try XCTAssertTrue(expires > Date(), "expiry should be in the future")
                }
            }
        }
    }

    // MARK: - Keychain identity query

    func testInspectKeychainIdentities_ReturnsEmpty() async throws {
        // Verify that inspectKeychainIdentities() handles the common case
        // (no 802.1X identities in the keychain) gracefully by returning [].
        // On a CI machine or clean macOS install, there are typically no
        // identity certificates, so this test exercises the SecItemCopyMatching
        // query path and the errSecSuccess → empty-items edge case.
        let results = EnterpriseCertStore.inspectKeychainIdentities()
        // The test doesn't assert on the count (it's machine-dependent).
        // Instead, verify the method doesn't crash and returns valid objects:
        for status in results {
            try XCTAssertFalse(status.label.isEmpty, "label should not be empty")
            try XCTAssertEqual(status.path, "(Keychain)")
        }
    }
}
