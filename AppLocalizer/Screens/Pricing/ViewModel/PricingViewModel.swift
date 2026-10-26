//
//  PricingViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Subscription Pricing section of one app: the catalog and selected
/// product, the pricing mode, the strategy inspector, and the matrix of the
/// selected product.
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

    var pendingPriceChangeCount: Int { queue.changes(for: app.id, section: .subscriptionPricing).count }

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
            onNotice(PricingLoadNotice.notice(for: error))
        }
    }

    /// ⌘R and after a push: everything again from App Store Connect.
    func reload() async {
        siblingSheets = [:]
        await load()
    }

    func select(productID: String, force: Bool = false) async {
        guard force || productID != selectedProductID, let product = catalog?.product(id: productID) else { return }
        selectedProductID = productID
        isBrowserPresented = false
        isLoadingSheet = true
        sheetError = nil
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
            matrix.onError = { [weak self] error in self?.onNotice(PricingLoadNotice.notice(for: error)) }
            if let previous = self.matrix, previous.product.id == productID {
                matrix.filter = previous.filter
                matrix.sortOrder = previous.sortOrder
                matrix.selection = previous.selection
            }
            self.matrix = matrix
        } catch {
            guard selectedProductID == productID else { return }
            sheetError = error.localizedDescription
            onNotice(PricingLoadNotice.notice(for: error))
        }
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

    /// Keep my prices after confirming: queued price changes go.
    func confirmKeepPrices() {
        queue.discardAll { $0.appID == app.id && $0.section == .subscriptionPricing }
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
}
