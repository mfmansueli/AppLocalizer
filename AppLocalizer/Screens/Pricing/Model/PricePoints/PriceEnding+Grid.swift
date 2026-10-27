//
//  PriceEnding+Grid.swift
//  AppLocalizer
//

import Foundation

// The design prototype's per-currency price grid, ported as-is. It shapes
// the simulated ladders and decides whether a real price point "has" an
// ending. Plain Double math, mirroring the prototype's JavaScript; results
// are rounded to cents before they become Decimal prices.
extension PriceEnding {
    /// Whether `price` sits on this ending's grid, e.g. R$ 109,90 for
    /// `.ninety` but not R$ 107,90 or R$ 109,99.
    func matches(_ price: Decimal) -> Bool {
        let value = price.doubleValue
        guard value > 0 else { return false }
        if abs(gridSnap(value) - value) < 0.001 { return true }
        // Just under a power of ten, the grid of the next decade applies
        // (MX$ 990.00 comes from rounding MX$ 1,000).
        let nextPower = pow(10, floor(log10(value)) + 1)
        return abs(gridSnap(nextPower) - value) < 0.001
    }

    /// The prototype's `snap`: rounds to the grid around `value`, then takes
    /// the ending off (−0.01 for .99, −0.10 for .90, −1 for MX$ 549…).
    func gridSnap(_ value: Double) -> Double {
        guard value > 0 else { return 0 }
        let exponent = floor(log10(value))
        let step = gridStep(around: value)
        var base = jsRound(value / step) * step
        if base <= 0 { base = step }
        var offset = endingOffset(exponent: exponent)
        if offset >= base { offset = 0 }
        return jsRound((base - offset) * 100) / 100
    }

    /// The grid's spacing around `value`: half a unit of the second digit
    /// below 5, one unit from 5 up, never under 1 (0.50 for .99).
    func gridStep(around value: Double) -> Double {
        let exponent = floor(log10(value))
        let mantissa = value / pow(10, exponent)
        var step = pow(10, exponent - 1) * (mantissa < 5 ? 0.5 : 1)
        step = max(step, self == .ninetyNine ? 0.5 : 1)
        if let digits = leadingDigits {
            let unit = pow(10, exponent - Double(digits))
            if unit >= 1, step < unit * 10 { step = unit * 10 }
        }
        return step
    }

    private func endingOffset(exponent: Double) -> Double {
        switch self {
        case .ninetyNine: 0.01
        case .ninety: 0.1
        case .ninetyEight: 0.02
        case .wholeUnits, .round: 0
        case .nineAfterTwoDigits, .nineAfterThreeDigits:
            nineOffset(exponent: exponent)
        case .eight: 2 * pow(10, max(0, exponent - 2))
        }
    }

    private func nineOffset(exponent: Double) -> Double {
        let unit = pow(10, exponent - Double(leadingDigits ?? 2))
        return unit < 1 ? 0 : unit
    }

    /// JavaScript's `Math.round`: halves go up.
    private func jsRound(_ value: Double) -> Double {
        floor(value + 0.5)
    }
}
