import SwiftUI
import AppKit

// MARK: - DNS section (Profiles tab)

struct DNSSectionView: View {
    @ObservedObject var model: WiFiModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(L10n.DNS.title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Tahoe.subtext)
                    .tracking(0.4)
                if model.dnsBusy {
                    ProgressView().controlSize(.mini)
                } else if model.snapshot.dnsIsAutomatic {
                    Text(L10n.DNS.dhcp)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Tahoe.accentCyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Tahoe.accentCyan.opacity(0.15)))
                } else if let p = model.snapshot.matchedDNSPreset, p != .automatic {
                    Text(p.shortLabel)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Tahoe.accentPurple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Tahoe.accentPurple.opacity(0.15)))
                }
                Spacer(minLength: 0)
            }

            Text(model.snapshot.dnsDisplay)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Tahoe.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            let columns = [GridItem(.adaptive(minimum: 72), spacing: 5)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
                ForEach(DNSPreset.allCases) { preset in
                    let on = model.selectedDNSPreset == preset
                    Button {
                        model.applyDNSPreset(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(preset.shortLabel)
                                .font(.system(size: 10, weight: .bold))
                            Text(preset == .automatic ? "DHCP" : (preset.servers.first ?? ""))
                                .font(.system(size: 8, design: .monospaced))
                                .opacity(0.85)
                        }
                        .foregroundColor(on ? Color.black.opacity(0.85) : Tahoe.subtext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(on ? Tahoe.accentPurple : Tahoe.cardElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(on ? Color.clear : Tahoe.cardBorder, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(model.dnsBusy
                              || (model.snapshot.networkServiceName.isEmpty && model.snapshot.bsdName.isEmpty))
                    .help(preset.label + " — " + preset.detail)
                }
            }

            if let msg = model.dnsStatusMessage {
                Text(msg)
                    .font(.system(size: 9))
                    .foregroundColor(msg.hasPrefix("DNS →") || msg.hasPrefix("OK")
                                     ? Tahoe.accentGreen : Tahoe.accentOrange)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Tahoe.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tahoe.cardBorder, lineWidth: 1))
        )
    }
}
