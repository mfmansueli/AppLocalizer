//
//  StudioPreviewBuilderLiveTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Live preview: what the App Store shows in a language now, falling
/// back to the primary language's set and, on iPad, to iPhone's.
@MainActor
@Suite("StudioPreviewBuilder · Live")
struct StudioPreviewBuilderLiveTests {
    @Test func thePrimaryLanguageShowsItsOwnSet() {
        let preview = StudioTestFixtures.builder().preview()
        #expect(preview.displayType == .iPhone)
        #expect(preview.shots.map(\.name) == StudioTestFixtures.slotNames)
        #expect(preview.shots.allSatisfy { $0.chip == nil })
        #expect(preview.shots.allSatisfy { $0.pixelSize == ScreenshotDisplayType.iPhone.portraitPixelSize })
        #expect(preview.note == "Live now · made with AppLocalizer")
        #expect(preview.searchNote == "The first screenshots, at the size search results show them.")
        #expect(preview.getTitle == "Get")
        #expect(!preview.isRightToLeft)
    }

    @Test func aLanguageWithoutASetFallsBackToThePrimaryLanguage() throws {
        let preview = StudioTestFixtures.builder(locale: "ar-SA").preview()
        #expect(preview.shots.count == 5)
        #expect(preview.shots.allSatisfy { $0.chip == .fallback(language: "English") })
        #expect(preview.note == "Live now · Arabic falls back to English (U.S.)")
        #expect(preview.isRightToLeft)
        #expect(preview.getTitle == "احصل")
        // The shots are English's, drawn from English's renders.
        let english = try #require(StudioTestFixtures.matrix.cell(locale: "en-US", displayType: .iPhone, slot: 0))
        #expect(preview.shots.first?.image == english.image)
    }

    @Test func iPadWithoutAnIPadSetShowsTheIPhoneSet() {
        var builder = StudioTestFixtures.builder(displayType: .iPad)
        builder.live = StudioTestFixtures.iPhoneOnlyLive
        let preview = builder.preview()
        #expect(preview.displayType == .iPhone)
        #expect(preview.shots.count == 5)
        #expect(preview.note == "Live now · no iPad screenshots, so iPad shows these")
        #expect(preview.searchShots.count == 3)
    }

    @Test func iPadWithItsOwnSetStaysOnIPad() {
        let preview = StudioTestFixtures.builder(displayType: .iPad).preview()
        #expect(preview.displayType == .iPad)
        #expect(preview.note == "Live now · made with AppLocalizer")
        #expect(preview.searchShots.count == 2)
    }

    @Test func aLiveCellDrawsFromItsRenderAndTheOthersDownload() throws {
        let preview = StudioTestFixtures.builder(locale: "de-DE").preview()
        let matrix = StudioTestFixtures.matrix
        for shot in preview.shots {
            let cell = try #require(matrix.cell(locale: "de-DE", displayType: .iPhone, slot: shot.slot))
            if cell.state == .live {
                #expect(shot.image == cell.image)
                #expect(shot.image.renderJob != nil)
            } else {
                let live = try #require(cell.live)
                #expect(shot.image == .live(live))
            }
        }
        // German's search screenshot changed since the push: it downloads.
        #expect(preview.shots[2].image.renderJob == nil)
        #expect(preview.shots.count { $0.image.renderJob != nil } == 4)
    }

    @Test func aSetUploadedByHandDownloadsAndSaysSo() {
        let preview = StudioTestFixtures.builder(locale: "en-GB").preview()
        #expect(preview.note == "Live now · uploaded by hand")
        #expect(preview.shots.allSatisfy { $0.chip == nil })
        #expect(preview.shots.allSatisfy { shot in
            if case .live = shot.image { return true }
            return false
        })
    }

    @Test func nothingLiveLeavesThePreviewEmpty() {
        var builder = StudioTestFixtures.builder(locale: "de-DE")
        builder.live = LiveScreenshots()
        let preview = builder.preview()
        #expect(preview.shots.isEmpty)
        #expect(preview.searchShots.isEmpty)
        #expect(preview.note == "Nothing live yet")
        #expect(preview.searchNote == "Search results show the first screenshots once there are some.")
    }

    @Test(arguments: [
        ("de-DE", "Lumen: Tagebuch", "Private Notizen, sanfte Fragen"),
        ("fr-FR", "Lumen: Journal", "Private notes, gentle prompts"),
    ])
    func theHeaderUsesTheLanguagesNameElseThePrimarys(locale: String, name: String, subtitle: String) {
        var builder = StudioTestFixtures.builder(locale: locale)
        builder.storeTexts = StudioStoreTexts(content: StorePageContentFixtures.editable)
        let preview = builder.preview()
        #expect(preview.name == name)
        #expect(preview.subtitle == subtitle)
    }

    @Test func withoutStoreTextsTheHeaderShowsTheAppsName() {
        let preview = StudioTestFixtures.builder(locale: "de-DE").preview()
        #expect(preview.name == "Lumen Journal")
        #expect(preview.subtitle == nil)
        #expect(preview.getTitle == "Laden")
    }

    @Test func slotsPastTheNamesAreNumbered() {
        var builder = StudioTestFixtures.builder()
        builder.slotNames = ["Today"]
        let names = builder.preview().shots.map(\.name)
        #expect(names == ["Today", "Slot 2", "Slot 3", "Slot 4", "Slot 5"])
    }
}
#endif
