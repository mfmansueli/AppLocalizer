//
//  QueuedPrice.swift
//  AppLocalizer
//

import Foundation

/// A territory's price as it waits in Review & Push. The queue is the source
/// of truth, so a row shows this after navigating away or relaunching, and
/// goes back to today's price when the change is discarded.
struct QueuedPrice: Hashable, Sendable {
    var changeID: PendingChange.ID
    var price: Decimal
    var pricePointID: String?
    var source: ChangeSource

    /// Reads a queued price change back, or nil if it isn't one AppLocalizer wrote.
    init?(change: PendingChange, territory: Territory) {
        guard let price = CurrencyFormat.forCurrency(territory.currencyCode).parse(change.newValue) else { return nil }
        changeID = change.id
        self.price = price
        source = change.source
        pricePointID = change.requests.first.flatMap { request in
            request.body.flatMap { try? JSONDecoder().decode(SubscriptionPriceCreateRequest.self, from: $0) }?.pricePointID
        }
    }

    init(changeID: PendingChange.ID, price: Decimal, pricePointID: String?, source: ChangeSource) {
        self.changeID = changeID
        self.price = price
        self.pricePointID = pricePointID
        self.source = source
    }

    /// A hand edit wins over the strategy; suggestions and restores don't.
    var isManual: Bool {
        switch source {
        case .you, .restore, .assistant: true
        case .suggestion, .machineTranslation: false
        }
    }
}
