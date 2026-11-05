//
//  SubscriptionStartingPriceError.swift
//  AppLocalizer
//

import Foundation

/// Why a subscription's starting price couldn't be set.
enum SubscriptionStartingPriceError: LocalizedError, Hashable, Sendable {
    /// Apple has no price point at that price in the territory.
    case noPricePoint(price: Decimal, territoryID: String, nearest: [Decimal])

    var errorDescription: String? {
        switch self {
        case let .noPricePoint(price, territoryID, nearest):
            let territory = TerritoryCatalog.standard.territory(alpha3: territoryID)
            let currency = CurrencyFormat.forCurrency(territory?.currencyCode ?? "USD")
            let place = territory?.name ?? territoryID
            let options = nearest.map { currency.format($0) }.formatted(.list(type: .or))
            let suggestion = nearest.isEmpty ? "" : String(localized: " Try \(options).")
            return String(localized: "Apple has no \(currency.format(price)) price in \(place).\(suggestion) Discard this change and set the price in Pricing.")
        }
    }
}
