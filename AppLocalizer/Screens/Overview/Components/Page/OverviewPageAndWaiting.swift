//
//  OverviewPageAndWaiting.swift
//  AppLocalizer
//

import SwiftUI

/// The Overview's top: the App Store page as it reads now, beside the
/// suggestions waiting in each section, how a change reaches the App Store,
/// and the languages the app speaks that its page doesn't yet.
struct OverviewPageAndWaiting: View {
    let app: StoreApp
    /// For the preview's screenshots and the captions waiting.
    let services: any StorePageServices
    let content: StorePageContent?
    /// The Overview's width: side by side when both fit.
    let width: CGFloat
    let storePage: StorePageSummary?
    let newLanguages: NewLanguagesSummary?

    @Environment(AppSummaryStore.self) private var summaries
    @Environment(ChangeQueue.self) private var changes
    @Environment(PricingModeStore.self) private var pricingModes
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(FieldSuggestionStore.self) private var suggestions

    /// The App Store page on the left, what waits for the person on the
    /// right; one above the other when the window is narrow.
    var body: some View {
        let isWide = width >= 300 + Spacing.xLarge + 380 + 2 * Spacing.xxLarge
        let layout = isWide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.xLarge))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.large))
        return layout {
            if let content {
                OverviewStorePreview(app: app, content: content, screenshots: services.screenshots, links: previewLinks)
            }
            VStack(alignment: .leading, spacing: Spacing.large) {
                OverviewWaitingCard(appName: app.name, rows: OverviewWaitingSection.rows(waitingFacts), onOpen: open)
                OverviewChangePathCard(
                    suggestedCount: badgeCounts.total,
                    readyCount: changes.count(for: app.id),
                    liveVersion: content?.versions.first { $0.state.isLive }?.versionString,
                    editedVersion: storePage?.versionString
                ) {
                    navigator.isReviewPresented = true
                }
                newLanguagesBanner
            }
            .frame(minWidth: isWide ? 380 : nil, maxWidth: .infinity, alignment: .leading)
        }
    }

    private var badgeCounts: SectionBadgeCounts {
        SectionBadgeCounts(
            appID: app.id,
            suggestions: suggestions,
            screenshots: services.screenshots.documentCenter,
            pricing: SectionBadgeCounts.pricingCount(appID: app.id, summaries: summaries, modes: pricingModes, changes: changes)
        )
    }

    private var waitingFacts: OverviewWaitingSection.Facts {
        let storeLanguages = Set(suggestions.toReview(for: app.id, area: .storePage).compactMap { suggestion -> String? in
            guard case let .storePage(code) = suggestion.target.scope else { return nil }
            return code
        })
        let pending = Set((newLanguages?.pending ?? []).map(\.code))
        let pages = Set(suggestions.toReview(for: app.id, area: .appInformation).compactMap(\.target.scope.page))
        let captions = services.screenshots.documentCenter?.openProposedCaptions(appID: app.id) ?? []
        return OverviewWaitingSection.Facts(
            counts: badgeCounts,
            storePageLanguages: storeLanguages.count,
            newPages: storeLanguages.intersection(pending).count,
            captionLanguages: Set(captions.map(\.locale)).count,
            isPricingEstimate: summaries.pricingSuggestionCounts[app.id] == nil,
            informationPages: AppInformationPage.allCases.filter(pages.contains).map(\.title)
        )
    }

    private var previewLinks: AppStorePreviewLinks {
        let counts = badgeCounts
        func link(_ section: AppWorkspaceSection) -> AppStorePreviewLink {
            AppStorePreviewLink(title: section.title, count: counts.count(for: section)) { open(section) }
        }
        return AppStorePreviewLinks(
            storePage: link(.storePage),
            appInformation: link(.appInformation),
            screenshots: link(.screenshots),
            pricing: link(.subscriptionPricing)
        )
    }

    /// Review (or Open) on a row, or a tag on the preview: the section, on
    /// its first suggestion when it has some.
    private func open(_ section: AppWorkspaceSection) {
        let hasSuggestions = badgeCounts.count(for: section) > 0
        switch section {
        case .storePage where hasSuggestions:
            navigator.open(.storePage, intent: .reviewFieldSuggestions(.storePage))
        case .appInformation where hasSuggestions:
            navigator.open(.appInformation, intent: .reviewFieldSuggestions(.appInformation))
        case .subscriptionPricing where hasSuggestions:
            navigator.open(.subscriptionPricing, intent: .reviewSuggestions)
        default:
            navigator.open(section)
        }
    }

    /// "Lumen 1.4 speaks Polish and Turkish, but its App Store page doesn’t
    /// yet. Their pages are suggested in Store Page."
    @ViewBuilder
    private var newLanguagesBanner: some View {
        if let newLanguages, newLanguages.hasSuggestions {
            let names = newLanguages.pending.map(\.name).formatted(.list(type: .and))
            let speaker = storePage?.versionString.map { "\(app.name) \($0)" } ?? app.name
            let suggested = suggestions.toReview(for: app.id, area: .storePage).contains { suggestion in
                guard case let .storePage(code) = suggestion.target.scope else { return false }
                return newLanguages.pending.contains { $0.code == code }
            }
            let text = String(localized: "\(speaker) speaks \(names), but its App Store page doesn’t yet.")
                + (suggested ? " " + String(localized: "Their pages are suggested in Store Page.") : "")
            Banner(kind: .info, title: text, isInline: true) {
                Button("Show") { navigator.open(.storePage, intent: .reviewFieldSuggestions(.storePage)) }
                    .accessibilityIdentifier("overview.newLanguages.show")
            }
            .accessibilityIdentifier("overview.newLanguages")
        }
    }
}
