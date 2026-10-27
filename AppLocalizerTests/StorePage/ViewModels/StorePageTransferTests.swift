//
//  StorePageTransferTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Find and Replace, Import with a diff, Export, keywords and Fill, through
/// the view model, so every result lands in the queue.
@MainActor
@Suite("Store Page find, import, export and fill")
struct StorePageTransferTests {
    private let app = StorePageContentFixtures.app

    private func makeModel(queue: ChangeQueue = ChangeQueue()) async -> StorePageViewModel {
        let model = StorePageViewModel(app: app, services: FakeStorePageServices(), queue: queue)
        await model.load()
        return model
    }

    // MARK: - Find and Replace

    @Test func previewsMatchesAndReplacesThemAsEdits() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.presentFindReplace()
        model.findQuery = FindReplaceQuery(find: "Lumen Plus", replacement: "Lumen Premium")
        #expect(model.findMatches.map(\.key) == [ListingFieldKey(.englishUS, .description)])

        #expect(model.replaceAll() == 1)
        #expect(model.sheet == nil)
        #expect(model.notice == "Replaced in 1 field.")
        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.englishUS, .description)))
        #expect(change.newValue.contains("Lumen Premium"))
        #expect(!change.newValue.contains("Lumen Plus"))
    }

    @Test func caseSensitivityIsAChoice() async {
        let model = await makeModel()
        model.findQuery = FindReplaceQuery(find: "lumen", replacement: "Lumen")
        #expect(model.findMatches.isEmpty)
        model.findQuery.isCaseSensitive = false
        #expect(!model.findMatches.isEmpty)
    }

    // MARK: - Import

    private let csv = "field,de-DE\r\npromotionalText,Neu: Wochenrückblicke\r\nsubtitle,\(String(repeating: "x", count: 31))\r\n"

    @Test func importShowsADiffBeforeApplying() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.showImport(Data(csv.utf8), fileName: "Lumen.csv")

        let preview = try #require(model.importPreview)
        #expect(model.sheet == .importPreview)
        #expect(preview.changes.map(\.key) == [ListingFieldKey(.german, .promotionalText)])
        #expect(preview.problems.contains { $0.isError })
        #expect(queue.changes.isEmpty)
    }

    @Test func applyingTheImportQueuesTheSelectedChanges() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.showImport(Data(csv.utf8), fileName: "Lumen.csv")
        model.applyImport()

        #expect(model.sheet == nil)
        #expect(model.notice == "Imported 1 change.")
        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.german, .promotionalText)))
        #expect(change.newValue == "Neu: Wochenrückblicke")
    }

    @Test func uncheckedImportChangesAreSkipped() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.showImport(Data(csv.utf8), fileName: "Lumen.csv")
        model.toggleImportChange(ListingFieldKey(.german, .promotionalText))
        #expect(model.importPreview?.selectedChanges.isEmpty == true)
        model.applyImport()
        #expect(queue.changes.isEmpty)
    }

    @Test func anUnreadableFileSaysWhy() async {
        let model = await makeModel()
        model.showImport(Data("not,a,listing".utf8), fileName: "Notes.csv")
        #expect(model.importPreview == nil)
        #expect(model.importError != nil)
        #expect(model.sheet == .importPreview)
        model.dismissImport(choosingAnother: true)
        #expect(model.sheet == nil)
        #expect(model.isImporterPresented)
    }

    // MARK: - Export

    @Test func exportsTheTextsWithPendingEdits() async throws {
        let model = await makeModel()
        model.edit(.promotionalText, in: .german, to: "Neu")
        let document = try #require(model.exportDocument(as: .csv))
        let text = try #require(String(data: document.data, encoding: .utf8))
        #expect(text.contains("promotionalText"))
        #expect(text.contains("Neu"))
        #expect(model.exportFileName(as: .xliff) == "Lumen-Journal-2.0.xliff")
    }

    @Test func aCancelledExportSaysNothing() async {
        let model = await makeModel()
        model.exportFormat = .json
        model.exportDidFinish(.failure(CocoaError(.userCancelled)))
        #expect(model.exportFormat == nil)
        #expect(model.notice == nil)
    }

    // MARK: - Keywords

    @Test func optimizingKeywordsDropsDuplicatesAndSpaces() async {
        let model = await makeModel()
        model.edit(.keywords, in: .german, to: "tagebuch, stimmung,tagebuch,notizen")
        let analysis = model.keywordAnalysis(in: .german)
        #expect(analysis.duplicateCount == 1)
        #expect(analysis.inNameOrSubtitleCount >= 1)
        #expect(analysis.canOptimize)
        model.optimizeKeywords(in: .german)
        #expect(model.value(.keywords, in: .german) == "stimmung")
    }

    @Test func removingAToken() async {
        let model = await makeModel()
        model.edit(.keywords, in: .german, to: "stimmung,dankbarkeit")
        model.removeKeyword(at: 0, in: .german)
        #expect(model.value(.keywords, in: .german) == "dankbarkeit")
    }

    // MARK: - Fill

    @Test func copiesFromASiblingLocale() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        let pair = try #require(model.siblingPairs.first { $0.target == .englishUK })
        model.copy(pair)
        #expect(model.listing?.contains(.englishUK) == true)
        #expect(model.value(.description, in: .englishUK) == model.value(.description, in: .englishUS))
        #expect(queue.changes.contains { $0.id == "storePage.app1.version.v2.en-GB.new" })
        #expect(model.notice?.hasPrefix("Copied") == true)
    }

    @Test func copiesURLsIntoEveryLocale() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        #expect(model.hasURLsToCopy)
        model.copyURLsToEveryLocale()
        #expect(model.value(.supportURL, in: .german) == "https://lumen.example/support")
        #expect(model.value(.privacyPolicyURL, in: .german) == "https://lumen.example/privacy")
        #expect(!model.hasURLsToCopy)
        #expect(model.notice == "Copied 3 URLs.")
        #expect(queue.changes.count == 3)
    }
}
