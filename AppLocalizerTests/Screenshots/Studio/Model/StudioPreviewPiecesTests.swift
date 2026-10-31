//
//  StudioPreviewPiecesTests.swift
//  AppLocalizerTests
//

import SwiftUI
import Testing
@testable import AppLocalizer

/// The preview's switches, chips and shots: Live · New, Light · Dark, a
/// shot's label and shape, and the search results' first shots.
@Suite("Studio preview pieces")
struct StudioPreviewPiecesTests {
    @Test func liveComesBeforeNew() {
        #expect(StudioSetChoice.allCases == [.live, .new])
        #expect(StudioSetChoice.allCases.map(\.title) == ["Live", "New"])
        #expect(StudioSetChoice.new.id == "new")
    }

    @Test func theStoreAppearanceSetsTheColorScheme() {
        #expect(StoreAppearance.allCases.map(\.title) == ["Light", "Dark"])
        #expect(StoreAppearance.light.colorScheme == .light)
        #expect(StoreAppearance.dark.colorScheme == .dark)
        #expect(StoreAppearance.dark.id == "dark")
    }

    @Test(arguments: [
        (StudioShotChip.fallback(language: "English"), "English", PillStyle.warning),
        (.new, "New", .accent),
        (.shortened, "Shortened", .machineTranslated),
    ])
    func chipsHaveTheirTitleAndStyle(chip: StudioShotChip, title: String, style: PillStyle) {
        #expect(chip.title == title)
        #expect(chip.style == style)
        #expect(!chip.help.isEmpty)
    }

    @Test func theFallbackChipsHelpNamesTheLanguageShown() {
        let help = StudioShotChip.fallback(language: "English").help
        #expect(help == "No screenshots in this language: the App Store shows English.")
    }

    @Test func aShotIsLabelledBySlotAndShapedByItsPixels() {
        let shot = StudioShot(slot: 2, name: "Search", image: .none, pixelSize: PixelSize(width: 1000, height: 2000), chip: nil)
        #expect(shot.id == 2)
        #expect(shot.label == "3 · Search")
        #expect(shot.aspect == 2)
        let empty = StudioShot(slot: 0, name: "Today", image: .none, pixelSize: PixelSize(width: 0, height: 0), chip: nil)
        #expect(empty.aspect == 2.17)
    }

    @Test(arguments: [(ScreenshotDisplayType.iPhone, 3), (.iPad, 2)])
    func searchResultsShowTheFirstShots(display: ScreenshotDisplayType, count: Int) {
        let shots = (0..<5).map { StudioShot(slot: $0, name: "\($0)", image: .none, pixelSize: display.portraitPixelSize, chip: nil) }
        let preview = StudioPreview(
            name: "Lumen", subtitle: nil, getTitle: "Get", statsLine: nil, isRightToLeft: false, displayType: display,
            note: "", shots: shots, searchNote: ""
        )
        #expect(preview.searchShots.map(\.slot) == Array(0..<count))
    }
}
