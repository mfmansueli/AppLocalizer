//
//  AssistantTranslatePanel.swift
//  AppLocalizer
//

import SwiftUI

/// The translate sheet with "Your AI assistant · MCP" chosen: AppLocalizer
/// can't start the assistant, so it offers Claude Code's slash command and
/// the same request for any MCP client, then waits. Proposals arrive in the
/// coverage grid tagged with the assistant, and wait in Review & Push.
/// Screenshots' caption sheet passes its own command and copy.
struct AssistantTranslatePanel: View {
    /// Claude Code's slash command.
    let slashCommand: String
    /// The same request in words, for any MCP client.
    let request: String
    /// Where the proposals appear.
    let explanation: String
    /// e.g. "Claude Code", or "your assistant" before one is paired.
    let clientName: String
    let isCopied: Bool
    /// The identifiers' prefix: "storePage.translate" for the Store Page.
    let identifierPrefix: String

    /// The Store Page's missing store-page fields.
    init(prompt: AssistantTranslatePrompt, clientName: String, isCopied: Bool) {
        self.init(
            slashCommand: prompt.slashCommand,
            request: prompt.text,
            explanation: String(
                localized: "Paste this into \(clientName). Its proposals appear in the coverage grid as they arrive, tagged with who proposed them, and wait for you in Review & Push."
            ),
            clientName: clientName,
            isCopied: isCopied
        )
    }

    init(slashCommand: String, request: String, explanation: String, clientName: String, isCopied: Bool, identifierPrefix: String = "storePage.translate") {
        self.slashCommand = slashCommand
        self.request = request
        self.explanation = explanation
        self.clientName = clientName
        self.isCopied = isCopied
        self.identifierPrefix = identifierPrefix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("AppLocalizer can’t start your assistant")
                .font(.headline)
            Text(explanation)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            code(slashCommand)
                .accessibilityIdentifier("\(identifierPrefix).slashCommand")
            Text("Or, in any MCP client:")
                .font(.caption)
                .foregroundStyle(Palette.label2)
            code(request)
                .accessibilityIdentifier("\(identifierPrefix).prompt")
            if isCopied {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Copied. Waiting for \(clientName)…")
                        .font(.callout)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("\(identifierPrefix).waiting")
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(identifierPrefix).assistant")
    }

    private func code(_ text: String) -> some View {
        Text(text)
            .font(.callout.monospaced())
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.small)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
    }
}
