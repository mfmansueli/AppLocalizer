//
//  AssistantProposedTag.swift
//  AppLocalizer
//

import SwiftUI

/// "CC Proposed": next to an answer an assistant gave. VoiceOver reads
/// "Proposed by Claude Code".
struct AssistantProposedTag: View {
    let client: String
    var text = String(localized: "Proposed")

    var body: some View {
        HStack(spacing: Spacing.xxSmall) {
            Text(ChangeSource.assistant(client: client).monogram ?? "")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                .frame(width: 14, height: 14)
                .background(Palette.label, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.leading, 3)
        .padding(.trailing, Spacing.xSmall)
        .padding(.vertical, 2)
        .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(text) by \(client)"))
    }
}

#Preview {
    VStack {
        AssistantProposedTag(client: "Claude Code")
        AssistantProposedTag(client: "Claude Code", text: "Suggested")
    }
    .padding()
}
