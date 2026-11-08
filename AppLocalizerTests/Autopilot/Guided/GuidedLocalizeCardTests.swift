//
//  GuidedLocalizeCardTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Localize and check's card follows what's being made: Bruma's run said
/// captions were being shortened while its header and search loops drew.
@MainActor
@Suite("Guided localize card")
struct GuidedLocalizeCardTests {
    private var run: AutopilotRun {
        var run = StudioDebugRuns.run(.localize)
        run.plan.alsoMakes.makesArtwork = true
        run.plan.alsoMakes.artworkSize = .headerAndSearch
        run.plan.alsoMakes.artworkMotion = .loop
        run.plan.alsoMakes.makesAppPreview = true
        return run
    }

    @Test func whileCheckingItSaysWhoShortensTheCaptions() {
        let card = GuidedLocalizeCard.make(run, client: "Claude Code")
        #expect(card.title == "Checking every image")
        #expect(card.detail == "Captions that don’t fit are shortened by Claude Code. Every change is listed in the review.")
    }

    @Test func thenTheLoopsDraw() {
        var run = run
        var extras = AutopilotExtrasProgress()
        extras.artworkTotal = 12
        extras.artworkDone = 4
        extras.previewsTotal = 2
        run.extrasProgress = extras
        let card = GuidedLocalizeCard.make(run, client: "Claude Code")
        #expect(card.title == "Header and search artwork")
        #expect(card.detail.hasPrefix("Every language’s 20-second loop is drawn frame by frame on this Mac"))

        run.plan.alsoMakes.artworkMotion = .still
        #expect(GuidedLocalizeCard.make(run, client: "Claude Code").detail == "Every language’s image is drawn and checked. Every caption is in.")
    }

    @Test func thenTheAppPreviews() {
        var run = run
        var extras = AutopilotExtrasProgress()
        extras.artworkTotal = 12
        extras.artworkDone = 12
        extras.previewsTotal = 2
        run.extrasProgress = extras
        #expect(GuidedLocalizeCard.make(run, client: "Claude Code").title == "App Previews")

        run.extrasProgress?.previewsTotal = 1
        #expect(GuidedLocalizeCard.make(run, client: "Claude Code").title == "App Preview")

        run.extrasProgress?.isFinished = true
        #expect(GuidedLocalizeCard.make(run, client: "Claude Code").title == "Checking every image")
    }
}
#endif
