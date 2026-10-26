//
//  MCPPriceProposer.swift
//  AppLocalizer
//

import Foundation

/// Checks an assistant's price for one territory like an edit in the
/// matrix, then queues it, withdraws the assistant's earlier proposal when
/// the price is today's, or says why it can't.
@MainActor
struct MCPPriceProposer {
    enum Outcome: Equatable {
        /// Waiting in Review & Push as `changeID`. `competing`: the person
        /// set another price there, which stays primary.
        case queued(changeID: PendingChange.ID, competing: Bool)
        /// Today's price, or the price already waiting; `withdrew` when the
        /// assistant's earlier proposal left the queue.
        case unchanged(note: String, withdrew: Bool)
        /// With what to do instead and, for a price between points, the
        /// nearest points.
        case refused(reason: String, nearest: [Decimal])
    }

    let sheet: MCPPriceSheet
    let source: ChangeSource

    var queue: ChangeQueue { sheet.workspace.changes }

    func propose(_ price: Decimal, in territory: Territory) -> Outcome {
        let ladder = sheet.ladder(for: territory)
        guard let point = ladder.point(at: price) else { return notAPricePoint(price, in: territory, ladder: ladder) }
        guard let current = sheet.sheet.prices[territory.id]?.current else {
            return .refused(reason: MCPPriceProposal.unknownTerritoryMessage(territory.id, product: sheet.product), nearest: [])
        }
        let existing = sheet.queuedChange(for: territory)
        guard PricingRow.differs(point.customerPrice, current.customerPrice) else { return withdraw(existing) }
        if let existing, existing.source != source, queuedPrice(existing, in: territory) == point.customerPrice {
            return .unchanged(note: String(localized: "That price already waits in Review & Push; nothing new was queued."), withdrew: false)
        }
        guard let change = sheet.change(for: territory, to: point, source: source) else {
            return .refused(reason: MCPPriceProposal.unknownTerritoryMessage(territory.id, product: sheet.product), nearest: [])
        }
        queue.upsert(change)
        let stored = queue.change(id: change.id)
        let competing = stored?.source != source && stored?.alternative?.source == source
        return .queued(changeID: change.id, competing: competing)
    }

    // MARK: - Private

    /// Today's price: the assistant's own proposal leaves, or its version
    /// of a price the person also changed. The person's change stays.
    private func withdraw(_ existing: PendingChange?) -> Outcome {
        var withdrew = false
        if let existing, existing.source == source {
            queue.discard(id: existing.id)
            withdrew = true
        } else if let existing, existing.alternative?.source == source {
            queue.resolveAlternative(id: existing.id, keepAlternative: false)
            withdrew = true
        }
        let note = withdrew
            ? String(localized: "That’s today’s price, so your earlier proposal for this territory was withdrawn.")
            : String(localized: "That’s already today’s price in App Store Connect; nothing was queued.")
        return .unchanged(note: note, withdrew: withdrew)
    }

    /// "R$ 112,00 isn't a price point in Brazil. Nearest: R$ 109,90 or R$ 114,90."
    private func notAPricePoint(_ price: Decimal, in territory: Territory, ladder: PricePointLadder) -> Outcome {
        let currency = CurrencyFormat.forCurrency(territory.currencyCode)
        let below = ladder.points.last { $0.customerPrice < price }?.customerPrice
        let above = ladder.points.first { $0.customerPrice > price }?.customerPrice
        let nearest = [below, above].compactMap(\.self)
        let options = if let below, let above {
            String(localized: "\(currency.format(below)) or \(currency.format(above))")
        } else {
            nearest.map(currency.format).joined()
        }
        let reason = nearest.isEmpty
            ? String(localized: "\(currency.format(price)) isn’t a price point in \(territory.name), which has none. Use get_price_points.")
            : String(localized: "\(currency.format(price)) isn’t a price point in \(territory.name). Nearest: \(options). Propose one of them.")
        return .refused(reason: reason, nearest: nearest)
    }

    private func queuedPrice(_ change: PendingChange, in territory: Territory) -> Decimal? {
        CurrencyFormat.forCurrency(territory.currencyCode).parse(change.newValue)
    }
}
