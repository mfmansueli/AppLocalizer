//
//  AgeRatingPageView.swift
//  AppLocalizer
//

import SwiftUI

/// Age Rating: Apple's questionnaire in three groups, the override, and
/// the rating preview beside them, updating as you answer.
struct AgeRatingPageView: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        if let ageRating = viewModel.ageRating {
            HStack(alignment: .top, spacing: Spacing.xLarge) {
                questionnaire(ageRating)
                    .frame(maxWidth: .infinity, alignment: .leading)
                AgeRatingPreviewCard(
                    preview: ageRating.preview,
                    currentRating: viewModel.content?.ageRating.currentRating,
                    changesWithPush: viewModel.ratingChanges
                )
                .frame(width: 250)
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
            if let banner = viewModel.assistantBanner {
                AssistantAnswersBanner(client: banner.client, text: banner.text)
            }
            if viewModel.content?.ids.ageRatingDeclarationID == nil {
                InlineMessage.warning(String(localized: "App Store Connect didn’t return this app’s questionnaire, so it can’t be edited here."))
            }
            ForEach(AgeRatingQuestionGroup.allCases) { group in
                AppInformationFormSection(title: group.title) {
                    ForEach(Array(group.questions.enumerated()), id: \.element) { index, question in
                        if index > 0 { Divider() }
                        AgeRatingQuestionRow(question: question, answer: ageRating.answers[question], viewModel: viewModel)
                    }
                }
            }
            AgeRatingOverrideSection(viewModel: viewModel, preview: ageRating.preview, override: ageRating.override)
        }
    }
}
