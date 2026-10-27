//
//  AppInformationCard.swift
//  AppLocalizer
//

import SwiftUI

/// App Information on the overview: age rating and App Review, then App
/// Privacy and the privacy URLs in cards of their own. The overview's grid
/// places each card in its own cell.
struct AppInformationCard: View {
    let summary: AppInformationSummary
    let onOpen: () -> Void
    /// Opens App Privacy on a tab: the worksheet, or the privacy URLs.
    let onOpenPrivacy: (AppPrivacyTab) -> Void

    var body: some View {
        Card {
            OverviewCardTitle(title: String(localized: "App Information"))
            VStack(spacing: 0) {
                OverviewRow {
                    Text("Age rating")
                } value: {
                    Text(summary.ageRating ?? "—")
                        .fontWeight(.semibold)
                }
                OverviewRow {
                    Text("App Review")
                } value: {
                    Text(summary.isAppReviewComplete ? "App Review details complete" : "Details missing")
                        .foregroundStyle(summary.isAppReviewComplete ? Palette.label : Palette.warning)
                }
            }
            Button("Open App Information", action: onOpen)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        }
        .accessibilityIdentifier("overview.appInformationCard")
        AppPrivacyOverviewCard(privacy: summary.privacy) { onOpenPrivacy(.worksheet) }
        if let urls = summary.privacyURLs {
            PrivacyURLsOverviewCard(urls: urls) { onOpenPrivacy(.urls) }
        }
    }
}
