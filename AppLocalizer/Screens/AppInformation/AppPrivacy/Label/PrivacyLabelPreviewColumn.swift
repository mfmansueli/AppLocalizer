//
//  PrivacyLabelPreviewColumn.swift
//  AppLocalizer
//

import SwiftUI

/// The column beside the worksheet: the App Privacy label the product page
/// will show, from reviewed answers only, updating as the person answers.
struct PrivacyLabelPreviewColumn: View {
    let preview: PrivacyLabelPreview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Product page preview")
                    .textCase(.uppercase)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.label2)
                Text("App Privacy")
                    .font(.headline)
                    .padding(.top, Spacing.xxSmall)
                if !preview.isAnswered {
                    Text("Answer the first question to see the label.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                } else if preview.isDataNotCollected {
                    notCollected
                } else {
                    ForEach(preview.groups) { group in
                        PrivacyLabelGroupCard(group: group)
                    }
                }
                Text("Updates as you answer. Unreviewed suggestions aren’t included.")
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xxSmall)
            }
            .padding(Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.content)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.labelPreview")
    }

    private var notCollected: some View {
        VStack(spacing: Spacing.xxSmall) {
            Text("Data Not Collected")
                .font(.callout.weight(.semibold))
            Text("The developer does not collect any data from this app.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("appInformation.appPrivacy.labelPreview.notCollected")
    }
}

#Preview {
    PrivacyLabelPreviewColumn(preview: PrivacyLabelPreview(answers: PrivacyReviewedAnswers(collects: true, collected: [
        .userId: PrivacyAnswer(collected: true, purposes: [.appFunctionality], linked: true),
        .crash: PrivacyAnswer(collected: true, purposes: [.appFunctionality]),
    ])))
    .frame(width: 262, height: 500)
}
