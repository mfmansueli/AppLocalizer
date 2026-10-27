//
//  PricePointLadder.swift
//  AppLocalizer
//

import Foundation

/// Apple's price points for one territory, lowest first. Every proposed price
/// lands on one of these: snapping prefers the currency's usual ending
/// (`PriceEnding`) and moves between points of that ending.
struct PricePointLadder: Sendable {
    /// A preferred-ending point further from the target than this share of
    /// it (or two grid steps, whichever is wider) doesn't count, and the
    /// plain nearest point is used instead.
    static let endingTolerance = Decimal(10) / 100

    let territoryID: String
    let currencyCode: String
    /// Ascending by customer price, one point per price.
    let points: [PricePoint]

    init(territoryID: String, currencyCode: String, points: [PricePoint]) {
        self.territoryID = territoryID
        self.currencyCode = currencyCode
        var unique: [PricePoint] = []
        for point in points.sorted(by: { $0.customerPrice < $1.customerPrice })
            where unique.last?.customerPrice != point.customerPrice
        {
            unique.append(point)
        }
        self.points = unique
    }

    var isEmpty: Bool { points.isEmpty }

    /// The ending a rounding choice resolves to in this currency.
    func ending(for rounding: PriceRounding) -> PriceEnding {
        rounding.ending(forCurrency: currencyCode)
    }

    /// The point at exactly this price, if it is one.
    func point(at price: Decimal) -> PricePoint? {
        let index = firstIndex(atOrAbove: price)
        guard index < points.count, Self.isSame(points[index].customerPrice, price) else { return nil }
        return points[index]
    }

    /// The closest point, whatever its ending. Ties go to the higher point.
    func nearest(to target: Decimal) -> PricePoint? {
        let index = firstIndex(atOrAbove: target)
        let above = index < points.count ? points[index] : nil
        let below = index > 0 ? points[index - 1] : nil
        return Self.closer(below, above, to: target)
    }

    /// The point the rounding's ending picks for a target, e.g. R$ 109,90 for
    /// R$ 109,95. First the ending's own rounding (`PriceEnding.gridSnap`:
    /// round to the grid, then apply the ending, so Rp 204.480 → Rp 199.000)
    /// when the ladder has that price; otherwise the closest point with the
    /// ending within the tolerance; otherwise `nearest(to:)`.
    func nearest(to target: Decimal, rounding: PriceRounding) -> PricePoint? {
        let ending = ending(for: rounding)
        if let ideal = idealPoint(for: target, ending: ending) { return ideal }
        let index = firstIndex(atOrAbove: target)
        let limit = Self.tolerance(around: target, ending: ending)
        let below = points[..<index].reversed()
            .prefix { target - $0.customerPrice <= limit }
            .first { ending.matches($0.customerPrice) }
        let above = points[index...]
            .prefix { $0.customerPrice - target <= limit }
            .first { ending.matches($0.customerPrice) }
        return Self.closer(below, above, to: target) ?? nearest(to: target)
    }

    /// The lowest point with the rounding's ending at or above `target`: where
    /// a price raised to the floor lands. Falls back to the lowest point at or
    /// above, then to the highest point.
    func lowest(atOrAbove target: Decimal, rounding: PriceRounding) -> PricePoint? {
        let ending = ending(for: rounding)
        if let ideal = idealPoint(for: target, ending: ending), ideal.customerPrice >= target - Self.epsilon { return ideal }
        let index = firstIndex(atOrAbove: target - Self.epsilon)
        let limit = Self.tolerance(around: target, ending: ending)
        let candidates = points[index...]
        return candidates.prefix { $0.customerPrice - target <= limit }.first { ending.matches($0.customerPrice) }
            ?? candidates.first
            ?? points.last
    }

    /// Moves `steps` points of the rounding's ending up (positive) or down
    /// from `price`, which needn't be a point itself. Stops at the last point
    /// in that direction; nil when there's none.
    func step(from price: Decimal, by steps: Int, rounding: PriceRounding) -> PricePoint? {
        guard steps != 0 else { return point(at: price) ?? nearest(to: price, rounding: rounding) }
        let ending = ending(for: rounding)
        let preferred = walk(from: price, upward: steps > 0) { ending.matches($0.customerPrice) }
        let candidates = preferred.isEmpty ? walk(from: price, upward: steps > 0) { _ in true } : preferred
        guard !candidates.isEmpty else { return nil }
        return candidates[min(abs(steps), candidates.count) - 1]
    }

    /// The breakdown popover's chips: up to `count` points of the rounding's
    /// ending below and above `price`, with `price` itself in the middle when
    /// it's a point.
    func nearby(_ price: Decimal, count: Int = 3, rounding: PriceRounding) -> [PricePoint] {
        let below = (1...max(count, 1)).compactMap { step(from: price, by: -$0, rounding: rounding) }
        let above = (1...max(count, 1)).compactMap { step(from: price, by: $0, rounding: rounding) }
        let middle = point(at: price).map { [$0] } ?? []
        return unique(below.reversed() + middle + above)
    }

    // MARK: - Private

    private static let epsilon = Decimal(1) / 1000

    private static func tolerance(around target: Decimal, ending: PriceEnding) -> Decimal {
        let value = target.doubleValue
        let steps = value > 0 ? Decimal(exactly: ending.gridStep(around: value) * 2) : 0
        return max(target.magnitude * endingTolerance, steps)
    }

    private static func isSame(_ lhs: Decimal, _ rhs: Decimal) -> Bool {
        (lhs - rhs).magnitude < epsilon
    }

    private static func closer(_ below: PricePoint?, _ above: PricePoint?, to target: Decimal) -> PricePoint? {
        guard let below else { return above }
        guard let above else { return below }
        return target - below.customerPrice < above.customerPrice - target ? below : above
    }

    /// The ending's own rounding of `target`, when the ladder has that price.
    private func idealPoint(for target: Decimal, ending: PriceEnding) -> PricePoint? {
        let ideal = ending.gridSnap(target.doubleValue)
        guard ideal > 0 else { return nil }
        return point(at: Decimal(Int64((ideal * 100).rounded())) / 100)
    }

    /// Index of the first point priced at or above `price` (binary search).
    private func firstIndex(atOrAbove price: Decimal) -> Int {
        var low = 0
        var high = points.count
        while low < high {
            let mid = (low + high) / 2
            if points[mid].customerPrice < price { low = mid + 1 } else { high = mid }
        }
        return low
    }

    /// Points strictly past `price` in one direction that pass `include`,
    /// nearest first.
    private func walk(from price: Decimal, upward: Bool, include: (PricePoint) -> Bool) -> [PricePoint] {
        if upward {
            let start = firstIndex(atOrAbove: price + Self.epsilon)
            return points[start...].filter(include)
        }
        let end = firstIndex(atOrAbove: price - Self.epsilon)
        return points[..<end].reversed().filter(include)
    }

    private func unique(_ list: [PricePoint]) -> [PricePoint] {
        var seen = Set<Decimal>()
        return list.filter { seen.insert($0.customerPrice).inserted }
    }
}
