// UNUSED — types are inline in WiFiModel.swift
import SwiftUI
import AppKit

// MARK: - Enterprise 802.1X fields

/// Reusable view for Enterprise 802.1X EAP configuration fields.
/// Shown in JoinPanel when the user selects WPA-Enterprise or WPA2-Enterprise.
struct EnterpriseFieldsView: View {
    @Binding var joinOpts: JoinOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // EAP method picker
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.EAP.method)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                Picker("", selection: $joinOpts.eapMethod) {
                    ForEach(EAPMethod.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
            }

            // Identity (username) field
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.EAP.identity)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                TextField("user@domain.com", text: $joinOpts.eapIdentity)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(fieldBG)
                    .foregroundColor(Tahoe.text)
                    .font(.system(size: 12, design: .monospaced))
                    .autocorrectionDisabled()
            }

            // Password (for PEAP, TTLS, LEAP)
            if joinOpts.eapMethod.needsPassword {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.EAP.password)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Tahoe.subtext)
                    SecureField(L10n.EAP.password, text: $joinOpts.eapPassword)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(fieldBG)
                        .foregroundColor(Tahoe.text)
                        .font(.system(size: 12))
                }
            }

            // CA Certificate (for TLS, TTLS)
            if joinOpts.eapMethod.needsCACert {
                certField(
                    label: L10n.EAP.caCert,
                    path: $joinOpts.eapCACert
                )
            }

            // Client Certificate (for TLS only)
            if joinOpts.eapMethod.needsClientCert {
                certField(
                    label: L10n.EAP.clientCert,
                    path: $joinOpts.eapClientCert
                )
                certField(
                    label: L10n.EAP.privateKey,
                    path: $joinOpts.eapPrivateKey
                )
                if !joinOpts.eapPrivateKey.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.EAP.privateKeyPassword)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Tahoe.subtext)
                        SecureField(L10n.EAP.privateKeyPassword, text: $joinOpts.eapPrivateKeyPassword)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(fieldBG)
                            .foregroundColor(Tahoe.text)
                            .font(.system(size: 12))
                    }
                }
            }

            if joinOpts.eapMethod == .tls {
                Text(L10n.EAP.tls)
                    .font(.system(size: 9))
                    .foregroundColor(Tahoe.accentOrange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// A reusable certificate file picker field.
    private func certField(label: String, path: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Tahoe.subtext)
            HStack(spacing: 4) {
                TextField("", text: path)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Tahoe.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button(L10n.EAP.selectCert) {
                    selectCertFile(path: path)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Tahoe.accentCyan)
            }
            .padding(8)
            .background(fieldBG)
        }
    }

    /// Present an NSOpenPanel to select a certificate file.
    private func selectCertFile(path: Binding<String>) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.pem, .cer, .certificate, .x509Certificate]
        // Add DER, P12, PFX
        panel.allowsOtherFileTypes = true

        if panel.runModal() == .OK, let url = panel.url {
            path.wrappedValue = url.path
        }
    }

    private var fieldBG: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Tahoe.cardElevated)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
    }
}
