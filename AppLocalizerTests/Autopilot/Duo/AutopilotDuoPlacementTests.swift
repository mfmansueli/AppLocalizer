//
//  AutopilotDuoPlacementTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Where iPhone Duo's captures go in the set (board 30), and what the set
/// renders from them: one display on each slot, both side by side (the
/// cover display as the slot's companion), or both as separate
/// screenshots on iPhone Duo's own screens, inner then cover.
@MainActor
@Suite("iPhone Duo placement")
struct AutopilotDuoPlacementTests {
    private static func placed(_ screens: AutopilotDuoScreens, _ both: AutopilotDuoBoth) -> (AutopilotRun, ScreenshotsDocument) {
        let run = StudioDebugDuoStates.run(.ready, screens, both)
        var document = ScreenshotsDebugDocuments.standard
        AutopilotLocalizer.place(run, in: &document)
        return (run, document)
    }

    private static func duoCells(_ document: ScreenshotsDocument) -> [ScreenshotCell] {
        ScreenshotsTestFixtures.matrix(document).row(locale: "en-US", displayType: .iPhoneDuo)
    }

    @Test func sideBySidePutsTheCoverBesideTheInnerOnEachSlot() throws {
        let (run, document) = Self.placed(.both, .sideBySide)
        let count = run.plan.screens.count
        #expect((document.screens(on: .iPhoneDuo) ?? []).isEmpty, "The set's screens")
        for slot in 0..<count {
            let inner = try #require(document.captures.ownCapture(locale: "en-US", displayType: .iPhoneDuo, slot: slot))
            let cover = try #require(document.captures.companion(locale: "en-US", displayType: .iPhoneDuo, slot: slot, primary: "en-US"))
            #expect(inner.isCompanion != true)
            #expect(!CaptureSizeRules.isDuoOuterDisplay(inner.pixelSize))
            #expect(CaptureSizeRules.isDuoOuterDisplay(cover.pixelSize))
            #expect(cover.fileName.hasSuffix("_cover.png"))
        }
        let matrix = ScreenshotsTestFixtures.matrix(document)
        #expect(matrix.slotCount(on: .iPhoneDuo) == count)
        let cells = Self.duoCells(document)
        #expect(cells.count == count)
        let job = try #require(cells.first?.image.renderJob)
        #expect(job.companion != nil)
        #expect(job.layout.companion != nil, "Both phones in one image")
        #expect(job.layout.canvas.pixelSize == CaptureSizeRules.duoInnerSize || job.layout.canvas.pixelSize == CaptureSizeRules.duoInnerSize.rotated)
    }

    @Test func separateGivesTheDuoItsOwnScreensInnerThenCover() throws {
        let (run, document) = Self.placed(.both, .separate)
        let screens = try #require(document.screens(on: .iPhoneDuo))
        let names = run.plan.screens.map(\.name)
        let covers = run.plan.duoSeparateCovers
        #expect(screens.count == names.count + covers)
        #expect(screens.prefix(2).map(\.name) == ["\(names[0]) · inner", "\(names[0]) · cover"])
        #expect(screens.prefix(2).map(\.captionSlot) == [0, 0], "Each takes its screen's caption")
        #expect(!document.captures.captures.contains { $0.displayType == .iPhoneDuo && $0.isCompanion == true })

        let matrix = ScreenshotsTestFixtures.matrix(document)
        #expect(matrix.slotCount(on: .iPhoneDuo) == screens.count)
        let cells = Self.duoCells(document)
        let innerJob = try #require(cells.first?.image.renderJob)
        let coverJob = try #require(cells.dropFirst().first?.image.renderJob)
        #expect(innerJob.companion == nil && innerJob.layout.companion == nil)
        #expect(!innerJob.layout.canvas.isCoverDisplay)
        #expect(coverJob.layout.canvas.isCoverDisplay, "The folded phone framed in Apple's size")
        #expect(coverJob.capture.map { CaptureSizeRules.isDuoOuterDisplay($0.pixelSize) } == true)
    }

    @Test func theCoverAloneFramesTheFoldedPhoneOnEverySlot() throws {
        let (run, document) = Self.placed(.cover, .sideBySide)
        let cells = Self.duoCells(document)
        #expect(cells.count == run.plan.screens.count)
        for cell in cells {
            let job = try #require(cell.image.renderJob)
            #expect(job.layout.canvas.isCoverDisplay)
            #expect(job.companion == nil)
            #expect(job.layout.canvas.pixelSize == CaptureSizeRules.duoInnerSize, "Every Duo image is Apple's 2007 × 2853")
        }
    }

    /// Placing again after the row changed takes the cover displays and
    /// the Duo's own screens off.
    @Test func switchingBackToTheInnerDisplayDropsTheCover() throws {
        var (_, document) = Self.placed(.both, .separate)
        let pair = StudioDebugDuoStates.run(.ready, .both, .sideBySide)
        AutopilotLocalizer.place(pair, in: &document)
        #expect((document.screens(on: .iPhoneDuo) ?? []).isEmpty)
        #expect(document.captures.captures.contains { $0.displayType == .iPhoneDuo && $0.isCompanion == true })

        let inner = StudioDebugDuoStates.run(.ready, .inner, .sideBySide)
        AutopilotLocalizer.place(inner, in: &document)
        #expect(!document.captures.captures.contains { $0.displayType == .iPhoneDuo && $0.isCompanion == true })
        let job = try #require(Self.duoCells(document).first?.image.renderJob)
        #expect(job.companion == nil && job.layout.companion == nil)
        #expect(!job.layout.canvas.isCoverDisplay)
    }

    @Test func aPreviewSaysWhichDisplaysTheDuoShows() {
        #expect(StudioPreviewBuilder.duoFaceTitle(Self.placed(.inner, .sideBySide).0.plan) == "inner display")
        #expect(StudioPreviewBuilder.duoFaceTitle(Self.placed(.cover, .sideBySide).0.plan) == "cover display")
        #expect(StudioPreviewBuilder.duoFaceTitle(Self.placed(.both, .sideBySide).0.plan) == "inner and cover, side by side")
        #expect(StudioPreviewBuilder.duoFaceTitle(Self.placed(.both, .separate).0.plan) == "inner and cover, separate")
    }
}
#endif
