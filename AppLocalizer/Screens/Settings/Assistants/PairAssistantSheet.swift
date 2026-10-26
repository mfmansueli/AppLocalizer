//
//  PairAssistantSheet.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// "Pair an assistant": pick the client, copy the snippet carrying a token
/// made for it alone (or read out the pairing code), and watch it connect.
/// Cancel before it connects throws the token away.
struct PairAssistantSheet: View {
    @Environment(MCPServerController.self) private var server
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let pairing = server.pendingPairing {
                content(pairing)
                    .padding(Spacing.xLarge)
                Divider()
                footer(pairing)
                    .padding(.horizontal, Spacing.xLarge)
                    .padding(.vertical, Spacing.medium)
            }
        }
        .frame(width: 600)
        .accessibilityIdentifier("settings.ai.pairSheet")
    }

    private func content(_ pairing: MCPPendingPairing) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Pair an assistant")
                    .font(.title2.weight(.semibold))
                Text("AppLocalizer makes a token for this assistant only. Paste the command into the assistant; it connects the next time it starts.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            FittingSegmentedPicker(
                label: String(localized: "Assistant"),
                options: MCPClientKind.allCases.map { ($0, $0.pickerTitle) },
                selection: Binding(get: { pairing.kind }, set: { server.choosePairingKind($0) })
            )
            .fixedSize()
            .disabled(pairing.isConnected)
            .accessibilityIdentifier("settings.ai.pairKind")
            Text(pairing.kind.setupLocation)
                .font(.callout)
                .foregroundStyle(Palette.label2)
            snippet(pairing)
            code(pairing)
            connection(pairing)
        }
    }

    private func snippet(_ pairing: MCPPendingPairing) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Text(server.pairingSnippet ?? "")
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.medium)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityIdentifier("settings.ai.pairSnippet")
            Button {
                copy(pairing)
            } label: {
                Label(pairing.isWaiting ? "Copied" : "Copy", systemImage: "doc.on.doc")
            }
            .controlSize(.small)
            .accessibilityIdentifier("settings.ai.pairCopy")
        }
    }

    private func code(_ pairing: MCPPendingPairing) -> some View {
        HStack(spacing: Spacing.medium) {
            Text(pairing.code.formatted)
                .font(.body.monospacedDigit())
                .tracking(1.5)
                .textSelection(.enabled)
                .accessibilityLabel(Text("Pairing code \(pairing.code.digits.map(String.init).joined(separator: " "))"))
            Text("Pairing code, if the assistant asks for one instead. It expires in 10 minutes if no one uses it.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings.ai.pairCode")
    }

    @ViewBuilder
    private func connection(_ pairing: MCPPendingPairing) -> some View {
        if let client = pairing.connectedClient {
            HStack(spacing: Spacing.small) {
                AssistantChip(name: client.name, monogram: client.monogram)
                Text(connectedText(client))
                    .font(.callout)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settings.ai.pairConnected")
        } else if pairing.isWaiting {
            HStack(spacing: Spacing.small) {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for \(pairing.kind.title) to connect…")
                    .font(.callout)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settings.ai.pairWaiting")
        }
    }

    private func footer(_ pairing: MCPPendingPairing) -> some View {
        HStack {
            Spacer()
            if pairing.isConnected {
                Button("Done") {
                    server.finishPairing()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("settings.ai.pairDone")
            } else {
                Button("Cancel") {
                    server.cancelPairing()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("settings.ai.pairCancel")
            }
        }
    }

    private func connectedText(_ client: MCPPairedClient) -> String {
        if let directory = client.workingDirectory {
            return String(localized: "Connected from \(directory). It can read and propose now.")
        }
        return String(localized: "Connected. It can read and propose now.")
    }

    private func copy(_: MCPPendingPairing) {
        guard let snippet = server.pairingSnippet else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet, forType: .string)
        server.markPairingCopied()
    }
}
