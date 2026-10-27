//
//  PriceMatrixModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The price matrix of one product: its rows, filters, sorting, selection
/// and open popover, and every edit, each of which becomes a pending change.
/// The change queue is the source of truth for proposed prices.
@MainActor
@Observable
final class PriceMatrixModel {
    let appID: StoreApp.ID
    let product: PricingProduct
    private(set) var sheet: ProductPriceSheet
    private(set) var strategy: PricingStrategy
    private(set) var calculator: PriceCalculator
    private(set) var mode: PricingMode
    private(set) var rows: [PricingRow] = []

    var filter = PriceMatrixFilter()
    var sortOrder: [KeyPathComparator<PricingRow>] = []
    var selection: Set<PricingRow.ID> = []
    var popover: PricingPopover?
    /// Whether every territory follows the strategy, as after Apply Recommended Prices….
    private(set) var isFollowing: Bool
    /// When the queued changes take effect; read from the queue, so it
    /// survives navigating away.
    private(set) var schedule: PriceSchedule
    /// True while Apple's price points load for an edit.
    private(set) var isLoadingLadders = false
    var onError: (any Error) -> Void = { _ in }

    @ObservationIgnored let queue: ChangeQueue
    @ObservationIgnored private let services: any PricingServices
    @ObservationIgnored private let territories: TerritoryCatalog
    @ObservationIgnored private var recommendations: [String: Recommendation] = [:]
    @ObservationIgnored private var refollowTask: Task<Void, Never>?

    init(
        appID: StoreApp.ID,
        product: PricingProduct,
        sheet: ProductPriceSheet,
        services: any PricingServices,
        queue: ChangeQueue,
        strategy: PricingStrategy,
        calculator: PriceCalculator,
        mode: PricingMode,
        isFollowing: Bool = false,
        territories: TerritoryCatalog = .standard
    ) {
        self.appID = appID
        self.product = product
        self.sheet = sheet
        self.services = services
        self.queue = queue
        self.strategy = strategy
        self.calculator = calculator
        self.mode = mode
        self.isFollowing = isFollowing
        self.territories = territories
        schedule = PriceSchedule.current(in: queue, appID: appID, productID: product.id)
        rebuild(recommendations: true)
    }

    // MARK: - Reading

    /// Keep my prices and in-app purchases show prices without edits.
    var isReadOnly: Bool { mode == .keepPrices || product.isInAppPurchase }

    var showsSuggestions: Bool { mode.showsSuggestions && !product.isInAppPurchase }

    /// Rows with a stepper instead of an Apply button.
    func showsStepper(_ row: PricingRow) -> Bool {
        !isReadOnly && (row.queued != nil || isFollowing || mode == .applyRecommended)
    }

    var visibleRows: [PricingRow] {
        let filtered = rows.filter(filter.matches)
        return sortOrder.isEmpty ? filtered.sorted(by: PricingRow.defaultOrder) : filtered.sorted(using: sortOrder)
    }

    var selectedRows: [PricingRow] { visibleRows.filter { selection.contains($0.id) } }

    var pendingCount: Int { rows.count { $0.queued != nil } }

    var heldBackCount: Int { rows.count(where: \.likelyHeldBack) }

    var customCount: Int { rows.count(where: \.isCustomPrice) }

    var baseRow: PricingRow? { rows.first(where: \.isBase) }

    func row(id: PricingRow.ID) -> PricingRow? {
        rows.first { $0.id == id }
    }

    func ladder(for row: PricingRow) -> PricePointLadder {
        sheet.ladder(for: row.territory, commission: calculator.commission)
    }

    /// Prices around the shown one, for the breakdown's chips.
    func nearbyPoints(for row: PricingRow) -> [PricePoint] {
        ladder(for: row).nearby(row.shownPrice, count: 3, rounding: strategy.rounding)
    }

    func comparison(for row: PricingRow) -> [SourceComparison] {
        guard let input = builder.input(for: row.territory) else { return [] }
        return calculator.compareSources(input, strategy: strategy)
    }

    // MARK: - Updating

    func update(strategy: PricingStrategy, calculator: PriceCalculator) {
        let commissionChanged = calculator.commission != self.calculator.commission
        self.strategy = strategy
        self.calculator = calculator
        rebuild(recommendations: commissionChanged)
        if isFollowing { scheduleRefollow() }
    }

