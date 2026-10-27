//
//  PrivacyChecklistTab.swift
//  AppLocalizer
//

import SwiftUI

/// "Fill in App Store Connect": the steps to enter the reviewed answers in
/// the order App Store Connect asks, each with Copy and a tick, then Mark
/// as Published. Closed while the worksheet isn't done.
struct PrivacyChecklistTab: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let worksheet = viewModel.worksheet
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                PrivacyChecklistIntro(viewModel: viewModel)
                if let reason = worksheet.blockedReason, worksheet.publication == nil {
                    blocked(reason)
                } else {
                    PrivacyChecklistSteps(viewModel: viewModel)
                    PrivacyChecklistFooter(viewModel: viewModel)
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(Spacing.large)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.checklist")
    }

    private func blocked(_ reason: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(reason)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(String(localized: "Back to Worksheet")) { viewModel.tab = .worksheet }
                .controlSize(.small)
                .accessibilityIdentifier("appInformation.appPrivacy.checklist.back")
        }
        .padding(Spacing.medium)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.checklist.blocked")
    }
}
