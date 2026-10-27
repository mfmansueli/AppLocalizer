//
//  PricingFixtures.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Shared lookups and hand-built values for the pricing tests.
enum PricingFixtures {
    /// The prototype's sample world, with the bundled index snapshot.
    static var sample: PricingSampleData { .shared }

    static let catalog = TerritoryCatalog.standard

    /// A territory by alpha-2 or alpha-3 code, failing the test when missing.
    static func territory(_ code: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Territory {
        try #require(catalog.territory(code: code), "No territory \(code)", sourceLocation: sourceLocation)
    }

    /// The sample's Annual input ($39.99) for a territory.
    static func annualInput(_ code: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> PriceCalculationInput {
        try sample.input(for: territory(code, sourceLocation: sourceLocation), subscription: .annual)
    }

    /// An exact decimal from its text: `money("109.90")`.
    static func money(_ text: String) -> Decimal {
        Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) ?? .nan
    }

    /// A ladder of plain prices whose proceeds equal the price.
    static func ladder(_ prices: [String], currency: String = "USD", territoryID: String = "USA") -> PricePointLadder {
        PricePointLadder(
            territoryID: territoryID,
            currencyCode: currency,
            points: prices.map { PricePoint(customerPrice: money($0), proceeds: money($0)) }
        )
    }

    /// The customer prices of some points, for readable comparisons.
    static func prices(_ points: [PricePoint]) -> [Decimal] {
        points.map(\.customerPrice)
    }

    /// A snapshot with hand-written levels per source, all editions dated
    /// 2026-01-01.
    static func snapshot(_ levels: [PriceIndexSource: [String: Decimal]]) -> PriceIndexSnapshot {
        var indices: [PriceIndexSource: PriceIndex] = [:]
        for (source, values) in levels {
            let edition = PriceIndexEdition(
                label: "Test edition",
                badge: source.shortName + " test",
                provenanceLabel: source.shortName + " test",
                date: PricingSampleData.date("2026-01-01"),
                newerEdition: nil
            )
            indices[source] = PriceIndex(source: source, edition: edition, levels: values)
        }
        return PriceIndexSnapshot(
            isApproximate: true,
            note: "Test snapshot",
            snapshotDate: PricingSampleData.date("2026-01-01"),
            referenceTerritoryID: "USA",
            indices: indices
        )
    }
}
