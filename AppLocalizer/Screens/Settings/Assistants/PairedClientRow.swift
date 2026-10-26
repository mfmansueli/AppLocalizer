//
//  PairedClientRow.swift
//  AppLocalizer
//

import SwiftUI

/// One paired assistant: its chip, whether it's connected (with a dot that
/// isn't the only cue: the text says it too), the folder it works in, and
/// Revoke, which asks first.
struct PairedClientRow: View {
    let client: MCPPairedClient
    let status: MCPPairedClientStatus
    let onRevoke: () -> Void
    @State private var isConfirmingRevoke = false

    var body: some View {
        HStack(spacing: Spacing.medium) {
            AssistantChip(name: client.name, monogram: client.monogram)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xSmall) {
                    Circle()
                        .fill(status.isConnected ? Palette.positive : Palette.label3)
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)
                    Text(status.text)
                        .font(.callout)
                }
                if let directory = client.workingDirectory {
                    Text(directory)
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.label3)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 0)
            Button(role: .destructive) {
                isConfirmingRevoke = true
            } label: {
                Text("Revoke").foregroundStyle(Palette.danger)
            }
            .controlSize(.small)
            .accessibilityLabel(Text("Revoke \(client.name)"))
            .accessibilityIdentifier("settings.ai.revoke.\(client.kind.rawValue)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.ai.client.\(client.kind.rawValue)")
        .confirmationDialog(
            Text("Revoke \(client.name)?"),
            isPresented: $isConfirmingRevoke
        ) {
            Button("Revoke", role: .destructive, action: onRevoke)
        } message: {
            Text("It’s disconnected now and its token stops working. Its proposals stay in Review & Push.")
        }
    }
}
