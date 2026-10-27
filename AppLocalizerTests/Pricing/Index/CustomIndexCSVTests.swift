//
//  CustomIndexCSVTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("CustomIndexCSV")
struct CustomIndexCSVTests {
    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    @Test func sampleFileMatches12TerritoriesAndFlagsUKAndEL() {
        let result = CustomIndexCSV.parse(PricingSampleData.customIndexCSV)
        #expect(result.kind == .factor)
        #expect(result.rows.count == 12)
        #expect(result.errors.isEmpty)
        #expect(result.factors["BRA"] == money("0.55"))
        #expect(result.factors["EGY"] == money("0.25"))
        #expect(result.unmatched.map(\.code) == ["UK", "EL"])
        #expect(result.unmatched.map(\.line) == [14, 15])
        #expect(result.unmatched.map { $0.suggestion?.alpha2 } == ["GB", "GR"])
    }

    @Test func importBecomesACustomIndex() {
        let result = CustomIndexCSV.parse(PricingSampleData.customIndexCSV)
        let index = result.index(fileName: "Regional reference prices.csv", importedOn: PricingSampleData.date("2026-10-20"))
        #expect(index.source == .custom)
        #expect(index.coverage == 12)
        #expect(index.publisher == "Regional reference prices.csv")
        #expect(index.edition.label == "Imported Oct 20, 2026")
        #expect(index.edition.badge == "Custom")
        #expect(index.level(for: "MEX") == money("0.7"))
    }

    @Test func readsFilesWithoutAHeader() {
        let result = CustomIndexCSV.parse("BR,0.55\nbra,0.6\nmex,0.7")
        #expect(result.rows.map(\.territory.id) == ["BRA", "MEX"])
        #expect(result.errors.map(\.line) == [2])
        #expect(result.errors.first?.message == "Line 2: Brazil appears twice; the first value is kept.")
    }

    @Test(arguments: ["code;factor\nBR;0,55\nMX;0,7", "code\tfactor\nBR\t0.55\nMX\t0.7", "\"code\",\"factor\"\n\"BR\",\"0.55\"\n\"MX\",\"0.7\""])
    func acceptsSemicolonsTabsAndQuotes(text: String) {
        let result = CustomIndexCSV.parse(text)
        #expect(result.factors == ["BRA": money("0.55"), "MEX": money("0.7")])
        #expect(result.errors.isEmpty)
    }

    @Test func skipsBlankLinesAndComments() {
        let result = CustomIndexCSV.parse("# exported from a sheet\ncode,factor\n\nBR,0.55\n   \n")
        #expect(result.rows.count == 1)
        #expect(result.rows.first?.line == 4)
    }

    @Test func reportsBadLines() {
        let result = CustomIndexCSV.parse("code,factor\nBR\nMX,abc\nAR,-0.5\n,0.4")
        #expect(result.rows.isEmpty)
        #expect(result.errors.map(\.line) == [2, 3, 4, 5])
        #expect(result.errors[0].message == "Line 2 needs a territory code and a value.")
        #expect(result.errors[1].message == "Line 3: “abc” isn’t a positive number.")
    }

    @Test func unmatchedCodesWithoutAnAliasHaveNoSuggestion() {
        let result = CustomIndexCSV.parse("code,factor\nZZ,0.5\nKOS,0.5")
        #expect(result.unmatched.map(\.code) == ["ZZ", "KOS"])
        #expect(result.unmatched[0].suggestion == nil)
        #expect(result.unmatched[1].suggestion?.id == "XKS")
    }

    @Test func emptyFileIsAnError() {
        let result = CustomIndexCSV.parse("\n\n")
        #expect(result.isEmpty)
        #expect(result.errors == [CustomIndexImport.LineError(line: 0, message: "The file is empty.")])
    }

    // MARK: - Reference prices

    @Test func referencePricesBecomeFactorsAgainstTheBase() {
        let text = "territory,reference price\nUS,10\nBR,30.25\nDE,9.50"
        let multipliers: [String: Decimal] = ["BRA": money("5.5"), "DEU": money("0.95")]
        let result = CustomIndexCSV.parse(text) { multipliers[$0.id] }
        #expect(result.kind == .referencePrice)
        #expect(result.factors == ["USA": 1, "BRA": money("0.55"), "DEU": 1])
        #expect(result.rows.first { $0.territory.id == "BRA" }?.value == money("30.25"))
    }

    @Test func referencePricesNeedTheBaseTerritory() {
        let result = CustomIndexCSV.parse("code,local price\nBR,30") { _ in 5 }
        #expect(result.kind == .referencePrice)
        #expect(result.rows.isEmpty)
        #expect(result.errors.first?.message == "Reference prices need a row for United States, the base territory.")
    }

    @Test func referencePricesWithoutAnEqualizationAreReported() {
        let result = CustomIndexCSV.parse("code,reference\nUS,10\nBR,30") { _ in nil }
        #expect(result.factors == ["USA": 1])
        #expect(result.errors.first?.message == "Line 3: no equalized price to compare Brazil with.")
    }
}
