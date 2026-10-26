//
//  AssistantTranslatePanel.swift
//  AppLocalizer
//

import SwiftUI

/// The translate sheet with "Your AI assistant · MCP" chosen: AppLocalizer
/// can't start the assistant, so it offers Claude Code's slash command and
/// the same request for any MCP client, then waits. Proposals arrive in the
/// coverage grid tagged with the assistant, and wait in Review & Push.
struct AssistantTranslatePanel: View {
    let prompt: AssistantTranslatePrompt
    /// e.g. "Claude Code", or "your assistant" before one is paired.
    let clientName: String
    let isCopied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("AppLocalizer can’t start your assistant")
                .font(.headline)
            Text("Paste this into \(clientName). Its proposals appear in the coverage grid as they arrive, tagged with who proposed them, and wait for you in Review & Push.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            code(prompt.slashCommand)
                .accessibilityIdentifier("storePage.translate.slashCommand")
            Text("Or, in any MCP client:")
                .font(.caption)
                .foregroundStyle(Palette.label2)
            code(prompt.text)
                .accessibilityIdentifier("storePage.translate.prompt")
            if isCopied {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Copied. Waiting for \(clientName)…")
                        .font(.callout)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("storePage.translate.waiting")
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.translate.assistant")
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
