//
//  RetentionServerSetupButton.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// Set Up with Claude Code…: opens Claude Code in the app's project, in the
/// person's terminal, with the Retention Messaging API setup prompt, so
/// they approve each step. AppLocalizer itself never calls their server
/// or Apple's server APIs. When Claude Code can't be opened, the prompt is
/// copied instead.
struct RetentionServerSetupButton: View {
    let app: StoreApp

    @Environment(ClaudeCodeLauncher.self) private var launcher
    @State private var copied = false

    var body: some View {
        Button("Set Up with Claude Code…", action: setUp)
            .help("Claude Code adds the endpoint to your server and runs Apple’s sandbox test; you approve each step")
            .accessibilityIdentifier("retention.server.setUp")
            .popover(isPresented: $copied, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Prompt copied")
                        .font(.headline)
                    Text("AppLocalizer couldn’t open Claude Code. Paste the prompt into Claude Code in your server’s project.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.large)
                .frame(width: 320)
            }
    }

    private func setUp() {
        let prompt = RetentionAskPrompts.server(app: app.name)
        let folder = launcher.projectFolder(for: app.id) ?? launcher.chooseProjectFolder(for: app.id, appName: app.name)
        if let folder, ClaudeCodeDeepLink.open(folder: folder, prompt: prompt) { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        copied = true
    }
}
