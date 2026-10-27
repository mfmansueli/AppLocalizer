//
//  PriceIndexSnapshotTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PriceIndexSnapshot")
struct PriceIndexSnapshotTests {
    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    private func bundled() throws -> PriceIndexSnapshot {
        try PriceIndexSnapshot.bundled()
    }

    // MARK: - Bundled snapshot

    @Test func bundledSnapshotIsMarkedApproximate() throws {
        let snapshot = try bundled()
        #expect(snapshot.isApproximate)
        #expect(!snapshot.note.isEmpty)
        #expect(snapshot.referenceTerritoryID == "USA")
        #expect(snapshot.snapshotDate == PricingSampleData.date("2026-10-01"))
    }

    @Test func bundledCoverageMatchesThePrototype() throws {
        let snapshot = try bundled()
        #expect(snapshot.coverage(of: .worldBank) == 165)
        #expect(snapshot.coverage(of: .bigMac) == 74)
        #expect(snapshot.coverage(of: .imf) == 161)
        #expect(snapshot.coverage(of: .custom) == 0)
        #expect(snapshot.index(.bigMac)?.coverageLabel(of: 175) == "74 of 175 territories")
    }

    @Test func bigMacEuroAreaEntryIsSharedBy21Territories() throws {
        let snapshot = try bundled()
        for territoryID in ["DEU", "FRA", "ITA", "ESP", "NLD"] {
            #expect(snapshot.level(.bigMac, territoryID: territoryID) == money("0.95"))
        }
        #expect(snapshot.level(.bigMac, territoryID: "BRA") == money("0.75"))
        #expect(snapshot.level(.bigMac, territoryID: "JPN") == money("0.55"))
    }

    @Test func levelsAreExactDecimals() throws {
        let snapshot = try bundled()
        #expect(snapshot.level(.worldBank, territoryID: "BRA") == money("0.5"))
        #expect(snapshot.level(.worldBank, territoryID: "DEU") == money("0.85"))
        #expect(snapshot.level(.imf, territoryID: "USA") == 1)
        #expect(snapshot.level(.worldBank, territoryID: "XXX") == nil)
    }

    @Test func editionsCarryTheirBadgesAndLabels() throws {
        let snapshot = try bundled()
        let bigMac = try #require(snapshot.index(.bigMac)?.edition)
        #expect(bigMac.label == "January 2026")
        #expect(bigMac.badge == "Big Mac Jan 26")
        #expect(bigMac.provenanceLabel == "Big Mac, Jan 2026")
        #expect(bigMac.newerEditionLabel == "July 2026 available")
        let worldBank = try #require(snapshot.index(.worldBank)?.edition)
        #expect(worldBank.label == "2024 data, published 2025")
        #expect(worldBank.badge == "WB 2024")
        #expect(worldBank.newerEditionLabel == nil)
        #expect(snapshot.index(.imf)?.edition.badge == "IMF Apr 26")
    }

    @Test func onlyWorldBankIsOlderThanAYearAtThePush() throws {
        let snapshot = try bundled()
        let now = PricingSampleData.pushDate
        #expect(snapshot.index(.worldBank)?.edition.isStale(asOf: now) == true)
        #expect(snapshot.index(.bigMac)?.edition.isStale(asOf: now) == false)
        #expect(snapshot.index(.imf)?.edition.isStale(asOf: now) == false)
    }

    @Test func stalenessStartsTheDayAfterTheAnniversary() {
        let edition = PriceIndexEdition(label: "", badge: "", provenanceLabel: "", date: PricingSampleData.date("2025-07-01"), newerEdition: nil)
        #expect(!edition.isStale(asOf: PricingSampleData.date("2026-07-01")))
        #expect(edition.isStale(asOf: PricingSampleData.date("2026-07-02")))
    }

