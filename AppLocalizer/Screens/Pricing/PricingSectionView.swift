//
//  PricingSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The Subscription Pricing section of an app's workspace (⌘2): builds the
/// view model from the window's queue, modes and preferences, and connects
/// it to Refresh, workspace intents, Review & Push and the push history
/// Results read.
struct PricingSectionView: View {
    let app: StoreApp
    let services: any PricingServices
    let retention: any RetentionServices

    @State private var viewModel: PricingViewModel?
    @State private var retentionModel: RetentionModel?
    @Environment(ChangeQueue.self) private var changes
    @Environment(PricingModeStore.self) private var modes
    @Environment(AppPreferences.self) private var preferences
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(PushController.self) private var push
    @Environment(PushHistory.self) private var history
    @Environment(AppSummaryStore.self) private var summaries

    var body: some View {
        Group {
            if let viewModel, viewModel.page == .retention, let retentionModel {
                RetentionScreen(model: retentionModel, pricing: viewModel)
            } else if let viewModel {
                PricingScreen(viewModel: viewModel, defaultMode: preferences.defaultPricingMode)
            } else {
                PricingTableSkeleton(columns: PriceColumnPreset.automatic.columns)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.subscriptionPricing")
        .task { await start() }
        .onChange(of: navigator.refreshCount) {
            Task {
                await viewModel?.reload()
                if let catalog = viewModel?.catalog { await retentionModel?.load(subscriptions: RetentionSubscription.all(in: catalog)) }
                await handlePendingIntent()
            }
        }
        .onChange(of: navigator.intent) {
            Task { await handlePendingIntent() }
        }
        .onChange(of: preferences.commissionRate) { _, rate in
            Task { await viewModel?.setCommission(Commission(preferenceRate: rate)) }
        }
        .onChange(of: changes.changes(for: app.id, section: .subscriptionPricing)) {
            viewModel?.matrix?.queueDidChange()
            viewModel?.productsQueueDidChange()
            retentionModel?.refresh()
        }
        // The tab bar's and Overview's Pricing count, once every product's
        // prices are read.
        .onChange(of: suggestionCount, initial: true) { _, count in
            if let count { summaries.setPricingSuggestionCount(count, for: app.id) }
        }
        .onChange(of: history.records.count) {
            viewModel?.resultsDidChange()
        }
    }

    private var suggestionCount: Int? {
        guard let viewModel, viewModel.areProductsLoaded else { return nil }
        return viewModel.openPriceSuggestionCount
    }

    private func start() async {
        guard viewModel == nil else { return }
        let model = PricingViewModel(
            app: app,
            services: services,
            queue: changes,
            modes: modes,
            commission: Commission(preferenceRate: preferences.commissionRate)
        )
        model.onNotice = { [push] notice in push.report(notice) }
        model.onOpenReview = { [navigator] in navigator.isReviewPresented = true }
        model.pushRecords = { [history, app] in history.records(for: app.id) }
        #if DEBUG
        model.applyDebugOpening(from: services)
        #endif
        let retentionModel = RetentionModel(app: app, services: retention, queue: changes)
        retentionModel.onOpenReview = { [navigator] in navigator.isReviewPresented = true }
        self.retentionModel = retentionModel
        viewModel = model
        await model.load()
        #if DEBUG
        await model.applyDebugLaunch(from: services)
        await retentionModel.applyDebugLaunch(from: retention, pricing: model)
        #endif
        await handlePendingIntent()
    }

    /// Handles the navigator's intent once prices are here, so “Apply
    /// Recommended Prices…” from the overview has a matrix to fill.
    private func handlePendingIntent() async {
        guard let viewModel, let intent = navigator.intent, viewModel.catalog != nil, !viewModel.isLoadingSheet else { return }
        if await viewModel.handle(intent) { navigator.consume(intent) }
    }
}
