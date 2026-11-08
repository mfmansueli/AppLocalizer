//
//  PricingViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Subscription Pricing section of one app: the catalog and selected
/// product, the pricing mode, the strategy inspector, the matrix of the
/// selected product and its other views (map, histogram, schedule, offers
/// and results).
@MainActor
@Observable
final class PricingViewModel {
    let app: StoreApp
    let strategy: PricingStrategyModel
    private(set) var catalogState: LoadState<PricingCatalog> = .idle
    private(set) var selectedProductID: String?
    private(set) var matrix: PriceMatrixModel?
    private(set) var isLoadingSheet = false
    private(set) var sheetError: String?

    var isModeSheetPresented = false
    var isBrowserPresented = false
    var isInspectorPresented = false
    var inspectorTab: StrategyInspectorTab = .strategy
    var columnPreset: PriceColumnPreset = .automatic
    /// Asks before Keep my prices drops the queued price changes.
    var isKeepConfirmationPresented = false
    var isGroupConfirmationPresented = false

    var tab = PricingTab.prices
    /// Prices, or Retention.
    var page = PricingPage.prices
    var display = PricingDisplay.table
    var mapMetric = TileMapMetric.percentVsBase
    /// The tile whose details the map shows.
    var hoveredTerritoryID: PricingRow.ID?
    var isScheduleSheetPresented = false
    /// Create Subscription, from the empty state or the product browser.
    var isNewSubscriptionSheetPresented = false
    /// The selected subscription has no price yet, so Pricing offers Set
    /// Starting Price instead of a failure.
    private(set) var needsStartingPrice = false
    var isStartingPriceSheetPresented = false
    /// Existing subscribers per territory for the schedule's warning; nil
    /// until loaded, or when AppLocalizer can't read them.
    private(set) var subscribers: [String: Int]?
    @ObservationIgnored private var subscribersProductID: String?
    private(set) var offers: LoadState<[SubscriptionOffer]> = .idle
    var selectedOfferID: SubscriptionOffer.ID?
    private(set) var results: PriceResultsModel?

    /// Today, for Results' 28 days; DEBUG scenes pin it.
    var today: () -> Date = { .now }
    /// The app's finished pushes (`PushHistory`), for Results.
    var pushRecords: () -> [PushRecord] = { [] }

    /// Shows a workspace banner (offline, rate limited, API error).
    var onNotice: (PushNotice) -> Void = { _ in }
    /// Opens Review & Push.
    var onOpenReview: () -> Void = {}

    @ObservationIgnored let queue: ChangeQueue
    @ObservationIgnored let services: any PricingServices
    @ObservationIgnored private let modes: PricingModeStore
    @ObservationIgnored var followedProductIDs: Set<String> = []
    @ObservationIgnored var siblingSheets: [String: ProductPriceSheet] = [:]

    init(app: StoreApp, services: any PricingServices, queue: ChangeQueue, modes: PricingModeStore, commission: Commission) {
        self.app = app
        self.services = services
        self.queue = queue
        self.modes = modes
        strategy = PricingStrategyModel(snapshot: services.indexSnapshot(), commission: commission)
    }

    // MARK: - Reading

    var mode: PricingMode { modes.mode(for: app.id) }

    var catalog: PricingCatalog? { catalogState.value }

    var selectedProduct: PricingProduct? {
        selectedProductID.flatMap { catalog?.product(id: $0) }
    }

    var resolvedPreset: PriceColumnPreset {
        let readOnly = mode == .keepPrices || selectedProduct?.isInAppPurchase == true
        return PriceColumnPreset.resolved(columnPreset, isKeepingPrices: readOnly, isInspectorOpen: isInspectorPresented)
    }

    /// Sibling subscriptions in the group, for “Copy from Monthly”.
    var siblings: [PricingProduct] {
        guard let product = selectedProduct else { return [] }
        return catalog?.siblings(of: product) ?? []
    }

    /// Price changes waiting in Review & Push; new subscriptions and
    /// retention aren't.
    var pendingPriceChangeCount: Int {
        queue.changes(for: app.id, section: .subscriptionPricing).count { !NewSubscriptionChangeBuilder.owns($0) && !RetentionChangeBuilder.owns($0) }
    }

    // MARK: - Loading

    /// Loads the catalog and the default product, and asks for a pricing
    /// mode the first time.
    func load() async {
        if modes.chosenMode(for: app.id) == nil { isModeSheetPresented = true }
        catalogState = .loading
        do {
            let catalog = try await services.catalog(for: app)
            catalogState = .loaded(catalog)
            let productID = selectedProductID.flatMap { catalog.product(id: $0)?.id } ?? catalog.defaultProduct?.id
            if let productID { await select(productID: productID, force: true) }
        } catch {
            catalogState = .failed(error.localizedDescription)
            reportLoadError(error)
        }
    }

    /// ⌘R and after a push: everything again from App Store Connect.
    func reload() async {
        siblingSheets = [:]
        await load()
    }

    /// The banner for a failed read, if it deserves one (a cancelled read
    /// doesn't).
    func reportLoadError(_ error: any Error) {
        if let notice = PricingLoadNotice.notice(for: error) { onNotice(notice) }
    }

