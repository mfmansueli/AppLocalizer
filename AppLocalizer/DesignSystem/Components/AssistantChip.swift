//
//  AssistantChip.swift
//  AppLocalizer
//

import SwiftUI

/// An assistant's name with its monogram, outlined: "CC Claude Code". The
/// assistant tag stays neutral; color is kept for meaning.
struct AssistantChip: View {
    let name: String
    var monogram: String?

    var body: some View {
        HStack(spacing: Spacing.xxSmall) {
            AssistantMonogram(letters: monogram ?? ChangeSource.assistant(client: name).monogram ?? "AI")
            Text(name)
                .font(.callout)
                .lineLimit(1)
        }
        .padding(.leading, 3)
        .padding(.trailing, Spacing.small)
        .padding(.vertical, 2)
        .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(name))
    }
}

#Preview {
    VStack {
        AssistantChip(name: "Claude Code")
        AssistantChip(name: "Cursor")
    }
    .padding()
}
