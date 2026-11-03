//
//  ProductPageTestExportTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The export for a test made by hand: both variants per language, named
/// for App Store Connect, and the steps.
@MainActor
@Suite("Product Page Optimization test export")
struct ProductPageTestExportTests {
    private typealias Fixtures = ProductPageTestFixtures

    @Test func writesBothVariantsOfEachLanguageWithClearNames() throws {
        let folder = try Fixtures.folder()
        let result = try ProductPageTestExport(request: Fixtures.request(in: folder)).write()

        #expect(result.folder == folder.appending(path: "Export"))
        #expect(result.files.map(\.lastPathComponent) == [
            "Header – Interface – en-US.png", "Header – Outcome – en-US.png",
            "Header – Interface – de-DE.png", "Header – Outcome – de-DE.png",
        ])
        #expect(try Data(contentsOf: result.files[1]) == Data("outcome en-US".utf8))
        #expect(try Data(contentsOf: result.files[2]) == Data("control de-DE".utf8))
        #expect(result.languagesWithoutControl.isEmpty)
    }

    @Test func aLanguageWithoutACurrentImageExportsOnlyItsVariant() throws {
        let folder = try Fixtures.folder()
        let result = try ProductPageTestExport(request: Fixtures.request(in: folder, locales: ["de-DE"], controls: false)).write()

        #expect(result.files.map(\.lastPathComponent) == ["Header – Outcome – de-DE.png"])
        #expect(result.languagesWithoutControl == ["de-DE"])
    }

    @Test func exportingAgainReplacesTheFiles() throws {
        let folder = try Fixtures.folder()
        let request = Fixtures.request(in: folder, locales: ["en-US"])
        _ = try ProductPageTestExport(request: request).write()
        try Data("outcome en-US, again".utf8).write(to: folder.appending(path: "header-outcome-en-US.png"))
        let result = try ProductPageTestExport(request: request).write()

        #expect(try Data(contentsOf: result.files[1]) == Data("outcome en-US, again".utf8))
    }

    @Test func theStepsNameTheTreatmentAndItsTab() throws {
        let folder = try Fixtures.folder()
        let search = Fixtures.request(in: folder, placement: .searchResults)
        let steps = ProductPageTestExport.steps(for: search)

        #expect(steps.contains("open Lumen’s Product Page Optimization"))
        #expect(steps.contains("one treatment named “Outcome”"))
        #expect(steps.contains("On the treatment’s Search Results tab, add “Search results – Outcome – …” in each language"))
        #expect(steps.contains("The “Interface” images are what the page shows now"))
        let name = ProductPageTestExport.fileName(placement: .searchResults, variant: "Outcome", locale: "ja", fileExtension: "")
        #expect(name == "Search results – Outcome – ja.png")
    }

    @Test func theSixteenByNineImageCanTestEitherPlacement() {
        #expect(ProductPageTestPlacement.placements(for: .header) == [.header])
        #expect(ProductPageTestPlacement.placements(for: .search) == [.searchResults])
        #expect(ProductPageTestPlacement.placements(for: .wide) == [.header, .searchResults])
        #expect(ProductPageTestPlacement.header.placementType == "PRODUCT_PAGE_HEADER_ASSET")
        #expect(ProductPageTestPlacement.searchResults.placementType == "APP_STORE_SEARCH_RESULTS_ASSET")
    }
}
