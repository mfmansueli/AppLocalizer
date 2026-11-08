//
//  AutopilotCenterSuggestedMusicTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The track picked for the app plays until the person chooses one, and
/// never changes under an App Preview already being cut.
@MainActor
@Suite("App Preview music · picked for the app")
struct AutopilotCenterSuggestedMusicTests {
    private static let pick = AppMusicPick(track: .softAmbient, reason: "People use it alone at night")

    private let center = AutopilotTestFixtures.center()
    private let appID = StudioDebugRuns.appID

    private var extras: AutopilotExtras? { center.run(for: appID)?.plan.alsoMakes }

    @Test func thePickPlaysWhenThePersonHasntChosen() {
        center.install(AutopilotPreviewTestRun.run(.capture))
        #expect(center.suggestPreviewMusic(Self.pick, appID: appID))
        #expect(extras?.previewMusic.track == .softAmbient)
        #expect(extras?.music == nil, "It isn't the person's choice")
        #expect(center.run(for: appID)?.log.last?.text.contains("Soft ambient") == true)
    }

    @Test func thePersonsChoiceWins() {
        var run = AutopilotPreviewTestRun.run(.capture)
        run.plan.alsoMakes.previewMusic = AutopilotPreviewMusic(track: .calmPiano)
        center.install(run)
        #expect(!center.suggestPreviewMusic(Self.pick, appID: appID))
        #expect(extras?.suggestedMusic == nil)
        #expect(extras?.previewMusic.track == .calmPiano)
    }

    @Test func choosingAfterThePickReplacesIt() {
        center.install(AutopilotPreviewTestRun.run(.capture))
        center.suggestPreviewMusic(Self.pick, appID: appID)
        center.update(appID) { $0.plan.alsoMakes.previewMusic = AutopilotPreviewMusic(track: .brightPop) }
        #expect(extras?.previewMusic.track == .brightPop)
    }

    @Test(arguments: [AutopilotStage.localize, .watchPreview, .ready])
    func itDoesntChangeOnceTheVideoIsBeingMade(stage: AutopilotStage) {
        center.install(AutopilotPreviewTestRun.run(stage))
        #expect(!center.suggestPreviewMusic(Self.pick, appID: appID))
        #expect(extras?.suggestedMusic == nil)
    }

    @Test func aRunWithoutAnAppPreviewHasNoMusicToPick() {
        var run = AutopilotPreviewTestRun.run(.capture)
        run.plan.alsoMakes.makesAppPreview = false
        center.install(run)
        #expect(!center.suggestPreviewMusic(Self.pick, appID: appID))
    }

    @Test func theSamePickDoesntFillTheLog() {
        center.install(AutopilotPreviewTestRun.run(.capture))
        center.suggestPreviewMusic(Self.pick, appID: appID)
        let lines = center.run(for: appID)?.log.count
        #expect(center.suggestPreviewMusic(Self.pick, appID: appID))
        #expect(center.run(for: appID)?.log.count == lines)
    }

    @Test func aPlanFromBeforeStillLoads() throws {
        let saved = try JSONEncoder().encode(AutopilotExtras())
        let extras = try JSONDecoder().decode(AutopilotExtras.self, from: saved)
        #expect(extras.suggestedMusic == nil)
        #expect(extras.previewMusic == .standard)
    }
}
#endif
