//
//  SavedKeyRow.swift
//  AppLocalizer
//

import SwiftUI

/// One saved key in Settings → Account: the team, "In use", issuer and key
/// IDs, what the last check found (role and connection), and Test
/// Connection and Remove….
struct SavedKeyRow: View {
    let credentials: AppStoreConnectCredentials
    let account: TeamAccount
    let isInUse: Bool
    let isTesting: Bool
    let check: KeyAccessCheck?
    let failure: KeyCheckFailure?
    let onTest: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            InitialsTile(initials: account.initials, size: 30)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xSmall) {
                    Text(account.name)
                        .font(.headline)
                    if isInUse {
                        Pill(text: String(localized: "In use"))
                            .accessibilityIdentifier("settings.inUse")
                    }
                }
                Group {
                    Text(verbatim: "Issuer \(credentials.issuerID)")
                    Text("Key \(credentials.keyID) · \(account.role)")
                }
                .font(.caption.monospaced())
                .foregroundStyle(Palette.label2)
                .textSelection(.enabled)
                status
                    .padding(.top, 2)
            }
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.xSmall) {
                Button("Test Connection", action: onTest)
                    .disabled(isTesting)
                    .accessibilityIdentifier("settings.test.\(credentials.keyID)")
                Button(role: .destructive, action: onRemove) {
                    Text("Remove…")
                        .foregroundStyle(Palette.danger)
                }
                .accessibilityIdentifier("settings.remove.\(credentials.keyID)")
            }
            .controlSize(.small)
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.key.\(credentials.keyID)")
    }

    @ViewBuilder
    private var status: some View {
        if isTesting {
            HStack(spacing: Spacing.xSmall) {
                ProgressView()
                    .controlSize(.mini)
                Text("Testing the connection…")
            }
            .font(.caption)
            .foregroundStyle(Palette.label2)
        } else if let failure {
            statusLine(failure.title, systemImage: "xmark.circle", tint: Palette.danger)
                .help(failure.message)
                .accessibilityIdentifier("settings.failure.\(credentials.keyID)")
        } else if let check {
            VStack(alignment: .leading, spacing: 3) {
                statusLine(
                    check.salesSummary,
                    systemImage: check.salesAccess == .readable ? "checkmark" : "exclamationmark.triangle",
                    tint: check.salesAccess == .readable ? Palette.label : Palette.warningMark
                )
                statusLine(check.connectionSummary, systemImage: "checkmark", tint: Palette.label2, isSecondary: true)
                    .accessibilityIdentifier("settings.connection.\(credentials.keyID)")
            }
        } else {
            Text("Not checked yet. Test Connection shows what this key can do.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
    }

    private func statusLine(_ text: String, systemImage: String, tint: Color, isSecondary: Bool = false) -> some View {
        Label {
            Text(text)
                .foregroundStyle(isSecondary ? Palette.label2 : Palette.label)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .font(.caption)
    }
}
