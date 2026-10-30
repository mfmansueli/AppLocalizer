//
//  AskAssistantPopover.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// After "Ask Claude Code…": AppLocalizer can't start the assistant, so the
/// prompt is on the clipboard to paste into it. The popover waits for the
/// first suggestion, then the streaming banner takes over.
struct AskAssistantPopover: View {
    let request: AssistantSuggestionRequest
    let onCopyAgain: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask \(request.client)")
                .font(.headline)
            Text("AppLocalizer can’t start your assistant. Paste this into \(request.client); its suggestions show up here as it sends them.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            Text(request.prompt)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityIdentifier("ask.prompt")
            HStack(spacing: Spacing.small) {
                Text("Copied to the clipboard.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Copy Again", action: onCopyAgain)
                    .controlSize(.small)
                    .accessibilityIdentifier("ask.copyAgain")
            }
            Text("Shortcut in Claude Code: \(Text(MCPPrompt.suggest.slashCommand).font(.caption2.monospaced())) is the same prompt, offered by AppLocalizer’s server.")
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.small) {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for \(request.client)…")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Cancel", action: onCancel)
                    .controlSize(.small)
                    .accessibilityIdentifier("ask.cancel")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, Spacing.small)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .accessibilityElement(children: .contain)
        }
        .padding(Spacing.large)
        .frame(width: 420)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ask.popover")
    }
}

#Preview {
    AskAssistantPopover(
        request: AssistantSuggestionRequest(
            appID: "1",
            area: .storePage,
            client: "Claude Code",
            prompt: SuggestionPrompt.text(for: .storePage, app: "Lumen", version: "1.4", primaryLanguage: "English"),
            startedAt: .now
        ),
        onCopyAgain: {},
        onCancel: {}
    )
}
