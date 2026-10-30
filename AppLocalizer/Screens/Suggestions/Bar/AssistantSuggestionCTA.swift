//
//  AssistantSuggestionCTA.swift
//  AppLocalizer
//

import SwiftUI

/// Under the suggestion bar before an assistant is connected: what one
/// could suggest here, with Not Now and Set Up Assistant… (Finish Setup…
/// once a token is out).
struct AssistantSuggestionCTA: View {
    let area: SuggestionArea
    let status: AssistantStatus
    let onHide: () -> Void
    let onSetUp: () -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "apple.terminal")
                .font(.title3)
                .foregroundStyle(Palette.machineTranslated)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Not Now", action: onHide)
                .accessibilityIdentifier("suggestions.ctaHide")
            Button(status.setupTitle, action: onSetUp)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("suggestions.ctaSetUp")
        }
        .controlSize(.small)
        .padding(.leading, 14)
        .padding(.trailing, Spacing.medium)
        .padding(.vertical, 11)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("suggestions.cta")
    }

    private var title: String {
        if case let .waiting(client) = status { return String(localized: "Finish connecting \(client)") }
        return String(localized: "Get more suggestions from your own AI assistant")
    }

    private var message: String {
        switch area {
        case .storePage:
            String(localized: """
            Connect Claude Code or another MCP client, or add an API key, and AppLocalizer can suggest What’s New, \
            promotional text and subtitles in every language. You review each one here.
            """)
        case .appInformation:
            String(localized: """
            Connect Claude Code or another MCP client and it can answer these from your code: categories, App Review \
            notes, age rating and accessibility. You review each one here.
            """)
        }
    }
}

#Preview {
    AssistantSuggestionCTA(area: .storePage, status: .notSetUp, onHide: {}, onSetUp: {})
        .padding()
        .frame(width: 760)
}
