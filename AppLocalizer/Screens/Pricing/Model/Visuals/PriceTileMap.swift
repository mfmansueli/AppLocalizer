//
//  PriceTileMap.swift
//  AppLocalizer
//

import Foundation

/// The tile map of one product: every territory at its `TileMapLayout`
/// cell, colored by a metric of the price it shows (the proposed one where
/// there is one, otherwise today's), with a legend and hover details.
struct PriceTileMap: Sendable {
    /// Which color a tile mixes into the content background.
    enum Tone: Hashable, Sendable {
        /// Within 3% of the base: the neutral fill.
        case neutral
        /// Below the base: teal.
        case below
        /// Above the base: orange.
        case above
        /// Along a one-way scale: the accent.
        case scale
    }

    struct Tile: Hashable, Sendable, Identifiable {
        /// The territory's App Store Connect ID.
        var id: String
        /// The two-letter code the tile shows.
        var code: String
        var cell: TileMapLayout.Cell
        var value: Double
        var tone: Tone
        /// 0…1: how far along its ramp the value is.
        var strength: Double
        /// "Brazil: R$ 109,90".
        var accessibilityLabel: String

        /// How much of the tone's color is mixed into the background.
        var colorShare: Double {
            switch tone {
            case .neutral: 0
            case .below, .above: 0.18 + strength * 0.70
            case .scale: 0.10 + strength * 0.76
            }
        }

        /// Dark enough that its code reads in white.
        var usesLightText: Bool { tone != .neutral && strength > 0.62 }
    }

    /// The hover card.
    struct Detail: Hashable, Sendable {
        /// "Brazil".
        var title: String
        /// Today's price: "R$ 219,90".
        var today: String
        /// The proposed price when it differs: "R$ 109,90".
        var proposed: String?
        /// "$19.98 · −50% vs base".
        var dollars: String
        /// "Feels like $40 · factor 0.50 · WB 2024".
        var feelsLike: String
    }

    /// Diverging tiles reach full strength this far from the base (70%).
    static let divergingRange = 0.7

    let metric: TileMapMetric
    let tiles: [Tile]
    /// The legend's ends: "−70%" and "+70%", or the lowest and highest value.
    let lowLabel: String
    let highLabel: String

    init(rows: [PricingRow], metric: TileMapMetric, basePrice: Decimal, layout: TileMapLayout = .standard, rates: ExchangeRates = .approximate) {
        self.metric = metric
        let values = rows.map { Self.value(of: $0, metric: metric, basePrice: basePrice, rates: rates) }
        let lowest = values.min() ?? 0
        let highest = values.max() ?? 0
        tiles = zip(rows, values).compactMap { row, value in
            guard let cell = layout[row.id] else { return nil }
            let (tone, strength) = metric.isDiverging
                ? Self.diverging(value)
                : (Tone.scale, (value - lowest) / max(0.0001, highest - lowest))
            return Tile(
                id: row.id,
                code: row.territory.alpha2,
                cell: cell,
                value: value,
                tone: tone,
                strength: strength,
                accessibilityLabel: "\(row.territory.name): \(row.currency.format(row.shownPrice))"
            )
        }
        switch metric {
        case .percentVsBase, .feelsLike:
            lowLabel = PricingText.signedPercent(-Int(Self.divergingRange * 100))
            highLabel = PricingText.signedPercent(Int(Self.divergingRange * 100))
        case .dollars:
            lowLabel = CurrencyFormat.usd.formatWhole(Decimal(lowest))
            highLabel = CurrencyFormat.usd.formatWhole(Decimal(highest))
        case .indexFactor:
            lowLabel = Decimal(lowest).fixed(2)
            highLabel = Decimal(highest).fixed(2)
        }
    }

    func tile(id: String) -> Tile? {
        tiles.first { $0.id == id }
    }

    /// What hovering a territory shows.
    static func detail(for row: PricingRow, basePrice: Decimal, rates: ExchangeRates = .approximate) -> Detail {
        let dollars = rates.dollars(row.shownPrice, currency: row.territory.currencyCode) ?? 0
        let vsBase = PriceChange(old: basePrice, new: dollars).percentText
        let feels = CurrencyFormat.usd.formatWhole(feelsLike(row) ?? 0)
        let factor = row.calculation.factor.fixed(2)
        return Detail(
            title: row.territory.name,
            today: row.currency.format(row.current.customerPrice),
            proposed: row.change.map { row.currency.format($0.new) },
            dollars: CurrencyFormat.usd.format(dollars) + " · " + String(localized: "\(vsBase) vs base"),
            feelsLike: String(localized: "Feels like \(feels) · factor \(factor)") + " · " + row.calculation.provenance.badge
        )
    }

    // MARK: - Private

    /// The shown price as the metric reads it.
    private static func value(of row: PricingRow, metric: TileMapMetric, basePrice: Decimal, rates: ExchangeRates) -> Double {
        let dollars = rates.dollars(row.shownPrice, currency: row.territory.currencyCode) ?? 0
        switch metric {
        case .percentVsBase:
            return basePrice > 0 ? (dollars / basePrice - 1).doubleValue : 0
        case .dollars:
            return dollars.doubleValue
        case .feelsLike:
            guard basePrice > 0, let feels = feelsLike(row) else { return 0 }
            return (feels / basePrice - 1).doubleValue
        case .indexFactor:
            return row.calculation.factor.doubleValue
        }
    }

    /// The shown price in base-currency terms, adjusted for what money buys
    /// there: price ÷ equalization multiplier ÷ factor.
    private static func feelsLike(_ row: PricingRow) -> Decimal? {
        let factor = row.recommendation?.factor ?? row.calculation.factor
        guard factor > 0, row.equalizationMultiplier > 0 else { return nil }
        return row.shownPrice / row.equalizationMultiplier / factor
    }

    private static func diverging(_ value: Double) -> (Tone, Double) {
        let strength = min(1, abs(value) / divergingRange)
        guard abs(value) >= 0.03 else { return (.neutral, strength) }
        return (value < 0 ? .below : .above, strength)
    }
}
