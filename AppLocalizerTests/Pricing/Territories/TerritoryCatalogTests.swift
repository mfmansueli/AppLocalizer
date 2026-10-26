//
//  TerritoryCatalogTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("TerritoryCatalog")
struct TerritoryCatalogTests {
    private let catalog = TerritoryCatalog.standard

    @Test func has175UniqueTerritories() {
        #expect(catalog.count == 175)
        #expect(Set(catalog.territories.map(\.id)).count == 175)
        #expect(Set(catalog.territories.map(\.alpha2)).count == 175)
    }

    @Test func idsAreAlpha3AndAlpha2CodesAreTwoLetters() {
        #expect(catalog.territories.allSatisfy { $0.id.count == 3 && $0.id == $0.id.uppercased() })
        #expect(catalog.territories.allSatisfy { $0.alpha2.count == 2 && $0.alpha2 == $0.alpha2.uppercased() })
    }

    @Test func everyTerritoryHasACurrencyFormatAndASaneTaxRate() {
        let known = Set(CurrencyFormat.all.map(\.code))
        #expect(catalog.territories.allSatisfy { known.contains($0.currencyCode) })
        #expect(catalog.territories.allSatisfy { $0.taxRate >= 0 && $0.taxRate < 1 })
    }

    @Test func brazilHasItsTableValues() throws {
        let brazil = try #require(catalog.territory(alpha3: "BRA"))
        #expect(brazil.alpha2 == "BR")
        #expect(brazil.name == "Brazil")
        #expect(brazil.region == .americas)
        #expect(brazil.currencyCode == "BRL")
        #expect(brazil.taxRate == 0)
    }

    @Test func germanyIncludesVAT() throws {
        let germany = try #require(catalog.territory(alpha2: "DE"))
        #expect(germany.taxRate == PricingFixtures.money("0.19"))
        #expect(germany.currencyCode == "EUR")
        #expect(germany.region == .europe)
    }

    @Test(arguments: ["BR", "br", "BRA", "bra", " Bra "])
    func findsBrazilByEitherCodeInAnyCase(code: String) {
        #expect(catalog.territory(code: code)?.id == "BRA")
    }

    @Test(arguments: ["UK", "EL", "BRAZ", "", "B"])
    func unknownCodesFindNothing(code: String) {
        #expect(catalog.territory(code: code) == nil)
    }

    @Test func kosovoUsesAppStoreConnectsXKS() {
        #expect(catalog.territory(alpha2: "XK")?.id == "XKS")
    }

    @Test func regionsPartitionTheCatalog() {
        let counts = TerritoryRegion.allCases.map { catalog.territories(in: $0).count }
        #expect(counts.allSatisfy { $0 > 0 })
        #expect(counts.reduce(0, +) == 175)
    }

    @Test func regionCodesRoundTrip() {
        for region in TerritoryRegion.allCases {
            #expect(TerritoryRegion(code: region.code) == region)
        }
        #expect(TerritoryRegion(code: "X") == nil)
        #expect(TerritoryRegion.africaMiddleEast.title == "Africa & Middle East")
    }

    @Test func flagsAreBuiltFromTheAlpha2Code() throws {
        #expect(try PricingFixtures.territory("US").flag == "🇺🇸")
        #expect(try PricingFixtures.territory("JP").flag == "🇯🇵")
    }

    @Test func referenceNameSaysUKForTheUnitedKingdom() throws {
        #expect(try PricingFixtures.territory("GB").referenceName == "UK")
        #expect(try PricingFixtures.territory("US").referenceName == "US")
    }

    @Test func tableRowsParseAndRejectBadInput() {
        let row = Territory(tableRow: "BRA|BR|Brazil|A|BRL|0|-10|-52")
        #expect(row?.id == "BRA")
        #expect(row?.latitude == -10)
        #expect(Territory(tableRow: "BRA|BR|Brazil|Z|BRL|0|-10|-52") == nil)
        #expect(Territory(tableRow: "BRA|BR|Brazil") == nil)
    }
}
