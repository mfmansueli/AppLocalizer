//
//  AssistantSetupSnippetStep.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// Step 3, "Add to assistant": the command or configuration to copy, with
/// a token made for that client. For Claude Code it first asks how it
/// should reach AppLocalizer: AppLocalizer starts it (install the helper
/// once, then the project folder), or a command run in Terminal.
struct AssistantSetupSnippetStep: View {
    let viewModel: AssistantSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.offersLaunch {
                choice
            }
            if viewModel.launches, let launcher = viewModel.launcher {
                AssistantSetupLaunchStep(viewModel: viewModel, launcher: launcher)
            } else {
                snippet
            }
        }
    }

    private var choice: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("How should Claude Code reach AppLocalizer?")
                .font(.headline)
            AssistantSetupOptionRow(
                title: String(localized: "AppLocalizer starts Claude Code"),
                detail: String(localized: """
                No Terminal and nothing to paste. Save a small helper once; when you ask, AppLocalizer runs your Claude Code \
                in the app’s project folder, with its own token for that run, and shows what it does.
                """),
                badge: String(localized: "Recommended"),
                isSelected: viewModel.launches
            ) {
                viewModel.chooseLaunch(true)
            }
            .accessibilityIdentifier("assistantSetup.launch.start")
            AssistantSetupOptionRow(
                title: String(localized: "Run a command in Terminal"),
                detail: String(localized: "Add AppLocalizer to Claude Code yourself, then paste each prompt into it."),
                isSelected: !viewModel.launches
            ) {
                viewModel.chooseLaunch(false)
            }
            .accessibilityIdentifier("assistantSetup.launch.terminal")
        }
    }

    private var snippet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.kind.setupIntro)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.snippet ?? "")
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityIdentifier("assistantSetup.snippet")
            HStack(spacing: Spacing.small) {
                Button {
                    if let snippet = viewModel.copySnippet() {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(snippet, forType: .string)
                    }
                } label: {
                    Label(viewModel.hasCopiedSnippet ? String(localized: "Copied") : viewModel.kind.copyTitle, systemImage: "doc.on.doc")
                }
                .accessibilityIdentifier("assistantSetup.copy")
                Text("Includes a new token just for \(viewModel.kind.title).")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .controlSize(.small)
            InlineMessage(text: viewModel.kind.setupNote, systemImage: "info.circle", tint: Palette.label2)
                .font(.caption)
        }
    }
}
