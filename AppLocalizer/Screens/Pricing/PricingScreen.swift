//
//  PricingScreen.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// Subscription Pricing laid out: a card per product (the Prices page), or
/// one product's section bar, then Prices (filters, the matrix, map or
/// histogram, and the bottom bar), Offers or Results, with the strategy
/// inspector, the mode and schedule sheets, the custom index import and the
/// Accept toast around them.
struct PricingScreen: View {
    @Bindable var viewModel: PricingViewModel
    /// Preselected in the first-visit sheet: the default for new apps from Settings.
    let defaultMode: PricingMode

    @State private var isImporterPresented = false
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var strategy = viewModel.strategy
        VStack(spacing: 0) {
            if let catalog = viewModel.catalog, catalog.isEmpty {
                NoSubscriptionsView(viewModel: viewModel)
            } else if let message = viewModel.catalogState.errorMessage {
                failure(message)
            } else if !viewModel.showsProductDetails, viewModel.catalog != nil {
                PricingProductsView(viewModel: viewModel)
            } else {
                PricingSectionBar(viewModel: viewModel)
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                ActionToast(message: toast) {
                    viewModel.undoToast()
                } onAction: {
                    viewModel.toast = nil
                    viewModel.onOpenReview()
                } onDismiss: {
                    if viewModel.toast == toast { viewModel.toast = nil }
                }
                .padding(.bottom, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.toast)
        .inspector(isPresented: $viewModel.isInspectorPresented) {
            StrategyInspector(viewModel: viewModel) { isImporterPresented = true }
        }
        .sheet(isPresented: $viewModel.isModeSheetPresented) {
            PricingModeSheet(
                appName: viewModel.app.name,
                initialMode: defaultMode,
                onContinue: { mode in Task { await viewModel.choose(mode) } },
                onNotNow: viewModel.notNow
            )
        }
        .sheet(isPresented: $viewModel.isNewSubscriptionSheetPresented) {
            NewSubscriptionSheet(
                appName: viewModel.app.name,
                bundleID: viewModel.app.bundleID,
                groups: viewModel.subscriptionGroups,
                initial: viewModel.newSubscriptionDefaults(),
                problems: viewModel.problems(for:),
                onCancel: { viewModel.isNewSubscriptionSheetPresented = false },
                onAdd: viewModel.queueNewSubscription
            )
        }
        .sheet(isPresented: $viewModel.isStartingPriceSheetPresented) {
            StartingPriceSheet(
                productName: viewModel.selectedProduct?.name ?? "",
                initialPrice: nil,
                onCancel: { viewModel.isStartingPriceSheetPresented = false },
                onSave: viewModel.queueStartingPrice
            )
        }
        .sheet(isPresented: $viewModel.isScheduleSheetPresented) {
            if let matrix = viewModel.matrix {
                PriceScheduleSheet(
                    productName: matrix.product.name,
                    schedule: matrix.schedule,
                    consent: matrix.increaseConsent(subscribers: viewModel.subscribers),
                    today: viewModel.today(),
                    onCancel: { viewModel.isScheduleSheetPresented = false },
                    onSave: viewModel.saveSchedule
                )
            }
        }
        .sheet(item: $strategy.importPreview) { preview in
            CustomIndexImportSheet(
                preview: preview,
                territoryCount: viewModel.strategy.territories.count,
                onCancel: viewModel.strategy.cancelImport,
                onImport: viewModel.confirmImport
            )
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText]) { result in
            importFile(result)
        }
        .confirmationDialog(
            String(localized: "Keep your prices?"),
            isPresented: $viewModel.isKeepConfirmationPresented
        ) {
            Button(String(localized: "Discard \(viewModel.pendingPriceChangeCount) Price Changes"), role: .destructive) {
                viewModel.confirmKeepPrices()
            }
        } message: {
            Text("Keep my prices never proposes a change, so the price changes waiting in Review & Push for \(viewModel.app.name) are discarded.")
        }
        .confirmationDialog(
            String(localized: "Apply the strategy to the whole group?"),
            isPresented: $viewModel.isGroupConfirmationPresented
        ) {
            Button(String(localized: "Apply to \(viewModel.siblings.count + 1) Subscriptions")) {
                Task { await viewModel.applyStrategyToGroup() }
            }
        } message: {
            Text("""
            Every subscription in the group gets the strategy’s prices as pending changes, keeping each one’s \
            price ratio. Hand edits stay, and nothing is pushed until you review it.
            """)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let matrix = viewModel.matrix {
            switch viewModel.tab {
            case .prices:
                prices(matrix)
            case .offers:
                Divider()
                PricingOffersView(viewModel: viewModel, matrix: matrix)
            case .results:
                Divider()
                PricingResultsView(viewModel: viewModel)
            }
        } else if viewModel.needsStartingPrice {
            StartingPriceView(viewModel: viewModel)
        } else if let message = viewModel.sheetError {
            failure(message)
        } else {
            PricingTableSkeleton(columns: viewModel.resolvedPreset.columns)
        }
    }

    @ViewBuilder
    private func prices(_ matrix: PriceMatrixModel) -> some View {
        PricingFilterBar(viewModel: viewModel, matrix: matrix)
        if viewModel.isLoadingSheet {
            Divider()
            PricingTableSkeleton(columns: viewModel.resolvedPreset.columns)
        } else {
            salesBanner(matrix)
            switch viewModel.display {
            case .table:
                PriceMatrixTable(viewModel: viewModel, matrix: matrix)
            case .map:
                Divider()
                PriceTileMapView(viewModel: viewModel, matrix: matrix)
            case .histogram:
                Divider()
                PriceHistogramView(histogram: matrix.histogram)
            }
        }
        PricingBottomBar(viewModel: viewModel, matrix: matrix)
    }

    @ViewBuilder
    private func salesBanner(_ matrix: PriceMatrixModel) -> some View {
        if matrix.showsSuggestions {
            switch matrix.sheet.sales.availability {
            case .available:
                EmptyView()
            case .roleCannotRead:
                Banner(
                    kind: .info,
                    title: String(localized: "Suggestions use purchasing power alone."),
                    message: String(localized: "This key’s role can’t read Sales and Trends or App Analytics, so every suggestion has low confidence.")
                ) {
                    Button("Use Another Key…") { openSettings() }
                        .accessibilityIdentifier("pricing.useAnotherKey")
                }
                .accessibilityIdentifier("pricing.noSalesBanner")
            case .notRead:
                Banner(
                    kind: .info,
                    title: String(localized: "Suggestions use purchasing power alone."),
                    message: String(localized: "AppLocalizer doesn’t read Sales and Trends yet, so every suggestion has low confidence.")
                )
                .accessibilityIdentifier("pricing.noSalesBanner")
            }
        }
    }

    private func failure(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Prices couldn’t load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") { Task { await viewModel.reload() } }
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("pricing.tryAgain")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func importFile(_ result: Result<URL, any Error>) {
        guard case let .success(url) = result else { return }
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            viewModel.onNotice(.apiError(String(localized: "“\(url.lastPathComponent)” couldn’t be read as text.")))
            return
        }
        let multipliers = viewModel.matrix?.sheet.prices
        viewModel.strategy.previewImport(text: text, fileName: url.lastPathComponent) { territory in
            multipliers?[territory.id]?.equalizationMultiplier
        }
    }
}
