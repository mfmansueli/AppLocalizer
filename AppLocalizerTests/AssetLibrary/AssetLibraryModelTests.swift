//
//  AssetLibraryModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The App Asset Library sheet: it lists the app's files, checks which are
/// on a page, picks the unused ones, and deletes several at once, keeping
/// Apple's reason on a file it refused.
@MainActor
@Suite("Asset library sheet")
struct AssetLibraryModelTests {
    private func makeModel(_ library: FakeAssetLibraryFiles) -> AssetLibraryModel {
        AssetLibraryModel(appID: "app-1", appName: "Alba", manager: library)
    }

    private func library(uncheckable: Set<String> = []) -> FakeAssetLibraryFiles {
        FakeAssetLibraryFiles([
            FakeAssetLibraryFiles.Seed(id: "header-new", media: .video, name: "Autopilot · en-US · Header 21:9 · motion · 7C1D0A", placements: 1),
            FakeAssetLibraryFiles.Seed(id: "header-old", media: .video, name: "Autopilot · en-US · Header 21:9 · motion", placements: 0),
            FakeAssetLibraryFiles.Seed(id: "search-old", media: .image, name: "Autopilot · en-US · Search results 3:2", placements: 0),
            FakeAssetLibraryFiles.Seed(id: "preview", media: .video, name: "Autopilot · en-US · iPhone App Preview", placements: 2),
        ], uncheckable: uncheckable)
    }

    @Test func itListsTheFilesAndWhichAreOnAPage() async {
        let model = makeModel(library())
        await model.load()
        #expect(model.phase == .loaded)
        #expect(model.files.map(\.id) == ["header-new", "header-old", "search-old", "preview"])
        let titles = model.files.map(model.placementTitle(of:))
        #expect(titles == ["On 1 page", "Not on any page", "Not on any page", "On 2 pages"])
        #expect(model.summaryTitle == "4 files · 2 on no page")
    }

    @Test func onlyFilesOnNoPageCanBePicked() async {
        let model = makeModel(library())
        await model.load()
        model.selectUnused()
        #expect(model.selection == ["header-old", "search-old"])
        #expect(model.deleteTitle == "Delete 2 Files…")
        // "KB" or "kB", as the system writes it.
        #expect(model.selectionTitle?.lowercased() == "2 selected · 2 kb")
        #expect(model.confirmationTitle == "Delete 2 files from Alba’s asset library?")

        let placed = model.files[0]
        model.toggle(placed)
        #expect(!model.selection.contains(placed.id), "A page shows it")
        model.selectNone()
        #expect(model.selection.isEmpty)
    }

    @Test func filtersNarrowTheList() async {
        let model = makeModel(library())
        await model.load()
        model.kind = .images
        #expect(model.visibleFiles.map(\.id) == ["search-old"])
        model.kind = .all
        model.onlyUnused = true
        #expect(model.visibleFiles.map(\.id) == ["header-old", "search-old"])
        model.onlyUnused = false
        model.search = "app preview"
        #expect(model.visibleFiles.map(\.id) == ["preview"])
        model.search = "header"
        model.selectUnused()
        #expect(model.selection == ["header-old"], "Select Unused picks only what's shown")
    }

    @Test func deletingRemovesTheFilesAndSaysHowMany() async {
        let files = library()
        let model = makeModel(files)
        await model.load()
        model.selectUnused()
        await model.deleteSelected()
        #expect(files.deleted == ["header-old", "search-old"])
        #expect(model.files.map(\.id) == ["header-new", "preview"])
        #expect(model.selection.isEmpty)
        #expect(model.notice == "Deleted 2 files.")
        #expect(!model.isDeleting)
    }

    /// A file whose check failed can be picked; Apple refuses it if a page
    /// shows it, and the reason stays on its row.
    @Test func aRefusedFileKeepsApplesReason() async throws {
        let files = library(uncheckable: ["preview"])
        let model = makeModel(files)
        await model.load()
        let preview = try #require(model.files.first { $0.id == "preview" })
        #expect(model.placementTitle(of: preview) == "Couldn’t check")
        model.selectUnused()
        model.toggle(preview)
        #expect(model.selection.count == 3)
        await model.deleteSelected()
        #expect(files.deleted == ["header-old", "search-old"])
        #expect(model.deleteErrors["preview"] == "STATE_ERROR.ASSET_HAS_PLACEMENTS — Delete those placements first.")
        #expect(model.notice == "Deleted 2 of 3. 1 couldn’t be deleted: the reason is on each.")
        #expect(model.files.map(\.id).contains("preview"))
    }
}
