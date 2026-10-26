//
//  PricingSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The Subscription Pricing section of an app's workspace (⌘2): builds the
/// view model from the window's queue, modes and preferences, and connects
/// it to Refresh, workspace intents and Review & Push.
struct PricingSectionView: View {
    let app: StoreApp
    let services: any PricingServices

    @State private var viewModel: PricingViewModel?
    @Environment(ChangeQueue.self) private var changes
    @Environment(PricingModeStore.self) private var modes
    @Environment(AppPreferences.self) private var preferences
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(PushController.self) private var push

    var body: some View {
        Group {
            if let viewModel {
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
        }
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
        viewModel = model
        await model.load()
        #if DEBUG
        await model.applyDebugLaunch(from: services)
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
