//
//  AskAssistantPopover.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// After "Ask Claude Code…". With the helper saved, AppLocalizer started
/// Claude Code itself: the popover shows what it's doing, with Show Output
/// and Stop, and closing it doesn't stop it. Otherwise the prompt is on the
/// clipboard to paste into the assistant, with a line offering to skip the
/// paste next time. Either way it waits for the first suggestion, then the
/// streaming banner takes over.
struct AskAssistantPopover: View {
    let request: AssistantSuggestionRequest
    let onCopyAgain: () -> Void
    let onCancel: () -> Void

    @Environment(ClaudeCodeLauncher.self) private var launcher
    @Environment(\.dismiss) private var dismiss
    @State private var showsPrompt = false
    @State private var copiedPrompt = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask \(request.client)")
                .font(.headline)
            if let run {
                started(run)
            } else {
                copied
            }
        }
        .padding(Spacing.large)
        .frame(width: 420)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ask.popover")
    }

    /// The run AppLocalizer started for this request.
    private var run: ClaudeCodeRun? {
        launcher.latestRun(appID: request.appID, purpose: .ask(area: request.area.title), since: request.startedAt)
    }

    // MARK: - Started

    private func started(_ run: ClaudeCodeRun) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if run.isActive {
                activeNote(run)
            }
            ClaudeCodeRunStatusView(run: run, onShowOutput: {
                dismiss()
                launcher.shownRunID = run.id
            }, onDismiss: onCancel)
            DisclosureGroup(isExpanded: $showsPrompt) {
                promptText
                    .padding(.top, Spacing.xSmall)
            } label: {
                HStack(spacing: Spacing.small) {
                    Text("Prompt")
                        .font(.callout.weight(.medium))
                    if !showsPrompt {
                        Text(request.prompt)
                            .font(.caption.monospaced())
                            .foregroundStyle(Palette.label2)
                            .lineLimit(1)
                    }
                }
            }
            .accessibilityIdentifier("ask.promptDisclosure")
            // A failure has its own Copy Prompt.
            if run.isActive {
                HStack(spacing: Spacing.small) {
                    Text("Closing this doesn’t stop it.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(copiedPrompt ? String(localized: "Copied") : String(localized: "Copy Prompt")) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(request.prompt, forType: .string)
                        copiedPrompt = true
                    }
                    .controlSize(.small)
                    .accessibilityIdentifier("ask.copyPrompt")
                }
            }
        }
    }

    private func activeNote(_ run: ClaudeCodeRun) -> some View {
        Text("""
        \(request.client) is reading \(run.appName) and suggesting \(request.area.title) fields. Suggestions show up here \
        as they arrive; nothing changes until you accept them.
        """)
        .font(.callout)
        .foregroundStyle(Palette.label2)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Copied

    private var copied: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AppLocalizer can’t start your assistant. Paste this into \(request.client); its suggestions show up here as it sends them.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            promptText
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
            ClaudeCodeLaunchHint(client: request.client)
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
    }

    private var promptText: some View {
        Text(request.prompt)
            .font(.callout.monospaced())
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
    }
}

#if DEBUG
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
    .environment(ClaudeCodeLauncher(
        assistants: MCPServerController(server: DebugHTTPServer(), secrets: InMemorySecretStore()),
        runner: DebugUnixScriptRunner(helperExists: false)
    ))
}
#endif
