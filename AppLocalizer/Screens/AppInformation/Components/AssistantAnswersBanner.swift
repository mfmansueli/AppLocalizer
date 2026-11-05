//
//  AssistantAnswersBanner.swift
//  AppLocalizer
//

import SwiftUI

/// "CC Claude Code answered 7 questions from the project · 5 not confirmed
/// yet": above a page an assistant filled in.
struct AssistantAnswersBanner<Trailing: View>: View {
    let client: String
    let text: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Spacing.small) {
            // One element for VoiceOver; the trailing buttons stay their own.
            HStack(spacing: Spacing.small) {
                SourceTag(source: .assistant(client: client))
                Text(text)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("appInformation.assistantBanner.text")
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.field + 1, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.assistantBanner")
    }
}

extension AssistantAnswersBanner where Trailing == EmptyView {
    init(client: String, text: String) {
        self.init(client: client, text: text) { EmptyView() }
    }
}

#Preview {
    AssistantAnswersBanner(client: "Claude Code", text: "answered 7 questions from the project · 5 not confirmed yet")
        .padding()
        .frame(width: 420)
}
