//
//  PrivacyCollectsRow.swift
//  AppLocalizer
//

import SwiftUI

/// The questionnaire's first question, Yes or No, with who answered it.
/// An assistant's answer nobody reviewed is tinted purple with Accept.
struct PrivacyCollectsRow: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let collects = viewModel.worksheet.collects
        let isUnreviewed = collects?.status == .unreviewed
        HStack(spacing: Spacing.small) {
            Text("Do you or your third-party partners collect data from this app?")
                .font(.callout.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            YesNoPicker(title: String(localized: "Collects data"), value: collects?.value) { value in
                viewModel.setCollects(value)
            }
            .accessibilityIdentifier("appInformation.appPrivacy.collects")
            if let collects {
                if let client = collects.client, collects.status.isAssistants {
                    AssistantChip(name: client)
                } else {
                    PrivacyRowStatusPill(status: collects.status)
                }
            }
            if isUnreviewed {
                Button(String(localized: "Accept")) { viewModel.acceptCollects() }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("appInformation.appPrivacy.collects.accept")
            }
        }
        .padding(Spacing.medium)
        .background(isUnreviewed ? Palette.machineTranslatedTint : Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.collectsRow")
    }
}