    @Test func missingResourceThrows() {
        #expect(throws: PriceIndexSnapshot.LoadingError.missingResource) {
            try PriceIndexSnapshot.bundled(in: Bundle(for: NSString.self))
        }
    }

    // MARK: - JSON

    @Test func decodesFactorsSharedEntriesAndSkipsUnknownSources() throws {
        let json = """
        {
          "approximate": false,
          "note": "Test",
          "snapshotDate": "2026-03-01",
          "referenceTerritory": "USA",
          "sources": {
            "bigMac": {
              "edition": { "label": "L", "badge": "B", "provenanceLabel": "P", "date": "2026-01-15" },
              "factors": { "USA": 1, "BRA": 0.75 },
              "shared": [ { "name": "Euro area", "factor": 0.95, "territories": ["DEU", "FRA"] } ]
            },
            "unknown": {
              "edition": { "label": "L", "badge": "B", "provenanceLabel": "P", "date": "2026-01-15" },
              "factors": { "USA": 1 }
            }
          }
        }
        """
        let snapshot = try PriceIndexSnapshot(jsonData: Data(json.utf8))
        #expect(!snapshot.isApproximate)
        #expect(snapshot.indices.count == 1)
        #expect(snapshot.coverage(of: .bigMac) == 4)
        #expect(snapshot.level(.bigMac, territoryID: "FRA") == money("0.95"))
        #expect(snapshot.index(.bigMac)?.edition.newerEdition == nil)
    }

    @Test func rejectsBadDates() {
        let json = #"{"approximate": true, "note": "", "snapshotDate": "March 2026", "referenceTerritory": "USA", "sources": {}}"#
        #expect(throws: (any Error).self) {
            try PriceIndexSnapshot(jsonData: Data(json.utf8))
        }
    }

    // MARK: - Medians and imports

    @Test func regionMediansTakeTheUpperMiddleValue() {
        let snapshot = PricingFixtures.snapshot([
            .worldBank: ["USA": 1, "BRA": money("0.5"), "MEX": money("0.6"), "ARG": money("0.45"), "DEU": money("0.85")],
        ])
        let medians = snapshot.regionMedians(of: .worldBank, catalog: PricingFixtures.catalog)
        #expect(medians[.americas] == money("0.6"))
        #expect(medians[.europe] == money("0.85"))
        #expect(medians[.asiaPacific] == nil)
        #expect(snapshot.regionMedians(of: .bigMac, catalog: PricingFixtures.catalog).isEmpty)
    }

    @Test func bundledWorldBankRegionMedians() throws {
        let medians = try bundled().regionMedians(of: .worldBank, catalog: PricingFixtures.catalog)
        #expect(medians[.americas] == money("0.55"))
        #expect(medians[.europe] == money("0.62"))
        #expect(medians[.asiaPacific] == money("0.5"))
        #expect(medians[.africaMiddleEast] == money("0.4"))
    }

    @Test func addingAnIndexReplacesTheSource() throws {
        let snapshot = try bundled()
        let custom = PricingSampleData.customIndex()
        let withCustom = snapshot.adding(custom)
        #expect(withCustom.coverage(of: .custom) == 12)
        #expect(withCustom.index(.custom)?.publisher == "Regional reference prices.csv")
        #expect(withCustom.coverage(of: .worldBank) == 165)
        #expect(snapshot.coverage(of: .custom) == 0)
    }

    @Test func emptySnapshotHasNoIndices() {
        #expect(PriceIndexSnapshot.empty.indices.isEmpty)
        #expect(PriceIndexSnapshot.empty.coverage(of: .worldBank) == 0)
    }

    @Test func sourcesDescribeThemselves() {
        #expect(PriceIndexSource.allCases.map(\.name) == ["Big Mac Index", "World Bank PPP price level", "IMF implied PPP rate", "Custom index"])
        #expect(PriceIndexSource.bigMac.publisher == "The Economist")
        #expect(PriceIndexSource.custom.sourceURL == nil)
        #expect(PriceIndexSource.worldBank.sourceURL != nil)
    }
}
