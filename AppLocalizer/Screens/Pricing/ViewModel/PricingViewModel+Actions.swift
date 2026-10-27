//
//  PricingViewModel+Actions.swift
//  AppLocalizer
//

import Foundation

/// Workspace intents and the actions that reach beyond the selected
/// product: copying from a sibling and applying the strategy to the group.
extension PricingViewModel {
    /// Handles an intent meant for Pricing. Returns whether it did, so the
    /// caller consumes it.
    func handle(_ intent: WorkspaceIntent) async -> Bool {
        switch intent {
        case .reviewSuggestions:
            if mode == .keepPrices { apply(mode: .showSuggestions) }
            showMatrix()
            matrix?.filter = PriceMatrixFilter()
            columnPreset = .automatic
            return true
        case .applyRecommendedPrices:
            if mode == .keepPrices { apply(mode: .showSuggestions) }
            showMatrix()
            await applyRecommendedPrices()
            return true
        case .showResults:
            tab = .results
            return true
        case let .showPrices(shown):
            tab = .prices
            display = shown
            return true
        case let .editPriceSchedule(productID):
            // Review passes the price group's ID, which is the subscription's.
            if let productID, catalog?.product(id: productID) != nil { await select(productID: productID) }
            tab = .prices
            // Review & Push's sheet is still closing; macOS shows one sheet at a time.
            try? await Task.sleep(for: .milliseconds(400))
            if (matrix?.pendingCount ?? 0) > 0 { openSchedule() }
            return true
        default:
            return false
        }
    }

    /// The Prices tab with the matrix, where suggestions are applied.
    private func showMatrix() {
        tab = .prices
        display = .table
    }

    /// The More menu's “Copy from Monthly × 8.0”: the sibling's shown
    /// prices (queued or current) times the ratio of the base prices.
    func copy(from sibling: PricingProduct, to ids: [PricingRow.ID]) async {
        guard let matrix, let ratio = ratio(of: matrix.product, to: sibling), let sheet = await siblingSheet(sibling) else { return }
        let prices = Self.shownPrices(sheet: sheet, product: sibling, queue: queue)
        await matrix.copy(ids, from: prices, ratio: ratio)
    }

    /// “Copy from Monthly × 8.0”: the multiplier in the title.
    func ratioText(from sibling: PricingProduct) -> String? {
        guard let product = selectedProduct, let ratio = ratio(of: product, to: sibling) else { return nil }
        return ratio.fixed(1)
    }

    /// “Apply Strategy to Whole Group…” after confirming: every subscription in
    /// the group gets the strategy's proposals, as pending changes.
    func applyStrategyToGroup() async {
        guard let matrix else { return }
        await matrix.follow()
        followedProductIDs.insert(matrix.product.id)
        for sibling in siblings {
            guard let sheet = await siblingSheet(sibling) else { continue }
            let other = PriceMatrixModel(
                appID: app.id,
                product: sibling,
                sheet: sheet,
                services: services,
                queue: queue,
                strategy: strategy.strategy,
                calculator: strategy.calculator,
                mode: mode
            )
            other.onError = { [weak self] error in self?.onNotice(PricingLoadNotice.notice(for: error)) }
            await other.follow()
            followedProductIDs.insert(sibling.id)
        }
        onOpenReview()
    }

    // MARK: - Private

    private func ratio(of product: PricingProduct, to sibling: PricingProduct) -> Decimal? {
        guard let base = product.basePrice, let other = sibling.basePrice, other > 0 else { return nil }
        return (base / other).rounded(scale: 1)
    }

    private func siblingSheet(_ product: PricingProduct) async -> ProductPriceSheet? {
        if let sheet = siblingSheets[product.id] { return sheet }
        do {
            let sheet = try await services.priceSheet(for: product, commission: strategy.commission)
            siblingSheets[product.id] = sheet
            return sheet
        } catch {
            onNotice(PricingLoadNotice.notice(for: error))
            return nil
        }
    }

    private static func shownPrices(sheet: ProductPriceSheet, product: PricingProduct, queue: ChangeQueue) -> [String: Decimal] {
        var prices = sheet.prices.mapValues(\.current.customerPrice)
        for (territoryID, _) in sheet.prices {
            let id = PriceChangeFactory.changeID(productID: product.id, territoryID: territoryID)
            guard let change = queue.change(id: id), let territory = TerritoryCatalog.standard.territory(alpha3: territoryID),
                  let queued = QueuedPrice(change: change, territory: territory)
            else { continue }
            prices[territoryID] = queued.price
        }
        return prices
    }
}
