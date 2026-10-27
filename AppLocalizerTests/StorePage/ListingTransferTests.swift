//
//  ListingTransferTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ListingTransfer")
struct ListingTransferTests {
    private typealias Fixtures = StorePageFixtures

    /// Values that trip up naive CSV and XML writers.
    private static let trickyDescription = "\"Quoted\", with commas,\r\nCRLF and\nLF lines, <tags> & ampersands"

    private var trickyListing: StoreListing {
        var listing = Fixtures.listing()
        listing.edit(.description, in: .german, to: Self.trickyDescription)
        listing.edit(.promotionalText, in: .german, to: "  leading and trailing spaces  ")
        return listing
    }

    private func entries(_ document: ListingTransferDocument, for locale: String) -> [String: String] {
        document.entries.filter { $0.localeCode == locale }.reduce(into: [:]) { $0[$1.fieldName] = $1.value }
    }

    // MARK: - Round trips

    @Test(arguments: ListingTransferFormat.allCases)
    func roundTripKeepsEveryValue(format: ListingTransferFormat) throws {
        let listing = trickyListing
        let document = try ListingTransfer.read(ListingTransfer.export(listing, as: format), as: format)
        let german = entries(document, for: "de-DE")
        #expect(german["description"] == Self.trickyDescription)
        #expect(german["promotionalText"] == "  leading and trailing spaces  ")
        #expect(german["name"] == "Lumen: Tagebuch")
        #expect(listing.importPreview(for: document).changes.isEmpty)
        #expect(listing.importPreview(for: document).problems.isEmpty)
    }

    @Test(arguments: ListingTransferFormat.allCases)
    func roundTripIntoAFreshListingRecreatesTheEdits(format: ListingTransferFormat) throws {
        let document = try ListingTransfer.read(ListingTransfer.export(trickyListing, as: format), as: format)
        var listing = Fixtures.listing()
        let preview = listing.importPreview(for: document)
        #expect(preview.changes.map(\.key.id) == ["de-DE.promotionalText", "de-DE.description"])
        let applied = listing.apply(preview)
        #expect(applied == 2)
        #expect(listing == trickyListing)
    }

    @Test func sampleXLIFFRoundTripsWithoutChanges() throws {
        let listing = StorePageSampleData.fetchedListing
        let document = try ListingTransfer.read(ListingTransfer.export(listing, as: .xliff), as: .xliff)
        #expect(document.sourceLocaleCode == "en-US")
        #expect(!document.entries.contains { $0.localeCode == "en-US" })
        let preview = listing.importPreview(for: document)
        #expect(preview.changes.isEmpty)
        #expect(preview.problems.isEmpty)
    }

    // MARK: - Formats

