//
//  OverviewSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The landing page for the selected app (⌘1): a header with quick actions
/// and summary cards for subscriptions, territory prices, the pricing mode,
/// the store page, App Information, pending changes and the last push.
struct OverviewSectionView: View {
    let app: StoreApp

    @Environment(AppSummaryStore.self) private var summaries
    @Environment(ChangeQueue.self) private var changes
    @Environment(PushHistory.self) private var history
    @Environment(PricingModeStore.self) private var pricingModes
    @Environment(WorkspaceNavigator.self) private var navigator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                if isLoading {
                    OverviewSkeleton()
                } else {
                    OverviewHeader(
                        app: app,
                        storePage: storePage,
                        showsReviewSuggestions: mode.showsSuggestions && pricing?.sellsAnything == true,
                        onReviewSuggestions: reviewSuggestions,
                        onTranslateMissing: { navigator.open(.storePage, intent: .translateMissing) },
                        onReviewAndPush: { navigator.isReviewPresented = true }
                    )
                    if let message = errorMessage {
                        InlineMessage.error(message)
                            .accessibilityIdentifier("overview.error")
                    }
                    cards
                }
            }
            .padding(Spacing.xxLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("workspace.overview")
        .task(id: app.id) { await summaries.load(app) }
    }

    private var cards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: Metrics.overviewCardMinimumWidth), spacing: 14, alignment: .top)], alignment: .leading, spacing: 14) {
            if let pricing {
                SubscriptionsCard(summary: pricing)
                if pricing.sellsAnything {
                    TerritoryPricesCard(summary: pricing)
                    PricingModeCard(
                        mode: mode,
                        summary: pricing,
                        onReviewSuggestions: reviewSuggestions,
                        onShowSuggestions: {
                            pricingModes.setMode(.showSuggestions, for: app.id)
                            navigator.open(.subscriptionPricing, intent: .reviewSuggestions)
                        }
                    )
                }
            }
            if let storePage {
                StorePageCard(summary: storePage) { navigator.open(.storePage) }
            }
            if let information = summaries.appInformation[app.id]?.value {
                AppInformationCard(summary: information) {
                    navigator.open(.appInformation)
                } onOpenPrivacy: { tab in
                    navigator.open(.appInformation, intent: .openAppInformationPage(.appPrivacy, privacyTab: tab))
                }
            }
            PendingChangesCard(count: changes.count(for: app.id)) { navigator.isReviewPresented = true }
            LastPushCard(record: history.lastRecord(for: app.id)) { navigator.isActivityPresented = true }
        }
    }

    private var pricing: PricingSummary? { summaries.pricing[app.id]?.value }
    private var storePage: StorePageSummary? { summaries.storePage[app.id]?.value }
    private var mode: PricingMode { pricingModes.mode(for: app.id) }

    private var isLoading: Bool {
        let states = [summaries.pricing[app.id]?.isLoading, summaries.storePage[app.id]?.isLoading, summaries.appInformation[app.id]?.isLoading]
        let nothingYet = pricing == nil && storePage == nil && summaries.appInformation[app.id]?.value == nil
        return nothingYet && (states.contains(true) || states.allSatisfy { $0 == nil })
    }

    /// The first failure, so a broken section doesn't hide the others.
    private var errorMessage: String? {
        summaries.pricing[app.id]?.errorMessage
            ?? summaries.storePage[app.id]?.errorMessage
            ?? summaries.appInformation[app.id]?.errorMessage
    }

    private func reviewSuggestions() {
        navigator.open(.subscriptionPricing, intent: .reviewSuggestions)
    }
}
