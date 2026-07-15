import SwiftUI
import AppKit

// MARK: - Profiles

struct ProfilesTab: View {
    @ObservedObject var model: WiFiModel
    @Binding var showJoin: Bool
    @State private var confirmForget: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Profiles.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Tahoe.subtext)
                .padding(.horizontal, 12)

            if model.profiles.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 22))
                        .foregroundColor(Tahoe.subtext)
                    Text(L10n.Profiles.empty)
                        .font(.system(size: 11))
                        .foregroundColor(Tahoe.subtext)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 6) {
                    ForEach(model.profiles) { p in
                        HStack(spacing: 8) {
                            Button {
                                showJoin = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: p.isDefault ? "star.fill" : "wifi")
                                        .font(.system(size: 12))
                                        .foregroundColor(p.isDefault ? Tahoe.accentOrange : Tahoe.accentCyan)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(p.ssid)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Tahoe.text)
                                            .lineLimit(1)
                                        Text(p.hasPassword ? L10n.Profiles.withPassword : L10n.Profiles.open)
                                            .font(.system(size: 9))
                                            .foregroundColor(Tahoe.subtext)
                                    }
                                    Spacer(minLength: 4)
                                    if p.isDefault {
                                        Text(L10n.Profiles.last)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Tahoe.accentOrange)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                confirmForget = p.ssid
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Tahoe.accentRed)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Tahoe.accentRed.opacity(0.15)))
                            }
                            .buttonStyle(.plain)
                            .help(L10n.tr("profiles.forget_help", p.ssid))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Tahoe.card)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tahoe.cardBorder, lineWidth: 1))
                        )
                    }
                }
                .padding(.horizontal, 12)
            }

            // DNS presets live under Profiles
            DNSSectionView(model: model)
                .padding(.horizontal, 12)

            HStack(spacing: 6) {
                ActionButton(title: L10n.App.join, icon: "plus.circle", accent: Tahoe.accentGreen) {
                    showJoin = true
                }
                ActionButton(title: L10n.Profiles.folder, icon: "folder", accent: Tahoe.accentCyan) {
                    model.revealProfilesFolder()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .confirmationDialog(
            L10n.Profiles.forgetTitle,
            isPresented: Binding(
                get: { confirmForget != nil },
                set: { if !$0 { confirmForget = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let ssid = confirmForget {
                Button(L10n.tr("profiles.forget_action", ssid), role: .destructive) {
                    model.forgetNetwork(ssid: ssid)
                    confirmForget = nil
                }
                Button(L10n.Profiles.cancel, role: .cancel) {
                    confirmForget = nil
                }
            }
        } message: {
            Text(L10n.Profiles.forgetMessage)
        }
    }
}


