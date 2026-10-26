//
//  PricingSampleData+Results.swift
//  AppLocalizer
//

import Foundation

extension PricingSampleData {
    /// Four weeks after pushing every recommended Annual price (the
    /// prototype's Results scene), most-viewed first.
    ///
    /// Before: the sales table, or a small made-up signal for territories
    /// without one. After: starts × the territory's multiplier (or a lift
    /// that grows with the cut), page views +3%.
    func results(subscription: PricingSampleSubscription = .annual) -> [PriceChangeResult] {
        catalog.territories.compactMap { territory -> PriceChangeResult? in
            let old = currentPrice(for: territory, subscription: subscription)
            let new = recommendation(for: territory, subscription: subscription).price.customerPrice
            guard (new - old).magnitude > Decimal(1) / 1000 else { return nil }
            let before = subscription == .annual ? Self.sales[territory.alpha2] ?? Self.quietSignal(territory) : Self.quietSignal(territory)
            let lift = Self.resultMultipliers[territory.alpha2] ?? 1 + 0.6 * max(0, 1 - (new / old).doubleValue)
            let afterStarts = Int((Double(before.starts) * lift + 0.5).rounded(.down))
            let afterViews = Int((Double(before.pageViews) * 1.03 + 0.5).rounded(.down))
            return PriceChangeResult(
                territory: territory,
                oldPrice: old,
                newPrice: new,
                before: SalesWindow(pageViews: before.pageViews, starts: before.starts, proceeds: proceeds(before.starts, old, territory)),
                after: SalesWindow(pageViews: afterViews, starts: afterStarts, proceeds: proceeds(afterStarts, new, territory))
            )
        }
        .sorted { $0.before.pageViews > $1.before.pageViews }
    }

    private func proceeds(_ starts: Int, _ price: Decimal, _ territory: Territory) -> Decimal {
        ResultsEvaluator.proceeds(starts: starts, price: price, territory: territory, commission: commission)
    }

    /// The prototype's stand-in for territories without sales: a few dozen
    /// views and 0–2 starts, derived from the code.
    private static func quietSignal(_ territory: Territory) -> SalesSignal {
        let codes = territory.alpha2.unicodeScalars.map { Int($0.value) }
        let hash = codes.count == 2 ? (codes[0] * 31 + codes[1] * 17) % 997 : 0
        return SalesSignal(pageViews: 40 + hash % 160, starts: hash % 3)
    }
}
