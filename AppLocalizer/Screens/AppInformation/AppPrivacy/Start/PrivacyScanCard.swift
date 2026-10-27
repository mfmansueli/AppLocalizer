//
//  PrivacyScanCard.swift
//  AppLocalizer
//

import SwiftUI

/// "Scan with an assistant": what the assistant reads, whether one is
/// connected, how to connect Claude Code when none is, and the prompt to
/// paste. AppLocalizer can't start the assistant itself.
struct PrivacyScanCard: View {
    let viewModel: AppPrivacyViewModel
    @Environment(MCPServerController.self) private var assistants

    var body: some View {
        let session = assistants.sessions.first
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Scan with an assistant")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.small)
                if let session {
                    AssistantChip(name: session.displayName)
                } else {
                    AssistantChip(name: String(localized: "Not connected"), monogram: "CC")
                }
            }
            Text("Your assistant runs in \(viewModel.appShortName)’s repository and reads it: privacy manifests, dependencies, Info.plist, entitlements and code that sends data off the device. It proposes answers with evidence; you review each one here.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            PrivacyAssistantStatusLine(session: session, isEnabled: assistants.isEnabled, appName: viewModel.appShortName)
            if session == nil {
                step(String(localized: "1 · Connect Claude Code, in \(viewModel.appShortName)’s folder"))
                PrivacyCopyableBlock(text: connectCommand, buttonTitle: String(localized: "Copy"), isProminent: false, id: "connectCommand") {
                    copyConnectCommand()
                }
                step(String(localized: "2 · Then paste this prompt"))
            }
            PrivacyCopyableBlock(text: viewModel.scanPrompt, buttonTitle: String(localized: "Copy Prompt"), isProminent: true, id: "prompt") {
                viewModel.copyPrompt()
            }
            if viewModel.isWaitingForScan {
                HStack(spacing: Spacing.small) {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                    Text("Copied. Waiting for \(session?.displayName ?? MCPClientKind.claudeCode.title) to start the scan…")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("appInformation.appPrivacy.waiting")
            }
        }
        .padding(Spacing.large)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.scanCard")
    }

    private func step(_ title: String) -> some View {
        Text(title)
            .font(.callout.weight(.semibold))
    }

    /// The pairing command, with the token shortened until Copy makes one.
    private var connectCommand: String {
        if let pairing = assistants.pendingPairing, pairing.kind == .claudeCode {
            return MCPClientKind.claudeCode.setupSnippet(token: MCPAccessToken.abbreviated(pairing.token), url: assistants.url, bridgePath: "")
        }
        return MCPClientKind.claudeCode.setupSnippet(token: MCPAccessToken.prefix + "…", url: assistants.url, bridgePath: "")
    }

    /// Copy: a pairing for Claude Code (its own token), the full command on
    /// the pasteboard, and the server waits for it as the Settings sheet does.
    private func copyConnectCommand() {
        if assistants.pendingPairing?.kind != .claudeCode {
            assistants.beginPairing(kind: .claudeCode)
        }
        guard let snippet = assistants.pairingSnippet else { return }
        viewModel.copyCommand(snippet)
        assistants.markPairingCopied()
    }
}