    @Test func csvLayout() throws {
        let data = ListingTransfer.export(Fixtures.listing(), as: .csv)
        // A byte order mark, so Excel opens the file as UTF-8.
        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))
        let text = try #require(String(bytes: data.dropFirst(3), encoding: .utf8))
        #expect(text.hasPrefix("field,limit,en-US,de-DE\r\n"))
        #expect(text.contains("\r\nsubtitle,30 characters,\"Private notes, gentle prompts\",\"Private Notizen, sanfte Fragen\"\r\n"))
        #expect(text.contains("\r\nkeywords,100 bytes,\"diary,mood,gratitude\",\r\n"))
    }

    @Test func csvReadsAnyColumnOrderAndIgnoresBlankRows() throws {
        let csv = "de-DE,Field,LIMIT\r\nTagebuch,name,30 characters\r\n\r\n,subtitle,\r\n\"Zeile 1\nZeile 2\",description,\r\n"
        let document = try ListingTransfer.read(Data(csv.utf8), fileName: "export.csv")
        #expect(document.format == .csv)
        #expect(document.entries.map(\.fieldName) == ["name", "subtitle", "description"])
        #expect(document.entries.map(\.value) == ["Tagebuch", "", "Zeile 1\nZeile 2"])
        #expect(document.entries.allSatisfy { $0.localeCode == "de-DE" })
    }

    @Test func csvParserHandlesEscapedQuotes() {
        #expect(ListingCSVCoder.rows(in: "a,\"b \"\"c\"\"\",d") == [["a", "b \"c\"", "d"]])
        #expect(ListingCSVCoder.quoted("plain") == "plain")
        #expect(ListingCSVCoder.quoted("a,b") == "\"a,b\"")
        #expect(ListingCSVCoder.quoted("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }

    @Test func xliffMarksStateAndLimits() throws {
        let text = try #require(String(data: ListingTransfer.export(StorePageSampleData.fetchedListing, as: .xliff), encoding: .utf8))
        #expect(text.contains("<trans-unit id=\"keywords\" xml:space=\"preserve\" maxwidth=\"100\" size-unit=\"byte\">"))
        #expect(text.contains("<trans-unit id=\"subtitle\" xml:space=\"preserve\" maxwidth=\"30\" size-unit=\"char\">"))
        #expect(text.contains("state=\"needs-review-translation\""))
        #expect(text.contains("state=\"needs-translation\"></target>"))
        #expect(text.contains("target-language=\"ja\""))
        #expect(!text.contains("target-language=\"en-US\""))
    }

    @Test func jsonCarriesTheListingsIdentity() throws {
        let document = try ListingTransfer.read(ListingTransfer.export(Fixtures.listing(), as: .json), as: .json)
        #expect(document.appName == "Lumen Journal")
        #expect(document.version == "2.0")
        #expect(document.sourceLocaleCode == "en-US")
        #expect(document.entries.first?.localeCode == "de-DE")
        #expect(entries(document, for: "en-US").count == 9)
    }

    // MARK: - Files and errors

    @Test func formatsFromFileExtensions() {
        #expect(ListingTransferFormat(fileExtension: "XLF") == .xliff)
        #expect(ListingTransferFormat(fileExtension: "xliff") == .xliff)
        #expect(ListingTransferFormat(fileExtension: "csv") == .csv)
        #expect(ListingTransferFormat(fileExtension: "txt") == nil)
        #expect(ListingTransferFormat.json.exportTitle == "Export as JSON…")
        #expect(ListingTransfer.suggestedFileName(for: StorePageSampleData.listing, as: .xliff) == "Lumen-Journal-1.4.xliff")
    }

    @Test func unreadableFilesThrow() {
        #expect(throws: ListingTransferError.unsupportedFileType("txt")) {
            try ListingTransfer.read(Data("x".utf8), fileName: "notes.txt")
        }
        #expect(throws: ListingTransferError.missingFieldColumn) {
            try ListingTransfer.read(Data("locale,de-DE\nname,Lumen".utf8), as: .csv)
        }
        #expect(throws: ListingTransferError.notText) {
            try ListingTransfer.read(Data([0xC3, 0x28, 0xA0]), as: .csv)
        }
        #expect(throws: ListingTransferError.self) {
            try ListingTransfer.read(Data("<xliff><file".utf8), as: .xliff)
        }
        #expect(throws: ListingTransferError.self) {
            try ListingTransfer.read(Data("[]".utf8), as: .json)
        }
    }

    @Test func fieldNamesFromOtherTools() {
        #expect(ListingField(transferName: "privacyPolicyUrl") == .privacyPolicyURL)
        #expect(ListingField(transferName: "Privacy Policy URL") == .privacyPolicyURL)
        #expect(ListingField(transferName: "what's new") == .whatsNew)
        #expect(ListingField(transferName: "Promo") == .promotionalText)
        #expect(ListingField(transferName: "promotional_text") == .promotionalText)
        #expect(ListingField(transferName: "title") == nil)
        #expect(ListingField(transferName: "") == nil)
    }
}
