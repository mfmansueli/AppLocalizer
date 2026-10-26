//
//  AppInformationCard.swift
//  AppLocalizer
//

import SwiftUI

/// Age rating, App Privacy status and whether App Review details are complete.
struct AppInformationCard: View {
    let summary: AppInformationSummary
    let onOpen: () -> Void

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
                    Text("App Privacy")
                } value: {
                    HStack(spacing: 4) {
                        if summary.privacyStatus.needsAttention {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Palette.warningMark)
                                .imageScale(.small)
                                .accessibilityHidden(true)
                        }
                        Text(summary.privacyStatus.title)
                    }
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
    }
}
