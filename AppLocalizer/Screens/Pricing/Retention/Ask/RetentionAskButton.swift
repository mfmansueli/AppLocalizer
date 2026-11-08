//
//  RetentionAskButton.swift
//  AppLocalizer
//

import SwiftUI

/// Retention's ask buttons: Claude Code (or the connected assistant) runs
/// the prompt and its proposals come back over MCP.
struct RetentionAskButton: View {
    let app: StoreApp
    let kind: RetentionAskKind

    var body: some View {
        ClaudeCodeAskButton(
            app: app,
            purpose: RetentionAskPrompts.purpose,
            prompt: kind.prompt(app: app.name),
            help: { kind.help(client: $0, app: app.name) },
            explanation: { kind.explanation(client: $0, app: app.name) },
            identifier: kind.identifier,
            title: { kind.title(client: $0) }
        )
    }
}
