//
//  PriceHistogram.swift
//  AppLocalizer
//

import Foundation

/// Territories bucketed by distance from Apple's equalized price, in 10%
/// steps from −80% to +40% (13 buckets). Values outside are counted in the
/// end buckets.
struct PriceHistogram: Hashable, Sendable {
    /// How a bucket is colored: teal below, orange above, neutral around 0.
    enum Tone: Hashable, Sendable {
        case below
        case atEqualized
        case above
    }

    struct Bucket: Hashable, Sendable, Identifiable {
        /// Lower bound in whole percent: −80, −70 … 40.
        var lowerBound: Int
        var count: Int
        var tone: Tone
        var id: Int { lowerBound }

        /// "−80%", "0%", "+10%" (minus is U+2212).
        var label: String { PricingText.signedPercent(lowerBound) }
    }

    static let lowestBound = -80
    static let highestBound = 40

    var buckets: [Bucket]
    /// The median distance as a fraction (−0.5 = 50% below equalized).
    var median: Double
    var belowCount: Int
    var atEqualizedCount: Int
    var aboveCount: Int

    /// Distances as fractions: shown price ÷ equalized − 1.
    init(distances: [Double]) {
        var counts = Array(repeating: 0, count: (Self.highestBound - Self.lowestBound) / 10 + 1)
        for distance in distances {
            let clamped = min(max(distance, -0.8), 0.49)
            let index = Int(((clamped + 0.8) * 10 + 1e-9).rounded(.down))
            counts[min(counts.count - 1, index)] += 1
        }
        buckets = counts.enumerated().map { offset, count in
            let lowerBound = Self.lowestBound + offset * 10
            let middle = Double(lowerBound) / 100 + 0.05
            let tone: Tone = abs(middle) < 0.06 ? .atEqualized : middle < 0 ? .below : .above
            return Bucket(lowerBound: lowerBound, count: count, tone: tone)
        }
        let sorted = distances.sorted()
        median = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
        belowCount = distances.count { $0 < -0.005 }
        atEqualizedCount = distances.count { abs($0) <= 0.005 }
        aboveCount = distances.count { $0 > 0.005 }
    }

    /// One distance per territory: the proposed price where there is one,
    /// otherwise the current price, against the equalized price.
    init(prices: [(shown: Decimal, equalized: Decimal)]) {
        self.init(distances: prices.compactMap { price in
            price.equalized > 0 ? (price.shown / price.equalized - 1).doubleValue : nil
        })
    }

    /// The tallest bucket, for scaling bars.
    var maximumCount: Int { buckets.map(\.count).max() ?? 0 }

    /// "Median −50% vs equalized · 165 below · 10 at equalized · 0 above".
    var summary: String {
        let percent = Int((median * 100 + 0.5).rounded(.down))
        return "Median " + (median < 0 ? "−" : "+") + "\(abs(percent))% vs equalized · \(belowCount) below · "
            + "\(atEqualizedCount) at equalized · \(aboveCount) above"
    }
}
