//
//  PricingViewModel+Products.swift
//  AppLocalizer
//

import Foundation

// Pricing's Prices page: a card per product with its open price suggestion
// (Accept, Dismiss, Show Countries), Accept All above them, and "What
// people pay" beside them. Every product's prices are read once the catalog
// is here, one product at a time; accepting follows the strategy for that
// product, as Apply Recommended Prices… does, and nothing is pushed.
extension PricingViewModel {
    // MARK: - Loading

    /// Reads every product's prices for the cards, after the selected one.
    func startLoadingProducts() {
        productsTask?.cancel()
        areProductsLoaded = false
        productsTask = Task { [weak self] in await self?.loadProducts() }
    }

    func loadProducts() async {
        guard let catalog else { return }
        let ids = Set(catalog.products.map(\.id))
        productMatrices = productMatrices.filter { ids.contains($0.key) }
        for product in catalog.products {
            guard !Task.isCancelled else { return }
            if let matrix, matrix.product.id == product.id {
                productMatrices[product.id] = makeMatrix(product: product, sheet: matrix.sheet)
                productErrors[product.id] = nil
                continue
            }
            do {
                let sheet = try await services.priceSheet(for: product, commission: strategy.commission)
                guard !Task.isCancelled else { return }
                productMatrices[product.id] = makeMatrix(product: product, sheet: sheet)
                productErrors[product.id] = nil
            } catch is PricingSheetError {
                productErrors[product.id] = String(localized: "No price yet. Set its starting price in its prices.")
            } catch {
                guard !Task.isCancelled else { return }
                productErrors[product.id] = error.localizedDescription
            }
        }
        areProductsLoaded = true
    }

    /// The queue changed: the cards read it again.
    func productsQueueDidChange() {
        for matrix in productMatrices.values { matrix.queueDidChange() }
    }

    // MARK: - Reading

    /// Each loaded product's card, in the catalog's order.
    var productCards: [PricingProductCard] {
        (catalog?.products ?? []).compactMap(card(for:))
    }

    func card(for product: PricingProduct) -> PricingProductCard? {
        guard let matrix = productMatrices[product.id] else { return nil }
        return PricingProductCard.make(
            product: product,
            rows: matrix.rows,
            showsSuggestions: matrix.showsSuggestions,
            isDismissed: modes.isPriceSuggestionDismissed(productID: product.id, appID: app.id)
        )
    }

    /// Products with an open price suggestion: the Prices badge and Accept
    /// All n.
    var openPriceSuggestionCount: Int {
        productCards.count { $0.suggestion != nil }
    }

    /// "Price suggestions for 3 products. See each one below, or accept
    /// them together."
    var priceSuggestionsBannerText: String {
        let count = openPriceSuggestionCount
        return count == 1
            ? String(localized: "Price suggestions for 1 product. See it below, or accept it here.")
            : String(localized: "Price suggestions for \(count) products. See each one below, or accept them together.")
    }

    /// The countries "What people pay" offers: the base territory, then
    /// Germany, Brazil, India and Japan.
    var payTerritories: [Territory] {
        let rows = productMatrices.values.first?.rows ?? matrix?.rows ?? []
        let base = rows.first(where: \.isBase)?.territory
        let others = ["DEU", "BRA", "IND", "JPN"].compactMap { id in rows.first { $0.id == id }?.territory }
        return ([base].compactMap(\.self) + others).reduce(into: []) { result, territory in
            if !result.contains(territory) { result.append(territory) }
        }
    }

    /// Countries and regions the app has prices in, for the header.
    var territoryCount: Int? {
        let count = productMatrices.values.first?.rows.count ?? matrix?.rows.count ?? 0
        return count > 0 ? count : nil
    }

    var hasDismissedPriceSuggestions: Bool {
        !(modes.dismissedPriceSuggestions[app.id]?.isEmpty ?? true)
    }

    // MARK: - Deciding

    /// A card's Accept: every territory gets the strategy's price as a
    /// pending change (hand edits stay). Undo puts the queue back.
    func acceptPriceSuggestion(productID: String) async {
        guard let product = catalog?.product(id: productID) else { return }
        let undo = await accept([product])
        guard let undo else { return }
        show(String(localized: "Prices for \(product.name) accepted. They’re in Review & Push."), undo: undo)
    }

    /// Accept All n.
    func acceptAllPriceSuggestions() async {
        let products = productCards.filter { $0.suggestion != nil }.map(\.product)
        guard !products.isEmpty, let undo = await accept(products) else { return }
        let text = products.count == 1
            ? String(localized: "Prices for \(products[0].name) accepted. They’re in Review & Push.")
            : String(localized: "Accepted prices for \(products.count) products. They’re in Review & Push.")
        show(text, undo: undo)
    }

    /// A card's Dismiss: the suggestion goes until Restore Dismissed.
    func dismissPriceSuggestion(productID: String) {
        modes.dismissPriceSuggestion(productID: productID, appID: app.id)
        if expandedProductID == productID { expandedProductID = nil }
    }

    func restoreDismissedPriceSuggestions() {
        modes.restorePriceSuggestions(appID: app.id)
    }

    func toggleCountries(productID: String) {
        expandedProductID = expandedProductID == productID ? nil : productID
    }

    /// A card's Edit Prices…: that product's matrix, offers and results.
    func openDetails(productID: String) async {
        showsProductDetails = true
        tab = .prices
        await select(productID: productID)
    }

    /// Back to the cards from the matrix.
    func showProducts() {
        showsProductDetails = false
    }

    func undoToast() {
        toastUndo?()
        toastUndo = nil
        toast = nil
    }

    /// Follows the strategy for each product; returns how to undo it, or
    /// nil when nothing was written.
    private func accept(_ products: [PricingProduct]) async -> (() -> Void)? {
        let matrices = products.compactMap { productMatrices[$0.id] }.filter { !$0.isReadOnly }
        guard !matrices.isEmpty else { return nil }
        let prefixes = matrices.map { PriceChangeFactory.changeID(productID: $0.product.id, territoryID: "") }
        let owned: (PendingChange) -> Bool = { [app] change in
            change.appID == app.id && change.section == .subscriptionPricing && prefixes.contains { change.id.hasPrefix($0) }
        }
        let before = queue.changes(for: app.id, section: .subscriptionPricing).filter(owned)
        for matrix in matrices {
            followedProductIDs.insert(matrix.product.id)
            await matrix.follow()
        }
        matrix?.queueDidChange()
        let after = queue.changes(for: app.id, section: .subscriptionPricing).filter(owned)
        guard after != before else { return nil }
        return { [weak self] in
            guard let self else { return }
            queue.discardAll(where: owned)
            queue.upsert(contentsOf: before)
            for matrix in matrices {
                followedProductIDs.remove(matrix.product.id)
                matrix.stopFollowing()
            }
            productsQueueDidChange()
            matrix?.queueDidChange()
        }
    }

    private func show(_ text: String, undo: @escaping () -> Void) {
        toastUndo = undo
        toast = ToastMessage(text: text, canUndo: true, actionTitle: String(localized: "Review & Push"))
    }
}
