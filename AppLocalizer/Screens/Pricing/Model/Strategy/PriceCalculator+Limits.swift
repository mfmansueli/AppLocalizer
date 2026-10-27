//
//  PriceCalculator+Limits.swift
//  AppLocalizer
//

import Foundation

extension PriceCalculator {
    /// The target after discount only, the floor, the ceiling, minimum
    /// proceeds and never raise, with one step each.
    struct LimitedTarget {
        var value: Decimal
        var adjustment: PriceAdjustment
        var steps: [String]
        var floor: Decimal
        var minimum: Decimal?
    }

    /// The price point a limited target lands on, and the last step.
    struct SnappedPrice {
        var point: PricePoint
        var step: String
    }

    private static let epsilon = Decimal(1) / 1000

    func applyLimits(to target: Decimal, input: PriceCalculationInput, strategy: PricingStrategy) -> LimitedTarget {
        let money = CurrencyFormat.forCurrency(input.territory.currencyCode)
        let toLocal = input.basePrice * input.equalizationMultiplier
        var value = target
        var adjustment: PriceAdjustment?
        var steps: [String] = []
        if strategy.discountOnly, value > input.equalizedPrice + Self.epsilon {
            value = input.equalizedPrice
            steps.append("Discount only → capped at the equalized price")
            adjustment = .cappedAtEqualized
        }
        let floor = strategy.floor * toLocal
        let floorText = strategy.floor.percentText + "% of base = " + money.format(floor)
        if value < floor {
            value = floor
            steps.append("Below the floor (" + floorText + ") → raised to the floor")
            adjustment = .raisedToFloor
        } else {
            steps.append("Above the floor (" + floorText + ")")
            adjustment = adjustment ?? .aboveFloor
        }
        let ceiling = strategy.ceiling * toLocal
        if !strategy.discountOnly, value > ceiling {
            value = ceiling
            steps.append("Above the ceiling (" + strategy.ceiling.percentText + "% of base) → lowered to " + money.format(ceiling))
            adjustment = .loweredToCeiling
        }
        var minimum: Decimal?
        if let proceeds = strategy.minimumProceeds, proceeds > 0 {
            let local = commission.customerPrice(forProceeds: proceeds * input.equalizationMultiplier, taxRate: input.territory.taxRate)
            minimum = local
            if value < local {
                value = local
                steps.append("Raised so proceeds stay at least " + baseFormat(strategy).format(proceeds))
                adjustment = .minimumProceeds
            }
        }
        if strategy.neverRaise, let current = input.currentPrice, value > current + Self.epsilon {
            value = current
            steps.append("Never raise → kept at the current price")
            adjustment = .neverRaise
        }
        return LimitedTarget(value: value, adjustment: adjustment ?? .aboveFloor, steps: steps, floor: floor, minimum: minimum)
    }

    /// Nearest point with the preferred ending. A price raised to the floor
    /// (or to the minimum proceeds) goes up to the nearest point at or above
    /// it instead of rounding back under.
    func snap(_ limited: LimitedTarget, input: PriceCalculationInput, strategy: PricingStrategy) -> SnappedPrice {
        let money = CurrencyFormat.forCurrency(input.territory.currencyCode)
        let ladder = input.ladder
        let rounding = strategy.rounding
        let nearest = ladder.nearest(to: limited.value, rounding: rounding) ?? offLadderPoint(limited.value, territory: input.territory)
        let bound: (value: Decimal, name: String)? = switch limited.adjustment {
        case .raisedToFloor: (limited.floor, "the floor")
        case .minimumProceeds: limited.minimum.map { ($0, "the minimum proceeds") }
        default: nil
        }
        if let bound, nearest.customerPrice < bound.value - Self.epsilon,
           let raised = ladder.lowest(atOrAbove: bound.value, rounding: rounding)
        {
            return SnappedPrice(point: raised, step: "Nearest price point at or above " + bound.name + " → " + money.format(raised.customerPrice))
        }
        return SnappedPrice(point: nearest, step: "Nearest price point → " + money.format(nearest.customerPrice))
    }
}
