//
//  PrivacyChecklistFooter.swift
//  AppLocalizer
//

import SwiftUI

/// Mark as Published once every step is ticked, or when it was marked.
struct PrivacyChecklistFooter: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        if let text = viewModel.publishedText {
            Label {
                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(Palette.positive)
            }
            .font(.callout)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("appInformation.appPrivacy.checklist.published")
        } else if viewModel.canMarkPublished, viewModel.worksheet.allStepsChecked {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("""
                Done in App Store Connect and published there? AppLocalizer saves today’s date and a copy of these answers, so it can tell \
                you when a later scan changes them.
                """)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                Button(String(localized: "Mark as Published in App Store Connect"), action: viewModel.markPublished)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("appInformation.appPrivacy.checklist.markPublished")
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .accessibilityElement(children: .contain)
        }
    }
}
