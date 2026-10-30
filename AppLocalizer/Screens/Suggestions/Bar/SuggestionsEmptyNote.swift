//
//  SuggestionsEmptyNote.swift
//  AppLocalizer
//

import SwiftUI

/// "No suggestions for Japanese": the built-in checks found nothing, and
/// the assistant (when connected) or the API key (on a Store Page) hasn't
/// suggested anything here.
struct SuggestionsEmptyNote: View {
    /// "Japanese" or "App Review".
    let scopeTitle: String
    let area: SuggestionArea
    let status: AssistantStatus

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundStyle(Palette.label3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("No suggestions for \(scopeTitle)")
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, 14)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("suggestions.empty")
    }

    private var message: String {
        if case let .ready(client) = status, area == .storePage {
            return String(localized: """
            Built-in checks found nothing to change, and \(client) hasn’t suggested anything for this language. Generate \
            suggestions if you’d like a second look.
            """)
        }
        guard case let .connected(client) = status else { return String(localized: "Built-in checks found nothing to change here.") }
        return area == .storePage
            ? String(localized: "Built-in checks found nothing to change, and \(client) hasn’t suggested anything for this language. Ask it if you’d like a second look.")
            : String(localized: "Built-in checks found nothing to change, and \(client) hasn’t suggested anything for this page. Ask it if you’d like a second look.")
    }
}

#Preview {
    SuggestionsEmptyNote(scopeTitle: "Japanese", area: .storePage, status: .connected(client: "Claude Code"))
        .padding()
        .frame(width: 700)
}
