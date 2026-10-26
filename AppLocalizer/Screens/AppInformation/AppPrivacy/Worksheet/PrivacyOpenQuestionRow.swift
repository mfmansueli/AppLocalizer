//
//  PrivacyOpenQuestionRow.swift
//  AppLocalizer
//

import SwiftUI

/// One open question with Yes and No and the types it's about; once
/// answered, what the answer did.
struct PrivacyOpenQuestionRow: View {
    let question: PrivacyOpenQuestion
    let onAnswer: @MainActor (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            AssistantMonogram(letters: ChangeSource.assistant(client: question.client).monogram ?? "AI")
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(question.question)
                    .font(.callout)
                    .foregroundStyle(question.isOpen ? Palette.label : Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            YesNoPicker(title: question.question, value: question.answer, onSet: onAnswer)
                .controlSize(.small)
                .accessibilityIdentifier("appInformation.appPrivacy.question.\(question.id)")
        }
        .padding(Spacing.medium)
        .background(question.isOpen ? Palette.warningTint : Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.questionRow.\(question.id)")
    }

    /// "About: Email Address, Customer Support", or what the answer did.
    private var detail: String {
        if let effect = question.effectSummary {
            let answer = question.answer == true ? String(localized: "Yes") : String(localized: "No")
            return String(localized: "Answered \(answer) · \(effect)")
        }
        return String(localized: "About: \(question.affectedNames)")
    }
}
