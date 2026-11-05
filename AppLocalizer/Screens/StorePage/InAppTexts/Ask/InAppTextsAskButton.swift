//
//  InAppTextsAskButton.swift
//  AppLocalizer
//

import SwiftUI

/// "Ask Claude Code…" on In-App Texts: proposes the missing group,
/// subscription and in-app purchase texts.
struct InAppTextsAskButton: View {
    let app: StoreApp

    var body: some View {
        ClaudeCodeAskButton(
            app: app,
            purpose: InAppTextsAskPrompt.purpose,
            prompt: InAppTextsAskPrompt.text(app: app.name),
            help: { client in String(localized: "Ask \(client) to propose the missing group, subscription and in-app purchase texts") },
            explanation: { client in
                String(localized: """
                \(client) reads \(app.name)’s project and proposes the missing texts. They wait \
                in Review & Push as its proposals; nothing reaches App Store Connect until you push.
                """)
            },
            identifier: "storePage.inAppTexts.ask"
        )
    }
}
