//
//  PrivacyURLsOverviewCard.swift
//  AppLocalizer
//

import SwiftUI

/// The privacy URLs on the overview: how many locales have a Privacy
/// Policy URL (required) and a User Privacy Choices URL (optional).
struct PrivacyURLsOverviewCard: View {
    let urls: AppInformationSummary.PrivacyURLs
    let onOpen: () -> Void

    var body: some View {
        Card {
            HStack(alignment: .firstTextBaseline) {
                OverviewCardTitle(title: String(localized: "Privacy URLs"))
                Spacer(minLength: Spacing.small)
                if urls.missingPolicyCount > 0 {
                    Pill(text: String(localized: "\(urls.missingPolicyCount) missing"), style: .danger)
                }
            }
            VStack(spacing: 0) {
                OverviewRow {
                    Text("Privacy Policy")
                } value: {
                    Text("\(urls.policyCount) of \(urls.localeCount) locales")
                }
                OverviewRow {
                    Text("Privacy Choices")
                } value: {
                    Text("\(urls.choicesCount) of \(urls.localeCount) · optional")
                        .foregroundStyle(Palette.label2)
                }
            }
            Button("Open Privacy URLs", action: onOpen)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("overview.privacyURLs.open")
        }
        .accessibilityIdentifier("overview.privacyURLsCard")
    }
}
