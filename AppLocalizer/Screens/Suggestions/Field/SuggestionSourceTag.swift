//
//  SuggestionSourceTag.swift
//  AppLocalizer
//

import SwiftUI

/// Who suggested a value, outlined and neutral: "AL Built-in", "CC Claude
/// Code", "AP AI provider". Purple is for the "Suggested" pill, not this.
struct SuggestionSourceTag: View {
    let source: SuggestionSource

    var body: some View {
        HStack(spacing: Spacing.xxSmall) {
            AssistantMonogram(letters: source.monogram)
            Text(source.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(.leading, 2)
        .padding(.trailing, Spacing.xSmall)
        .frame(height: 18)
        .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(source.title))
    }
}

#Preview {
    HStack {
        SuggestionSourceTag(source: .builtIn)
        SuggestionSourceTag(source: .assistant(client: "Claude Code"))
        SuggestionSourceTag(source: .aiProvider)
    }
    .padding()
}
