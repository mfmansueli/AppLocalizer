//
//  PrivacyWorksheetTab.swift
//  AppLocalizer
//

import SwiftUI

/// The Worksheet tab: the ways to start, or the worksheet itself, with the
/// label preview in a column beside it.
struct PrivacyWorksheetTab: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let worksheet = viewModel.worksheet
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    if worksheet.hasContent {
                        PrivacyWorksheetContent(viewModel: viewModel)
                    } else {
                        PrivacyStartView(viewModel: viewModel)
                    }
                    Text("Suggestions aren’t legal advice. You’re responsible for these answers, including what third-party SDKs in \(viewModel.appShortName) collect. “Collect” means data leaves the device and is kept longer than it takes to serve the request.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("appInformation.appPrivacy.disclaimer")
                }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.appPrivacy.worksheet")
            Divider()
            PrivacyLabelPreviewColumn(preview: worksheet.labelPreview)
                .frame(width: 262)
        }
    }
}
