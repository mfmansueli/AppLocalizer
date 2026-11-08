//
//  ExtrasPushControllerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Autopilot's extras in Review & Push: planned with the screenshots,
/// checked or left out, pushed on their own run through the asset
/// library, and noted in the set once App Store Connect has them.
@MainActor
@Suite("Extras push")
struct ExtrasPushControllerTests {
    private func harness() throws -> ScreenshotPushControllerHarness {
        var document = ScreenshotsDebugDocuments.standard
        document.extras = ExtrasReviewFixtures.extras()
        let harness = ScreenshotPushControllerHarness(document: document)
        let folder = harness.screenshots.extrasFolder(for: harness.app)
        try ExtrasReviewFixtures.writeFiles(of: ExtrasReviewFixtures.extras(), into: folder)
        return harness
    }

    @Test func theExtrasArePlannedWithTheScreenshots() async throws {
        let harness = try harness()
        await harness.load()
        let plan = try #require(harness.controller.extras.plans[harness.app.id])
        #expect(plan.items.count == 7)
        #expect(harness.controller.extras.itemCount == 7)
        #expect(harness.controller.canPushExtras)
    }

    /// A run that makes only an App Preview leaves the set as it is, so an
    /// app that never had one still lists its App Preview.
    @Test func anAppPreviewWithoutAScreenshotSetIsStillPlanned() async throws {
        var extras = ExtrasReviewFixtures.extras()
        extras.artwork = []
        extras.artworkSize = nil
        var document = ScreenshotsDebugDocuments.standard
        document.history = nil
        document.extras = extras
        let harness = ScreenshotPushControllerHarness(document: document)
        try ExtrasReviewFixtures.writeFiles(of: extras, into: harness.screenshots.extrasFolder(for: harness.app))
        await harness.load()

        let plan = try #require(harness.controller.extras.plans[harness.app.id])
        #expect(plan.items.map(\.id) == ["iphone-en-US"])
        #expect(plan.items.first?.localizationID == "loc-en-US")
        #expect(harness.controller.plans[harness.app.id] == nil, "No screenshots to push")
        #expect(harness.controller.extras.itemCount == 1)
        #expect(harness.controller.loadErrors[harness.app.id] == nil)
    }

    @Test func extrasThatAreGoneLeaveReview() async throws {
        let harness = try harness()
        await harness.load()
        #expect(harness.controller.extras.plans[harness.app.id] != nil)

        var document = try #require(harness.screenshots.storedDocument)
        document.history = nil
        document.extras = nil
        harness.screenshots.storedDocument = document
        await harness.load()
        #expect(harness.controller.extras.plans[harness.app.id] == nil)
        #expect(harness.controller.extras.itemCount == 0)
    }

