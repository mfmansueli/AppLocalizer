//
//  SuggestionsCard.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's count of field suggestions waiting: per area, per
/// Store Page language, and per source, with a way into each area.
struct SuggestionsCard: View {
    let summary: SuggestionsSummary
    /// The connected assistant, named in the sources line.
    var assistant: String?
    let onReviewStorePage: () -> Void
    let onReviewAppInformation: () -> Void

    var body: some View {
        Card {
            HStack {
                OverviewCardTitle(title: String(localized: "Suggestions"), systemImage: "sparkles")
                Spacer(minLength: Spacing.small)
                Pill(text: summary.pillText, style: summary.total > 0 ? .machineTranslated : .outline)
                    .accessibilityIdentifier("overview.suggestionsCard.count")
            }
            VStack(spacing: 0) {
                OverviewRow {
                    Text("Store Page").foregroundStyle(Palette.label2)
                } value: {
                    Text(summary.storePageText)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                OverviewRow {
                    Text("App Information").foregroundStyle(Palette.label2)
                } value: {
                    Text(summary.appInformationText)
                }
                OverviewRow {
                    Text("From").foregroundStyle(Palette.label2)
                } value: {
                    Text(summary.sourcesText(assistant: assistant))
                        .foregroundStyle(Palette.label2)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            FlowLayout(spacing: Spacing.xSmall) {
                Button("Review Store Page", action: onReviewStorePage)
                    .accessibilityIdentifier("overview.suggestionsCard.storePage")
                Button("Review App Information", action: onReviewAppInformation)
                    .accessibilityIdentifier("overview.suggestionsCard.appInformation")
            }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
        }
        .accessibilityIdentifier("overview.suggestionsCard")
    }
}
