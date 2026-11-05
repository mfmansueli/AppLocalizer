//
//  AgeRatingPageView.swift
//  AppLocalizer
//

import SwiftUI

/// Age Rating: Apple's questionnaire in three groups, the override, and
/// the rating preview beside them, updating as you answer. Suggested
/// answers show under their questions, with the suggestion bar above; an
/// assistant's answers have a banner with Confirm All. In a narrow window
/// the preview goes above the questionnaire.
struct AgeRatingPageView: View {
    @Bindable var viewModel: AppInformationViewModel

    /// Narrower than this, the questions' labels wrap around their pickers.
    private static let minimumQuestionnaireWidth: CGFloat = 420

    var body: some View {
        if let ageRating = viewModel.ageRating {
            SideColumnLayout(sideWidth: 250, minimumMainWidth: Self.minimumQuestionnaireWidth) {
                questionnaire(ageRating)
                    .frame(maxWidth: .infinity, alignment: .leading)
                AgeRatingPreviewCard(
                    preview: ageRating.preview,
                    currentRating: viewModel.content?.ageRating.currentRating,
                    changesWithPush: viewModel.ratingChanges
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.ageRating")
        }
    }

    private func questionnaire(_ ageRating: AgeRatingValues) -> some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            AppInformationPageHeader(
                title: AppInformationPage.ageRating.title,
                subtitle: String(localized: """
                Apple’s questionnaire. Content is None, Infrequent or Frequent; capabilities are Yes or No. The rating updates as you answer.
                """)
            )
            AppInformationSuggestionsPanel(viewModel: viewModel, page: .ageRating)
            if let banner = viewModel.assistantBanner {
                AssistantAnswersBanner(client: banner.client, text: banner.text) {
                    if banner.unconfirmed > 0 {
                        Button(String(localized: "Confirm All")) { viewModel.confirmAllAnswers() }
                            .help(String(localized: "Confirms every answer \(banner.client) proposed on this page."))
                            .accessibilityIdentifier("appInformation.age.confirmAll")
                    }
                }
            }
            if viewModel.content?.ids.ageRatingDeclarationID == nil {
                InlineMessage.warning(String(localized: "App Store Connect didn’t return this app’s questionnaire, so it can’t be edited here."))
            }
            ForEach(AgeRatingQuestionGroup.allCases) { group in
                let questions = group.questions.filter { viewModel.showsField(.ageRating($0)) }
                if !questions.isEmpty {
                    AppInformationFormSection(title: group.title) {
                        ForEach(Array(questions.enumerated()), id: \.element) { index, question in
                            if index > 0 { Divider() }
                            VStack(alignment: .leading, spacing: 0) {
                                AgeRatingQuestionRow(question: question, answer: ageRating.answers[question], viewModel: viewModel)
                                AppInformationFieldSuggestions(viewModel: viewModel, slot: .ageRating(question))
                            }
                        }
                    }
                }
            }
            if !viewModel.showsOnlySuggestedFields {
                AgeRatingOverrideSection(viewModel: viewModel, preview: ageRating.preview, override: ageRating.override)
            }
        }
    }
}