    func update(mode: PricingMode) {
        guard mode != self.mode else { return }
        let suggestionsChanged = mode.showsSuggestions != self.mode.showsSuggestions
        self.mode = mode
        if mode == .keepPrices { isFollowing = false }
        if suggestionsChanged { rebuild(recommendations: true) }
    }

    /// Re-reads the queue, after this model or anyone else changed it.
    func queueDidChange() {
        let queued = queuedPrices()
        for index in rows.indices where rows[index].queued != queued[rows[index].id] {
            rows[index].queued = queued[rows[index].id]
        }
    }

    func stopFollowing() {
        isFollowing = false
        refollowTask?.cancel()
    }

    /// The schedule sheet's Save: every queued change of this product (and
    /// every later one) takes effect on the new schedule.
    func setSchedule(_ schedule: PriceSchedule) {
        self.schedule = schedule
        let prefix = PriceChangeFactory.changeID(productID: product.id, territoryID: "")
        let rewritten = queue.changes(for: appID, section: .subscriptionPricing)
            .filter { $0.id.hasPrefix(prefix) }
            .map(schedule.applied(to:))
        queue.upsert(contentsOf: rewritten)
        rebuild(recommendations: false)
    }

    // MARK: - Writing

    /// Writes new prices to the queue in one save; a price equal to today's
    /// drops the territory's pending change instead.
    func write(_ points: [String: PricePoint], source: ChangeSource) {
        let factory = PriceChangeFactory(appID: appID, product: product, schedule: schedule)
        var upserts: [PendingChange] = []
        var discards: [PendingChange.ID] = []
        for (territoryID, point) in points {
            guard let row = row(id: territoryID) else { continue }
            if PricingRow.differs(point.customerPrice, row.current.customerPrice) {
                upserts.append(factory.change(for: row.territory, from: row.current, to: point, source: source))
            } else if row.queued != nil {
                discards.append(PriceChangeFactory.changeID(productID: product.id, territoryID: territoryID))
            }
        }
        queue.discard(ids: discards)
        queue.upsert(contentsOf: upserts.sorted { $0.title < $1.title })
        queueDidChange()
    }

    /// Makes sure Apple's ladders are here for these territories, since only
    /// their points can be pushed. Returns false if they couldn't load.
    func ensureLadders(for territoryIDs: [String]) async -> Bool {
        let missing = sheet.missingLadders(in: territoryIDs)
        guard !missing.isEmpty else { return true }
        isLoadingLadders = true
        defer { isLoadingLadders = false }
        do {
            let ladders = try await services.ladders(for: product, territoryIDs: missing, commission: calculator.commission)
            sheet.merge(ladders)
            rebuild(recommendations: true)
            return true
        } catch {
            onError(error)
            return false
        }
    }

    /// Follows the strategy everywhere: every territory without a hand edit
    /// gets the strategy's price as a pending change.
    func follow() async {
        isFollowing = true
        guard await ensureLadders(for: rows.map(\.id)) else { return }
        writeTargets()
    }

    // MARK: - Private

    private var builder: PricingRowBuilder {
        PricingRowBuilder(
            catalog: territories,
            calculator: calculator,
            sheet: sheet,
            strategy: strategy,
            showsSuggestions: showsSuggestions,
            isScheduled: schedule.isScheduled
        )
    }

    private func rebuild(recommendations recompute: Bool) {
        let builder = builder
        if recompute { recommendations = builder.recommendations() }
        rows = builder.rows(recommendations: recommendations, queued: queuedPrices())
    }

    private func queuedPrices() -> [String: QueuedPrice] {
        let prefix = PriceChangeFactory.changeID(productID: product.id, territoryID: "")
        var result: [String: QueuedPrice] = [:]
        for change in queue.changes(for: appID, section: .subscriptionPricing) where change.id.hasPrefix(prefix) {
            let territoryID = String(change.id.dropFirst(prefix.count))
            guard let territory = territories.territory(alpha3: territoryID) else { continue }
            result[territoryID] = QueuedPrice(change: change, territory: territory)
        }
        return result
    }

    /// The strategy's price for every row without a hand edit.
    func writeTargets() {
        var points: [String: PricePoint] = [:]
        for row in rows where !(row.queued?.isManual ?? false) && !row.isBase {
            points[row.id] = row.target
        }
        write(points, source: .suggestion)
    }

    /// While following, a strategy edit rewrites the proposals once the
    /// person pauses, so dragging a slider doesn't rewrite the queue each step.
    private func scheduleRefollow() {
        refollowTask?.cancel()
        refollowTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.writeTargets()
        }
    }
}
