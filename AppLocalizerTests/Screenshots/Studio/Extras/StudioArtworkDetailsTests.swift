//
//  StudioArtworkDetailsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Screenshots preview's Header and search card: each image's size and
/// format, its text, its checks and whether it's new or on App Store
/// Connect in the shown language, and the same across every language.
@MainActor
@Suite("Studio · header and search details")
struct StudioArtworkDetailsTests {
    /// Lumen's checked extras in 12 languages: German's header has a
    /// discount, Japanese's search image a Dark Mode edge; German's search
    /// and English's two are pushed.
    private static var extras: ScreenshotExtras {
        var extras = StudioDebugExtras.extras(for: StudioDebugExtras.checked(StudioDebugExtras.run(.ready)))!
        extras.pushedChecksums = StudioDebugExtras.pushedForDetails
        return extras
    }

    private func details(_ extras: ScreenshotExtras = Self.extras, locale: String, hasLocalization: Bool = true) throws -> StudioArtworkDetails {
        try #require(StudioArtworkDetails(extras: extras, locale: locale) { _ in hasLocalization })
    }

    @Test func germansHeaderCantGoAndItsSearchImageIsOnTheStore() throws {
        let german = try details(locale: "de-DE")
        #expect(german.languageName == "German")
        #expect(german.rows.map(\.title) == ["Header · 21:9", "Search results · 3:2"])
        let header = try #require(german.rows.first)
        #expect(header.id == "header-de-DE")
        #expect(header.format.hasPrefix("3840 × 1646 · PNG · "))
        #expect(header.text == "No line: the app name only")
        #expect(header.checks == "Can’t be pushed: German header: ‘−50%’ — discounts and percentages aren’t allowed here.")
        #expect(header.checksTone == .danger)
        #expect(header.status == "New · stays out of the push until it’s fixed")
        #expect(header.statusTone == .danger)

        let search = try #require(german.rows.last)
        #expect(search.format.hasPrefix("3840 × 2560 · PNG · "))
        #expect(search.text == "No headline yet")
        #expect(search.checks == "Passed every check")
        #expect(search.checksTone == .positive)
        #expect(search.status == "On App Store Connect")
        #expect(search.statusTone == .positive)
        #expect(search.viewerIndex == 1)
    }

    @Test func everyLanguageIsSummedUp() throws {
        let summary = try details(locale: "de-DE").languagesSummary
        #expect(summary == "12 languages · 1 on App Store Connect · 1 with warnings · 1 can’t be pushed")
        var nothing = Self.extras
        nothing.pushedChecksums = nil
        nothing.artwork = nothing.artwork.map { file in
            var file = file
            file.checks = []
            return file
        }
        #expect(StudioArtworkDetails.languagesSummary(nothing) == "12 languages")
    }

    @Test func aWarningSaysWhatItFound() throws {
        let search = try #require(details(locale: "ja").rows.last)
        #expect(search.checks == "1 warning: Japanese search image: its edges melt into the page in Dark Mode.")
        #expect(search.checksTone == .warning)
        #expect(search.status == "New · waits in Review & Push")
        #expect(search.statusTone == .accent)
    }

    @Test func discardedReplacedAndNoLocalization() throws {
        var extras = Self.extras
        extras.discardedChecksums = ["header-fr-FR": "debug-header-fr-FR"]
        extras.pushedChecksums?["search-fr-FR"] = "an-older-file"
        let french = try details(extras, locale: "fr-FR")
        #expect(french.rows.first?.status == "Discarded: App Store Connect keeps what it has")
        #expect(french.rows.first?.statusTone == .neutral)
        #expect(french.rows.last?.status == "New · replaces the one on App Store Connect")

        let noLocalization = try details(locale: "fr-FR", hasLocalization: false)
        #expect(noLocalization.rows.last?.status == "New · App Store Connect has no French localization on this version yet")
        #expect(noLocalization.rows.last?.statusTone == .warning)
    }

    @Test func aLanguageWithoutArtworkSaysSo() throws {
        let rows = try details(locale: "sv").rows
        #expect(rows.count == 2)
        let made = rows.map(\.isMade)
        #expect(made == [false, false])
        #expect(rows.first?.status.hasPrefix("Not made in ") == true)
        #expect(rows.first?.format == "3840 × 1646")
    }

    @Test func oneImageForBoth() throws {
        let wide = try #require(StudioDebugExtras.extras(for: StudioDebugExtras.run(.ready, size: .wide)))
        let rows = try details(wide, locale: "en-US").rows
        #expect(rows.map(\.title) == ["Header and search · 16:9"])
        #expect(rows.first?.format.hasPrefix("5244 × 2950 · PNG · ") == true)
        #expect(rows.first?.viewerIndex == 0)
        #expect(rows.first?.checks == "Not checked: made before the checks", "These were made without checks")
    }

    @Test func aLoopSaysItsLengthFrameRateAndCodec() {
        var file = ExtrasArtworkFile(kind: .header, locale: "en-US", fileID: "sum", headline: "Calm mornings", fits: false, byteCount: 1000)
        file.loop = ExtrasArtworkLoop(fileID: "loop", byteCount: 18_000_000, seconds: 20, framesPerSecond: 30, codec: "H.264", isSeamless: true)
        let format = StudioArtworkDetails.format(file)
        #expect(format.hasPrefix("3840 × 1646 · 0:20 loop · 30 fps · H.264 · seamless · "))
        file.loop?.isSeamless = false
        #expect(StudioArtworkDetails.format(file).contains("jumps where it loops"))
        #expect(StudioArtworkDetails.text(file) == "“Calm mornings” · too long even at its smallest size")
    }

    @Test func noArtworkNoCard() {
        var extras = Self.extras
        extras.artwork = []
        #expect(StudioArtworkDetails(extras: extras, locale: "en-US") { _ in true } == nil)
        extras = Self.extras
        extras.artworkSize = nil
        #expect(StudioArtworkDetails(extras: extras, locale: "en-US") { _ in true } == nil)
    }
}
#endif
