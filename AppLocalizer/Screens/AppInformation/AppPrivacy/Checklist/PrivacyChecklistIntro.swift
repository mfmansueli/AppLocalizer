//
//  PrivacyChecklistIntro.swift
//  AppLocalizer
//

import SwiftUI

/// What to do, Open App Store Connect and Tile with Safari, and how many
/// steps are ticked.
struct PrivacyChecklistIntro: View {
    let viewModel: AppPrivacyViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Fill the questionnaire in App Store Connect in the order it asks. Keep this window on the left and Safari on the right.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.small) {
                Button(String(localized: "Open App Store Connect ↗")) {
                    openURL(viewModel.appStoreConnectURL)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("appInformation.appPrivacy.checklist.openASC")
                Button(String(localized: "Tile with Safari"), action: viewModel.tileWithSafari)
                    .accessibilityIdentifier("appInformation.appPrivacy.checklist.tile")
            }
            .controlSize(.small)
            HStack(spacing: Spacing.small) {
                MeterBar(fraction: viewModel.progress, tint: Palette.accent)
                    .accessibilityHidden(true)
                Text(viewModel.progressText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("appInformation.appPrivacy.checklist.progress")
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}
