//
//  PricingSalesData.swift
//  AppLocalizer
//

import Foundation

/// What a product's recent sales say, per territory (alpha-3), and whether
/// AppLocalizer could read them at all.
struct PricingSalesData: Hashable, Sendable {
    enum Availability: Hashable, Sendable {
        /// Sales and Trends were read; territories without a signal had too few.
        case available
        /// The key's role can't read Sales and Trends or App Analytics.
        case roleCannotRead
        /// AppLocalizer doesn't read sales for this source yet.
        case notRead
    }

    var availability: Availability
    var signals: [String: SalesSignal] = [:]
    var priorChanges: [String: PriorPriceChange] = [:]
    var baseTerritoryID = "USA"

    static let notRead = PricingSalesData(availability: .notRead)

    var canRead: Bool { availability == .available }

    func pageViews(in territoryID: String) -> Int? {
        signals[territoryID]?.pageViews
    }

    func evidence(for territoryID: String) -> SalesEvidence {
        guard canRead else { return .unavailable }
        return SalesEvidence(
            canReadSales: true,
            signal: signals[territoryID],
            baseSignal: signals[baseTerritoryID],
            priorChange: priorChanges[territoryID]
        )
    }
}
