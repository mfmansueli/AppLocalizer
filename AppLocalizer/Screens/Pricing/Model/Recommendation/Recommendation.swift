//
//  Recommendation.swift
//  AppLocalizer
//

import Foundation

/// The suggestion for one territory: price, reason, confidence and what it's
/// based on.
struct Recommendation: Hashable, Sendable {
    var price: PricePoint
    var currentPrice: Decimal
    /// The suggestion is the current price (nothing to apply).
    var isUnchanged: Bool
    var isBaseTerritory: Bool
    /// Nil for the base territory.
    var confidence: RecommendationConfidence?
    /// One line of why: "Feels like 2.0× the US price · many page views, few
    /// starts".
    var reason: String
    /// "What it's based on" lines.
    var basis: [String]
    /// What the current price feels like locally, in the base currency.
    var feelsLike: Decimal
    /// The same for the suggested price.
    var feelsLikeSuggested: Decimal
    /// `feelsLike` ÷ base price.
    var ratio: Decimal
    /// `feelsLikeSuggested` ÷ base price.
    var suggestedRatio: Decimal
    /// The World Bank (or region median) factor behind "feels like".
    var factor: Decimal
    /// "$80" and "$40": `feelsLike` and `feelsLikeSuggested` in whole base
    /// currency units.
    var feelsLikeText: String
    var feelsLikeSuggestedText: String
    /// An earlier cut didn't lift starts, so the price holds.
    var isHolding: Bool
    /// Converts well, so the step was halved (intensity 50%).
    var isSoftStep: Bool
    /// The breakdown popover's one-liner and steps.
    var summary: String
    var steps: [String]
    /// The calculation behind the price; nil for the base territory.
    var calculation: PriceCalculation?

    /// "Likely holds people back": it feels at least 25% above the base
    /// price and the suggestion would change it.
    var likelyHoldsPeopleBack: Bool {
        !isUnchanged && ratio >= PriceRecommender.holdsBackRatio
    }

    /// "2.0×".
    var ratioText: String { PricingText.ratio(ratio) }

    /// "1.0×", at the suggested price.
    var suggestedRatioText: String { PricingText.ratio(suggestedRatio) }
}
