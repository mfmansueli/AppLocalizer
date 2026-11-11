//
//  AutopilotLocalizerCaptionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Use This Direction saves the run's captions: every language's follow
/// their screen to its new slot, and the translations of a primary caption
/// that changed are written again.
@MainActor
@Suite("AutopilotLocalizer captions")
struct AutopilotLocalizerCaptionsTests {
    private static let names = ["Today", "Week", "Search"]
    private static let english = ["Write every day", "Your whole week", "Find any entry"]
    private static let german = ["Schreib jeden Tag", "Deine ganze Woche", "Finde jeden Eintrag"]

    /// A document whose slots are Today, Week and Search, in English,
    /// German and Italian.
    private static func document() -> ScreenshotsDocument {
        var document = ScreenshotsDocument.empty(primary: "en-US")
        document.slotNames = names
        for slot in names.indices {
            document.captions.setCaption(ScreenshotCaption(headline: english[slot], provenance: .written), locale: "en-US", slot: slot)
            document.captions.setCaption(ScreenshotCaption(headline: german[slot]), locale: "de-DE", slot: slot)
            document.captions.setCaption(ScreenshotCaption(headline: "Italiano \(slot + 1)"), locale: "it", slot: slot)
        }
        return document
    }

    /// A run in English and German over `order` of the document's screens.
    private static func run(_ order: [Int], captions: [Int: String] = [:]) -> AutopilotRun {
        var run = StudioDebugRuns.run(.choose)
        run.plan.screens = order.map { slot in
            AutopilotScreen(id: AutopilotScreen.identifier(for: names[slot]), name: names[slot], caption: captions[slot] ?? english[slot])
        }
        run.plan.localeCodes = ["en-US", "de-DE"]
        return run
    }

    @Test func translationsFollowTheirScreenToItsNewSlot() {
        var document = Self.document()
        AutopilotLocalizer.setCaptions(of: Self.run([0, 2, 1]), primary: "en-US", in: &document)
        #expect(document.captions.caption(locale: "en-US", slot: 1)?.headline == "Find any entry")
        #expect(document.captions.caption(locale: "de-DE", slot: 1)?.headline == "Finde jeden Eintrag")
        #expect(document.captions.caption(locale: "de-DE", slot: 2)?.headline == "Deine ganze Woche")
        #expect(document.captions.caption(locale: "it", slot: 2)?.headline == "Italiano 2", "A language outside the run moves too")
    }

    @Test func translationsOfAChangedCaptionAreWrittenAgain() {
        var document = Self.document()
        AutopilotLocalizer.setCaptions(of: Self.run([0, 1, 2], captions: [1: "Look back on your week"]), primary: "en-US", in: &document)
        #expect(document.captions.caption(locale: "en-US", slot: 1)?.headline == "Look back on your week")
        #expect(document.captions.caption(locale: "de-DE", slot: 1) == nil, "It translated the caption replaced")
        #expect(document.captions.caption(locale: "de-DE", slot: 0)?.headline == "Schreib jeden Tag")
        #expect(document.captions.caption(locale: "it", slot: 1)?.headline == "Italiano 2", "Not in the run: nobody would write it again")
    }

    @Test func aFirstCaptionLeavesTheTranslationsAlone() {
        var document = Self.document()
        document.captions.setCaption(nil, locale: "en-US", slot: 2)
        AutopilotLocalizer.setCaptions(of: Self.run([0, 1, 2]), primary: "en-US", in: &document)
        #expect(document.captions.caption(locale: "en-US", slot: 2)?.headline == "Find any entry")
        #expect(document.captions.caption(locale: "de-DE", slot: 2)?.headline == "Finde jeden Eintrag")
    }

    @Test func aSetWithoutNamesKeepsItsSlots() {
        var document = Self.document()
        document.slotNames = []
        AutopilotLocalizer.setCaptions(of: Self.run([0, 2, 1]), primary: "en-US", in: &document)
        #expect(document.captions.caption(locale: "it", slot: 1)?.headline == "Italiano 2")
    }
}
#endif
