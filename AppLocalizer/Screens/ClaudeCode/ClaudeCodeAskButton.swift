//
//  ClaudeCodeAskButton.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// "Ask Claude Code…" for one screen's job, e.g. In-App Texts' missing
/// texts or Pricing's subscriptions: starts Claude Code (once its helper is
/// saved) with `prompt`, or copies the prompt to paste. The popover shows
/// the run or the prompt; the proposals arrive in the screen and in Review
/// & Push.
struct ClaudeCodeAskButton: View {
    let app: StoreApp
    /// Names the run, so the button finds its own.
    let purpose: ClaudeCodeRunPurpose
    let prompt: String
    /// The button's tooltip: "Ask Claude Code to …".
    let help: (_ client: String) -> String
    /// The popover's line while the run goes: "Claude Code reads … and proposes …".
    let explanation: (_ client: String) -> String
    /// `storePage.inAppTexts.ask`; the popover and prompt add `.popover` and `.prompt`.
    let identifier: String

    @Environment(ClaudeCodeLauncher.self) private var launcher
    @Environment(MCPServerController.self) private var assistants
    @State private var isPresented = false
    @State private var askedAt: Date?
    @State private var copied = false

    private var client: String {
        assistants.sessions.first?.displayName ?? MCPClientKind.claudeCode.title
    }

    /// The run this button started, once it did.
    private var run: ClaudeCodeRun? {
        guard let askedAt else { return nil }
        return launcher.latestRun(appID: app.id, purpose: purpose, since: askedAt)
    }

    var body: some View {
        Button(action: ask) {
            Label("Ask \(client)…", systemImage: "sparkles")
        }
        .help(Text(help(client)))
        .popover(isPresented: $isPresented, arrowEdge: .bottom) { popover }
        .accessibilityIdentifier(identifier)
    }

    private func ask() {
        isPresented = true
        if let run, run.isActive { return }
        askedAt = .now
        copied = false
        let prompt = prompt
        let purpose = purpose
        Task {
            guard await launcher.start(purpose, appID: app.id, appName: app.name, prompt: prompt) == nil else { return }
            copy()
        }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        copied = true
    }

    // MARK: - Popover

    private var popover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask \(client)")
                .font(.headline)
            if let run {
                Text(explanation(client))
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                ClaudeCodeRunStatusView(run: run, onShowOutput: {
                    isPresented = false
                    launcher.shownRunID = run.id
                }, onDismiss: { isPresented = false })
            } else if copied {
                Text("AppLocalizer can’t start your assistant. Paste this into \(client); its proposals show up here and in Review & Push.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(prompt)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                    .accessibilityIdentifier(identifier + ".prompt")
                HStack(spacing: Spacing.small) {
                    Text("Copied to the clipboard.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Copy Again", action: copy)
                        .controlSize(.small)
                }
                ClaudeCodeLaunchHint(client: client)
            } else {
                HStack(spacing: Spacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Starting \(client)…")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
            }
        }
        .padding(Spacing.large)
        .frame(width: 420)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier + ".popover")
    }
}
