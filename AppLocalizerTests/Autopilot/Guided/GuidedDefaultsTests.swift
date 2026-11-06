//
//  GuidedDefaultsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A guided plan's stops, What to make's three cards, and the Look's
/// template pick button.
@MainActor
@Suite("GuidedDefaults")
struct GuidedDefaultsTests {
    @Test func aGuidedPlanStopsToChooseAndToReview() {
        var plan = AutopilotTestFixtures.singlePlan(stopsToPick: true, stopsToChoose: false)
        plan.stopsToWatchPreview = false
        GuidedDefaults.apply(to: &plan)
        #expect(!plan.stopsToPick, "The assistant picks the captures")
        #expect(plan.stopsToChoose)
        #expect(plan.stopsToWatchPreview, "Watching is part of the review")
    }

    @Test func eachCardTurnsItsPartOnAndOff() {
        var plan = StudioDebugExtras.run(.plan).plan
        let devices = plan.displayTypes
        for part in GuidedReviewPart.allCases {
            GuidedDefaults.setMakes(part, false, in: &plan, devices: devices, canReuse: true)
            #expect(!GuidedDefaults.makes(part, plan), "\(part)")
            GuidedDefaults.setMakes(part, true, in: &plan, devices: devices, canReuse: true)
            #expect(GuidedDefaults.makes(part, plan), "\(part)")
        }
    }

    @Test func anAppPreviewWithoutScreenshotsIsMadeForTheAppsDevices() {
        var plan = StudioDebugExtras.run(.plan).plan
        let devices: [ScreenshotDisplayType] = [.iPhone, .iPad]
        GuidedDefaults.setMakes(.screenshots, false, in: &plan, devices: devices, canReuse: true)
        #expect(!plan.previewDisplays.isEmpty)
        #expect(plan.previewDisplays.allSatisfy(devices.contains))

        GuidedDefaults.setMakes(.screenshots, true, in: &plan, devices: devices, canReuse: true)
        #expect(plan.runChoice.previewDisplays == nil, "Following the screenshots' devices again")
    }

    @Test func onlyArtworkReusesTheLastCaptures() {
        var plan = StudioDebugExtras.run(.plan).plan
        let devices = plan.displayTypes
        GuidedDefaults.setMakes(.screenshots, false, in: &plan, devices: devices, canReuse: true)
        #expect(!plan.runChoice.reusesCaptures, "The App Preview still records")
        GuidedDefaults.setMakes(.appPreview, false, in: &plan, devices: devices, canReuse: true)
        #expect(plan.runChoice.reusesCaptures)

        var noCaptures = plan
        GuidedDefaults.applyCaptureChoice(to: &noCaptures, canReuse: false)
        #expect(!noCaptures.runChoice.reusesCaptures, "Nothing to reuse: captured again")

        GuidedDefaults.setMakes(.screenshots, true, in: &plan, devices: devices, canReuse: true)
        #expect(!plan.runChoice.reusesCaptures)
    }

    // MARK: - Pick toggle

    @Test func thePickButtonSaysWhatItDoes() {
        #expect(GuidedPickToggle.title(number: 2, picked: 2) == "✓ Pick 2 · Remove")
        #expect(GuidedPickToggle.title(number: nil, picked: 1) == "Add to My Picks")
        #expect(GuidedPickToggle.title(number: nil, picked: 3, maximum: 3) == "Replace Pick 3 With This")
        #expect(GuidedPickToggle.isProminent(number: nil))
        #expect(!GuidedPickToggle.isProminent(number: 1))
    }
}
#endif