    /// Discard All: every extra leaves review, the blocked ones too, and
    /// stays out on the next look; Undo brings them back.
    @Test func discardedExtrasLeaveUntilUndo() async throws {
        let harness = try harness()
        await harness.load()
        let extras = harness.controller.extras
        let plan = try #require(extras.plans[harness.app.id])
        try extras.toggle(#require(plan.items.first { $0.id == "search-fr-FR" }))

        await harness.controller.discardExtras(plan.items)
        let discarded = try #require(extras.plans[harness.app.id])
        #expect(discarded.items.isEmpty)
        #expect(discarded.discardedCount == 7)
        #expect(extras.itemCount == 0)
        #expect(extras.unchecked.isEmpty)
        let saved = harness.screenshots.storedDocument?.extras?.discardedChecksums
        #expect(saved?["iphone-en-US"] == "preview-sum")
        #expect(saved?["header-de-DE"] == "header-de-DE-sum", "Blocked ones go too")
        #expect(harness.screenshots.storedDocument?.extras?.previews.count == 1, "The files stay with the set")

        await harness.load()
        #expect(extras.plans[harness.app.id]?.items.isEmpty == true, "They stay out on the next look")

        await harness.controller.undoExtrasDiscards(appIDs: [harness.app.id])
        #expect(extras.plans[harness.app.id]?.items.count == 7)
        #expect(extras.plans[harness.app.id]?.discardedCount == 0)
        #expect(harness.screenshots.storedDocument?.extras?.discardedChecksums == nil)
    }

    @Test func aBlockedExtraCantBeCheckedAndUncheckedOnesStay() async throws {
        let harness = try harness()
        await harness.load()
        let extras = harness.controller.extras
        let plan = try #require(extras.plans[harness.app.id])
        let german = try #require(plan.items.first { $0.id == "header-de-DE" })
        #expect(!extras.isChecked(german))
        extras.toggle(german)
        #expect(!extras.isChecked(german), "An error keeps it out")

        let french = try #require(plan.items.first { $0.id == "search-fr-FR" })
        extras.toggle(french)
        #expect(extras.checkedItems(in: plan).map(\.id) == ["header-en-US", "search-en-US", "header-fr-FR", "search-de-DE", "iphone-en-US"])
    }

    /// The card's checkbox: every header out at once, the search images
    /// untouched, and an error still keeping its header out when all go
    /// back in.
    @Test func aWholeCardComesOutAndGoesBackAtOnce() async throws {
        let harness = try harness()
        await harness.load()
        let extras = harness.controller.extras
        let plan = try #require(extras.plans[harness.app.id])
        let headers = plan.items.filter { $0.artworkKind == .header }

        extras.setChecked(headers, to: false)
        #expect(!headers.contains(where: extras.isChecked))
        #expect(extras.checkedItems(in: plan).map(\.id) == ["search-en-US", "search-fr-FR", "search-de-DE", "iphone-en-US"])

        extras.setChecked(headers, to: true)
        #expect(extras.checkedItems(in: plan).map(\.id) == [
            "header-en-US", "search-en-US", "header-fr-FR", "search-fr-FR", "search-de-DE", "iphone-en-US",
        ])
        let german = try #require(headers.first { $0.id == "header-de-DE" })
        #expect(!extras.isChecked(german), "An error keeps it out")
    }

    @Test func pushingSendsTheCheckedOnesAndNotesThemInTheSet() async throws {
        let harness = try harness()
        await harness.load()
        let extras = harness.controller.extras
        let plan = try #require(extras.plans[harness.app.id])
        try extras.toggle(#require(plan.items.first { $0.id == "search-fr-FR" }))

        harness.controller.pushExtras([plan])
        let run = try #require(extras.run)
        await run.waitUntilFinished()

        #expect(run.items.map(\.id) == ["header-en-US", "search-en-US", "header-fr-FR", "search-de-DE", "iphone-en-US"])
        #expect(run.doneCount == 5)
        #expect(run.items.first?.localizationID == "loc-en-US")
        #expect(harness.push.extrasLibrary.log.contains { $0.hasPrefix("place") && $0.contains("PRODUCT_PAGE_HEADER_ASSET") && $0.hasSuffix("loc-en-US") })

        let pushed = harness.screenshots.storedDocument?.extras?.pushedChecksums
        #expect(pushed?["header-en-US"] == "header-en-US-sum")
        #expect(pushed?["iphone-en-US"] == "preview-sum")
        #expect(pushed?["header-de-DE"] == nil)
        #expect(extras.plans[harness.app.id]?.items.map(\.id) == ["search-fr-FR", "header-de-DE"])
        #expect(harness.controller.revisions[harness.app.id] == 1)
    }

    @Test func nothingCheckedNothingSent() async throws {
        let harness = try harness()
        await harness.load()
        let extras = harness.controller.extras
        let plan = try #require(extras.plans[harness.app.id])
        for item in plan.pushable { extras.toggle(item) }
        harness.controller.pushExtras([plan])
        #expect(extras.run == nil)
    }
}
#endif
