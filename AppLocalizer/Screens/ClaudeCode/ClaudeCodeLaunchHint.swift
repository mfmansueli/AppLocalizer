//
//  ClaudeCodeLaunchHint.swift
//  AppLocalizer
//

import SwiftUI

/// Under a copied prompt for Claude Code, while the helper isn't saved:
/// one line offering to skip the paste next time. Set Up… opens the Save
/// panel for the helper straight away.
struct ClaudeCodeLaunchHint: View {
    /// The assistant the prompt was copied for; only Claude Code can be
    /// started.
    let client: String

    @Environment(ClaudeCodeLauncher.self) private var launcher

    var body: some View {
        if shows {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "bolt.horizontal.circle")
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                    Text("Skip the paste: let AppLocalizer start Claude Code.")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Set Up…") { Task { await launcher.installHelper() } }
                        .controlSize(.small)
                        .accessibilityIdentifier("claudeCode.hint.setUp")
                }
                if let error = launcher.installError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("claudeCode.hint")
        }
    }

    private var shows: Bool {
        guard client == MCPClientKind.claudeCode.title, launcher.helperURL != nil else { return false }
        return switch launcher.helper {
        case .notInstalled, .outdated, .failed: true
        case .unknown, .checking, .ready, .claudeMissing: false
        }
    }
}
