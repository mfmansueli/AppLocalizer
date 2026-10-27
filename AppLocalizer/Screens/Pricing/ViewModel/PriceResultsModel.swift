//
//  PriceResultsModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// One product's Results: the last push that changed its prices, each
/// territory compared over the 28 days before and after, and Restore where
/// it got worse, which queues the old price for review like Activity's
/// Restore Previous Values does.
@MainActor
@Observable
final class PriceResultsModel {
    enum State: Equatable {
        case loading
        /// No push has changed this product's prices yet.
        case noChanges
        /// The 28 days after the change aren't up yet.
        case tooEarly(changedOn: Date, day: Int, arrivesOn: Date)
        /// The 28 days are up, but AppLocalizer can't read sales to compare.
        case salesUnavailable(changedOn: Date)
        case ready(changedOn: Date)
        case failed(String)
    }

    let appID: StoreApp.ID
    let product: PricingProduct
    private(set) var state = State.loading
    /// Territories with enough data, most-viewed first.
    private(set) var results: [PriceChangeResult] = []
    /// Totals over those territories, plus how many had too little data.
    private(set) var summary: ResultsSummary?

    @ObservationIgnored private let services: any PricingServices
    @ObservationIgnored private let queue: ChangeQueue
    @ObservationIgnored private let territories: TerritoryCatalog
    /// The pushed change per territory, for Restore.
    @ObservationIgnored private var pushed: [String: PendingChange] = [:]

    init(appID: StoreApp.ID, product: PricingProduct, services: any PricingServices, queue: ChangeQueue, territories: TerritoryCatalog = .standard) {
        self.appID = appID
        self.product = product
        self.services = services
        self.queue = queue
        self.territories = territories
    }

    /// Finds the last push of this product's prices in `records` and
    /// compares, or says when results arrive.
    func load(records: [PushRecord], today: Date) async {
        let prefix = PriceChangeFactory.changeID(productID: product.id, territoryID: "")
        let latest = records
            .filter { $0.appID == appID }
            .sorted { $0.date > $1.date }
            .first { record in record.pushed.contains { $0.id.hasPrefix(prefix) } }
        guard let record = latest else {
            state = .noChanges
            return
        }
        pushed = Dictionary(
            record.pushed.filter { $0.id.hasPrefix(prefix) }.map { (String($0.id.dropFirst(prefix.count)), $0) },
            uniquingKeysWith: { _, last in last }
        )
        switch ResultsEvaluator.availability(changedOn: record.date, now: today) {
        case let .tooEarly(day, arrivesOn):
            state = .tooEarly(changedOn: record.date, day: day, arrivesOn: arrivesOn)
        case .ready:
            await compare(changedOn: record.date)
        }
    }

    // MARK: - Restore

    /// Worse territories whose old price can be put back.
    func canRestore(_ result: PriceChangeResult) -> Bool {
        result.verdict.offersRestore && pushed[result.id]?.restoreRequests.isEmpty == false
    }

    /// Whether the old price already waits in Review & Push.
    func isRestoreQueued(_ territoryID: String) -> Bool {
        guard let change = pushed[territoryID] else { return false }
        return queue.change(id: change.id)?.source == .restore
    }

    /// Queues the territory's old price for review. Restores apply as soon
    /// as Apple processes them.
    func restore(_ territoryID: String) {
        guard var change = pushed[territoryID]?.restoring() else { return }
        change.groupNote = PriceSchedule.immediate.note
        queue.upsert(change)
    }

    // MARK: - Private

    private func compare(changedOn date: Date) async {
        state = .loading
        do {
            let ids = pushed.keys.sorted()
            guard let sales = try await services.salesComparison(for: product, territoryIDs: ids, changedOn: date) else {
                state = .salesUnavailable(changedOn: date)
                return
            }
            let all = ids.compactMap { id in pushed[id].flatMap { result(for: $0, territoryID: id, sales: sales[id]) } }
            summary = ResultsEvaluator.summarize(all)
            results = all.filter(\.verdict.hasEnoughData).sorted { $0.before.pageViews > $1.before.pageViews }
            state = .ready(changedOn: date)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// A pushed change read back as before and after; a territory without
    /// sales counts as too little data.
    private func result(for change: PendingChange, territoryID: String, sales: SalesComparison?) -> PriceChangeResult? {
        guard let territory = territories.territory(alpha3: territoryID) else { return nil }
        let currency = CurrencyFormat.forCurrency(territory.currencyCode)
        guard let old = currency.parse(change.oldValue), let new = currency.parse(change.newValue) else { return nil }
        let empty = SalesWindow(pageViews: 0, starts: 0, proceeds: 0)
        return PriceChangeResult(territory: territory, oldPrice: old, newPrice: new, before: sales?.before ?? empty, after: sales?.after ?? empty)
    }
}
