//
//  PrivacyOpenQuestionsBox.swift
//  AppLocalizer
//

import SwiftUI

/// What the code can't answer: the assistant's questions, open ones
/// first. The worksheet isn't done while one is open.
struct PrivacyOpenQuestionsBox: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let questions = viewModel.worksheet.questions
        let open = questions.count(where: \.isOpen)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("Open questions · the code can’t answer these")
                    .font(.callout.weight(.semibold))
                Spacer(minLength: Spacing.small)
                Text(open == 0
                    ? String(localized: "All answered")
                    : String(localized: "\(open) of \(questions.count) open · answer them before the worksheet counts as done"))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.trailing)
            }
            .padding(Spacing.medium)
            .background(Palette.fill1)
            ForEach(questions.sorted { $0.isOpen && !$1.isOpen }) { question in
                Divider()
                PrivacyOpenQuestionRow(question: question) { answer in
                    viewModel.answerQuestion(question.id, with: answer)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.questions")
    }
}
