//
//  PriceMatrixModel+Views.swift
//  AppLocalizer
//

import Foundation

/// The matrix's prices as the other views show them: the tile map, the
/// histogram, the schedule's increases and each offer's derived prices.
/// Each reads the price a territory shows: the queued one, else today's.
extension PriceMatrixModel {
    /// Distance from Apple's equalized price for the rows the filters show.
    var histogram: PriceHistogram {
        PriceHistogram(prices: visibleRows.map { (shown: $0.shownPrice, equalized: $0.equalized) })
    }

    /// Every territory on the tile map, colored by `metric`.
    func tileMap(metric: TileMapMetric) -> PriceTileMap {
        PriceTileMap(rows: rows, metric: metric, basePrice: sheet.basePrice)
    }

    /// The tile map's hover card for one territory.
    func tileDetail(id: PricingRow.ID) -> PriceTileMap.Detail? {
        row(id: id).map { PriceTileMap.detail(for: $0, basePrice: sheet.basePrice) }
    }

    /// Territories whose queued price goes up, with their existing
    /// subscribers when `subscribers` knows them.
    func increaseConsent(subscribers: [String: Int]?) -> PriceIncreaseConsent {
        PriceIncreaseConsent(rows: rows, subscribers: subscribers)
    }

    /// The offer's price in every territory, from the price it shows,
    /// snapped to its price points; most-viewed territories first.
    func offerPrices(for offer: SubscriptionOffer) -> [OfferPrice] {
        rows.sorted(by: PricingRow.defaultOrder).map { row in
            OfferPricing.price(
                offer,
                subscriptionPrice: row.shownPrice,
                territory: row.territory,
                ladder: ladder(for: row),
                commission: calculator.commission
            )
        }
    }
}
