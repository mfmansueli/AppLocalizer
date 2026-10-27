//
//  PrivacyStartView.swift
//  AppLocalizer
//

import SwiftUI

/// Not started: the scan card, then the other ways to start.
struct PrivacyStartView: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            PrivacyScanCard(viewModel: viewModel)
            Text("Or start another way")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
                .padding(.top, Spacing.xxSmall)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: Spacing.small) {
                PrivacyStartOption(
                    title: String(localized: "Start from scratch"),
                    detail: String(localized: "Answer every question yourself."),
                    id: "scratch",
                    action: viewModel.startFromScratch
                )
                PrivacyStartOption(
                    title: String(localized: "Import from fastlane"),
                    detail: String(localized: "Read app_privacy_details.json from the project."),
                    id: "fastlane",
                    action: viewModel.chooseImportFile
                )
                PrivacyStartOption(
                    title: String(localized: "Enter what’s in App Store Connect"),
                    detail: String(localized: "Copy today’s answers in by hand, then scan to check them."),
                    id: "appStoreConnect",
                    action: viewModel.enterFromAppStoreConnect
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.start")
    }
}
