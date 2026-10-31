//
//  SuggestionsCard.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's count of field suggestions waiting, per page and per
/// source, the languages to add to the App Store, with Suggest
/// Everything… and a way into the Store Page. While
/// Suggest Everything runs, pages say how many are still coming and the
/// pill says "Arriving…"; a page that can't change now says "Locked".
struct SuggestionsCard: View {
    let summary: SuggestionsSummary
    /// The connected assistant, named in the sources line.
    var assistant: String?
    /// The run for this app, while it sends.
    var run: SuggestionRun?
    /// Pages locked while the version is in review.
    var lockedPages: Set<SuggestionPage> = []
    /// "Suggest Everything…", or with an API key "Generate Store Page
    /// Suggestions…".
    var suggestTitle = String(localized: "Suggest Everything…")
    /// The languages the app supports and the App Store page doesn't, under
    /// Store Page; nil leaves the line out (no project reported).
    var newLanguages: NewLanguagesSummary?
    let onSuggest: () -> Void
    let onReviewStorePage: () -> Void

    var body: some View {
        Card {
            HStack {
                OverviewCardTitle(title: String(localized: "Suggestions"), systemImage: "sparkles")
                Spacer(minLength: Spacing.small)
                Pill(
                    text: isArriving ? String(localized: "Arriving…") : summary.pillText,
                    style: summary.total > 0 || isArriving ? .machineTranslated : .outline
                )
                .accessibilityIdentifier("overview.suggestionsCard.count")
            }
            VStack(spacing: 0) {
                ForEach(SuggestionPage.allCases) { page in
                    let coming = run?.comingCount(on: page) ?? 0
                    OverviewRow {
                        Text(page.title).foregroundStyle(Palette.label2)
                    } value: {
                        Text(summary.text(on: page, coming: coming, isLocked: lockedPages.contains(page)))
                            .foregroundStyle(coming > 0 ? Palette.machineTranslated : Palette.label)
                            .fontWeight(coming > 0 ? .medium : .regular)
                    }
                    .accessibilityIdentifier("overview.suggestionsCard.row.\(page.rawValue)")
                    if page == .storePage, let newLanguages {
                        OverviewRow {
                            Text("New languages").foregroundStyle(Palette.label2)
                        } value: {
                            Text(newLanguages.suggestionText)
                                .foregroundStyle(newLanguages.hasSuggestions ? Palette.machineTranslated : Palette.label)
                                .fontWeight(newLanguages.hasSuggestions ? .medium : .regular)
                                .multilineTextAlignment(.trailing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityIdentifier("overview.suggestionsCard.newLanguages")
                    }
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
                if !isArriving {
                    Button(suggestTitle, action: onSuggest)
                        .accessibilityIdentifier("overview.suggestionsCard.suggest")
                }
                Button("Review Store Page", action: onReviewStorePage)
                    .accessibilityIdentifier("overview.suggestionsCard.storePage")
            }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
        }
        .accessibilityIdentifier("overview.suggestionsCard")
    }

    private var isArriving: Bool { run?.isRunning == true }
}
