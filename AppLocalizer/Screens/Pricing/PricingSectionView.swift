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
    /// The window's kept models; nil in previews without the main window.
    @Environment(WorkspaceSectionModels.self) private var sectionModels: WorkspaceSectionModels?
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
                await reload()
                await handlePendingIntent()
            }
        }
        .onChange(of: navigator.intent) {
            Task { await handlePendingIntent() }
        }
        .onChange(of: preferences.commissionRate) { _, rate in
            Task { await viewModel?.setCommission(Commission(preferenceRate: rate)) }
        }
        .onChange(of: changes.changes(for: app.id, section: .subscriptionPricing)) { queueDidChange() }
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
        let kept = sectionModels?.models(for: app.id)
        // The window keeps the models while other sections show: the
        // prices are there when the person comes back.
        if let model = kept?.pricing, let retentionModel = kept?.retention, model.catalog != nil {
            self.retentionModel = retentionModel
            viewModel = model
            // What changed while another section showed.
            queueDidChange()
            model.resultsDidChange()
            await model.setCommission(Commission(preferenceRate: preferences.commissionRate))
            if kept?.needsLoad(.subscriptionPricing, refreshCount: navigator.refreshCount) == true { await reload() }
            await handlePendingIntent()
            return
        }
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
        kept?.pricing = model
        kept?.retention = retentionModel
        let refreshCount = navigator.refreshCount
        await model.load()
        noteLoaded(model, refreshCount: refreshCount)
        #if DEBUG
        await model.applyDebugLaunch(from: services)
        await retentionModel.applyDebugLaunch(from: retention, pricing: model)
        #endif
        await handlePendingIntent()
    }

    /// Lays the queue back onto the prices, the cards and Retention.
    private func queueDidChange() {
        viewModel?.matrix?.queueDidChange()
        viewModel?.productsQueueDidChange()
        retentionModel?.refresh()
    }

    /// ⌘R, after a push, or kept prices that got old: everything again.
    private func reload() async {
        guard let viewModel else { return }
        let refreshCount = navigator.refreshCount
        await viewModel.reload()
        if let catalog = viewModel.catalog { await retentionModel?.load(subscriptions: RetentionSubscription.all(in: catalog)) }
        noteLoaded(viewModel, refreshCount: refreshCount)
    }

    /// Notes when the catalog was read, so the kept model isn't read again
    /// until Refresh, a push or its age asks for it.
    private func noteLoaded(_ model: PricingViewModel, refreshCount: Int) {
        guard !Task.isCancelled, model.catalog != nil else { return }
        sectionModels?.models(for: app.id).didLoad(.subscriptionPricing, refreshCount: refreshCount)
    }

    /// Handles the navigator's intent once prices are here, so “Apply
    /// Recommended Prices…” from the overview has a matrix to fill.
    private func handlePendingIntent() async {
        guard let viewModel, let intent = navigator.intent, viewModel.catalog != nil, !viewModel.isLoadingSheet else { return }
        if await viewModel.handle(intent) { navigator.consume(intent) }
    }
}