    func select(productID: String, force: Bool = false) async {
        guard force || productID != selectedProductID, let product = catalog?.product(id: productID) else { return }
        selectedProductID = productID
        isBrowserPresented = false
        resetProductViews(for: product)
        isLoadingSheet = true
        sheetError = nil
        needsStartingPrice = false
        if matrix?.product.id != productID { matrix = nil }
        defer { isLoadingSheet = false }
        do {
            let sheet = try await services.priceSheet(for: product, commission: strategy.commission)
            guard selectedProductID == productID else { return }
            let matrix = PriceMatrixModel(
                appID: app.id,
                product: product,
                sheet: sheet,
                services: services,
                queue: queue,
                strategy: strategy.strategy,
                calculator: strategy.calculator,
                mode: mode,
                isFollowing: followedProductIDs.contains(productID)
            )
            matrix.onError = { [weak self] error in self?.reportLoadError(error) }
            if let previous = self.matrix, previous.product.id == productID {
                matrix.filter = previous.filter
                matrix.sortOrder = previous.sortOrder
                matrix.selection = previous.selection
            }
            self.matrix = matrix
        } catch {
            guard selectedProductID == productID else { return }
            sheetError = error.localizedDescription
            needsStartingPrice = error is PricingSheetError
            if !needsStartingPrice { reportLoadError(error) }
        }
    }

    /// Offers, results and subscribers belong to one product; a product
    /// without offers can't stay on that tab.
    private func resetProductViews(for product: PricingProduct) {
        offers = .idle
        selectedOfferID = nil
        results = nil
        subscribers = nil
        subscribersProductID = nil
        hoveredTerritoryID = nil
        if product.isInAppPurchase, tab == .offers { tab = .prices }
    }

    func setCommission(_ commission: Commission) async {
        guard commission != strategy.commission else { return }
        strategy.setCommission(commission)
        if let productID = selectedProductID { await select(productID: productID, force: true) }
    }

    // MARK: - Mode

    /// The first-visit sheet's Continue.
    func choose(_ mode: PricingMode) async {
        isModeSheetPresented = false
        await setMode(mode)
    }

    /// The first-visit sheet's Not Now: keep the default for now and ask again next time.
    func notNow() {
        isModeSheetPresented = false
    }

    func setMode(_ mode: PricingMode) async {
        if mode == .keepPrices, pendingPriceChangeCount > 0 {
            isKeepConfirmationPresented = true
            return
        }
        apply(mode: mode)
        if mode == .applyRecommended { await applyRecommendedPrices() }
    }

    /// Keep my prices after confirming: queued price changes go (new
    /// subscriptions and retention stay).
    func confirmKeepPrices() {
        queue.discardAll {
            $0.appID == app.id && $0.section == .subscriptionPricing && !NewSubscriptionChangeBuilder.owns($0) && !RetentionChangeBuilder.owns($0)
        }
        apply(mode: .keepPrices)
        matrix?.queueDidChange()
    }

    /// The keep bottom bar's “Show price suggestions”.
    func showPriceSuggestions() {
        apply(mode: .showSuggestions)
    }

    func apply(mode: PricingMode) {
        modes.setMode(mode, for: app.id)
        if mode == .keepPrices {
            followedProductIDs = []
            isInspectorPresented = false
        }
        matrix?.update(mode: mode)
    }

    /// Fills every territory with its proposal, then opens Review & Push.
    func applyRecommendedPrices() async {
        guard let matrix, !matrix.isReadOnly else { return }
        followedProductIDs.insert(matrix.product.id)
        await matrix.follow()
        onOpenReview()
    }

    // MARK: - Strategy

    func toggleInspector() {
        isInspectorPresented.toggle()
    }

    /// Edits the strategy; the matrix updates live, and followed proposals follow.
    func editStrategy(_ change: (inout PricingStrategy) -> Void) {
        strategy.edit(change)
        strategyDidChange()
    }

    func resetStrategy() {
        strategy.resetToRecommended()
        strategyDidChange()
    }

    func toggleExclusion(of territoryID: String) {
        strategy.toggleExclusion(of: territoryID)
        strategyDidChange()
    }

    func confirmImport() {
        strategy.confirmImport()
        strategyDidChange()
    }

    func strategyDidChange() {
        matrix?.update(strategy: strategy.strategy, calculator: strategy.calculator)
    }

    // MARK: - Schedule

    /// The bottom bar's “Starts now”, or Review & Push's “Edit…”.
    func openSchedule() {
        isScheduleSheetPresented = true
        Task { await loadSubscribers() }
    }

    func loadSubscribers() async {
        guard let product = selectedProduct, subscribersProductID != product.id else { return }
        subscribersProductID = product.id
        let counts = try? await services.subscribers(for: product)
        guard selectedProductID == product.id else { return }
        subscribers = counts
    }

    /// The schedule sheet's Save.
    func saveSchedule(_ schedule: PriceSchedule) {
        matrix?.setSchedule(schedule)
        isScheduleSheetPresented = false
    }

    // MARK: - Offers and Results

    /// Reads the selected subscription's offers once, selecting the first
    /// promotional offer (else the first).
    func loadOffers() async {
        guard let product = selectedProduct, !product.isInAppPurchase, !offers.isLoading, offers.value == nil else { return }
        offers = .loading
        do {
            let list = try await services.offers(for: product)
            guard selectedProductID == product.id else { return }
            offers = .loaded(list)
            if selectedOfferID == nil { selectedOfferID = (list.first { $0.kind == .promotional } ?? list.first)?.id }
        } catch {
            guard selectedProductID == product.id else { return }
            offers = .failed(error.localizedDescription)
        }
    }

    var selectedOffer: SubscriptionOffer? {
        offers.value?.first { $0.id == selectedOfferID }
    }

    /// Compares the selected product's last price push, once per product
    /// (and again after `resultsDidChange()`).
    func loadResults() async {
        guard let product = selectedProduct, results?.product.id != product.id else { return }
        let model = PriceResultsModel(appID: app.id, product: product, services: services, queue: queue)
        results = model
        await model.load(records: pushRecords(), today: today())
    }

    /// A push finished: Results compare again when shown.
    func resultsDidChange() {
        results = nil
    }
}
