//
//  SourceTag.swift
//  AppLocalizer
//

import SwiftUI

/// Who made a change, at the end of a review row. Assistants get an outlined
/// capsule with their monogram ("Proposed by Claude Code"); the rest a quiet
/// label. Neutral on purpose: purple is for unreviewed text, not for this.
struct SourceTag: View {
    let source: ChangeSource

    var body: some View {
        if let monogram = source.monogram {
            HStack(spacing: Spacing.xxSmall) {
                Text(monogram)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                    .frame(width: 14, height: 14)
                    .background(Palette.label, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                Text(source.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.leading, 3)
            .padding(.trailing, Spacing.xSmall)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Proposed by \(source.title)"))
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
