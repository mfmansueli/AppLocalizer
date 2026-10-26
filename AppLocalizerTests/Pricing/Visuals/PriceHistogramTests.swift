//
//  PriceHistogramTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PriceHistogram")
struct PriceHistogramTests {
    @Test func hasThirteenTenPointBuckets() {
        let histogram = PriceHistogram(distances: [])
        #expect(histogram.buckets.map(\.lowerBound) == Array(stride(from: -80, through: 40, by: 10)))
        #expect(histogram.buckets.first?.label == "−80%")
        #expect(histogram.buckets.last?.label == "+40%")
        #expect(histogram.maximumCount == 0)
        #expect(histogram.median == 0)
    }

    @Test func tonesSplitAroundEqualized() {
        let tones = PriceHistogram(distances: []).buckets.map(\.tone)
        #expect(tones.prefix(7).allSatisfy { $0 == .below })
        #expect(tones[7] == .atEqualized)
        #expect(tones[8] == .atEqualized)
        #expect(tones.suffix(4).allSatisfy { $0 == .above })
    }

    @Test func distancesLandInTheirBucketAndClampAtTheEnds() {
        let histogram = PriceHistogram(distances: [-0.95, -0.8, -0.5, -0.4999, 0, 0.05, 0.12, 0.9])
        let counts = Dictionary(uniqueKeysWithValues: histogram.buckets.map { ($0.lowerBound, $0.count) })
        #expect(counts[-80] == 2)
        #expect(counts[-50] == 2)
        #expect(counts[0] == 2)
        #expect(counts[10] == 1)
        #expect(counts[40] == 1)
        #expect(histogram.maximumCount == 2)
    }

    @Test func summaryCountsBelowAtAndAbove() {
        let histogram = PriceHistogram(prices: [
            (shown: 50, equalized: 100),
            (shown: 100, equalized: 100),
            (shown: 110, equalized: 100),
            (shown: 5, equalized: 0),
        ])
        #expect(histogram.belowCount == 1)
        #expect(histogram.atEqualizedCount == 1)
        #expect(histogram.aboveCount == 1)
        #expect(histogram.summary == "Median +0% vs equalized · 1 below · 1 at equalized · 1 above")
    }

    @Test func sampleSuggestionsAreMostlyBelowEqualized() {
        let sample = PricingFixtures.sample
        let prices = sample.catalog.territories.map { territory in
            (
                shown: sample.recommendation(for: territory, subscription: .annual).price.customerPrice,
                equalized: sample.equalizedPrice(for: territory, subscription: .annual)
            )
        }
        let histogram = PriceHistogram(prices: prices)
        #expect(histogram.summary == "Median −50% vs equalized · 165 below · 10 at equalized · 0 above")
        #expect(histogram.buckets.map(\.count) == [13, 47, 34, 21, 24, 9, 12, 5, 10, 0, 0, 0, 0])
    }
}
