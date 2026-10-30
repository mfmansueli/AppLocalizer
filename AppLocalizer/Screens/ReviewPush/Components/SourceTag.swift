//
//  SourceTag.swift
//  AppLocalizer
//

import SwiftUI

/// Who made a change, at the end of a review row. Assistants and accepted
/// field suggestions get an outlined capsule with their monogram ("Proposed
/// by Claude Code", "AL Built-in"); the rest a quiet label. Neutral on purpose: purple is for unreviewed text, not for this.
struct SourceTag: View {
    let source: ChangeSource

    var body: some View {
        if let monogram = source.monogram {
            HStack(spacing: Spacing.xxSmall) {
                AssistantMonogram(letters: monogram)
                Text(source.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.leading, 3)
            .padding(.trailing, Spacing.xSmall)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(source.isAssistant ? "Proposed by \(source.title)" : "Suggested by \(source.title)"))
        } else {
            Text(source.title)
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        SourceTag(source: .assistant(client: "Claude Code"))
        SourceTag(source: .suggestion)
        SourceTag(source: .you)
    }
    .padding()
}
