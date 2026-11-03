//
//  AutopilotRunChoiceTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's "What this run makes": screenshots or not, what a run
/// without them captures, the presets, and the languages.
@MainActor
@Suite("Autopilot run choice")
struct AutopilotRunChoiceTests {
    /// Lumen's five screens on iPhone and iPad in 12 languages.
    private var plan: AutopilotPlan { StudioDebugRuns.plan }

    /// Header and search artwork only.
    private var artworkOnly: AutopilotPlan {
        var plan = plan
        plan.runChoice.makesScreenshots = false
        plan.alsoMakes.makesArtwork = true
        return plan
    }

    @Test func runsFromBeforeMakeScreenshotsAndCaptureAgain() throws {
        #expect(plan.choice == nil)
        #expect(plan.makesScreenshots)
        #expect(!plan.reusesCaptures)
        #expect(plan.runChoice.languages == .all)
        #expect(!plan.makesNothing)

        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(artworkOnly)) as? [String: Any])
        #expect(json["choice"] != nil)
        json.removeValue(forKey: "choice")
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.makesScreenshots)
    }

    @Test func theChoicePersistsWithThePlan() throws {
        var chosen = artworkOnly
        chosen.runChoice.reusesCaptures = true
        chosen.runChoice.previewDisplays = [.iPhone]
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONEncoder().encode(chosen))
        #expect(decoded.runChoice == chosen.runChoice)
    }

    @Test func withoutScreenshotsOnlyTheArtworksScreensAreCapturedOnIPhone() {
        let plan = artworkOnly
        #expect(plan.screensPerLanguage == 0)
        #expect(plan.artworkScreens.map(\.name) == ["Search"], "The header shows no phone: only the search screen")
        #expect(plan.pickedScreens == plan.artworkScreens)
        #expect(plan.targets.count == 12)
        #expect(plan.targets.allSatisfy { $0.displayType == .iPhone })
        #expect(plan.runDisplays == [.iPhone])

        var wide = plan
        wide.alsoMakes.artworkSize = .wide
        #expect(wide.artworkScreens.map(\.name) == ["Search"])

        var primaryOnly = plan
        primaryOnly.capturesEachLanguage = false
        #expect(primaryOnly.targets == plan.artworkScreens.map { AutopilotCaptureTarget(screenID: $0.id, displayType: .iPhone, locale: "en-US") })
    }

    @Test func anAppPreviewOnlyRunRecordsAndCapturesNothing() {
        var plan = plan
        plan.runChoice.makesScreenshots = false
        plan.alsoMakes.makesAppPreview = true
        #expect(plan.targets.isEmpty)
        #expect(plan.pickedScreens.isEmpty)
        #expect(plan.runDisplays == [.iPhone, .iPad])
        #expect(plan.recordingTargets.count == 2)

        plan.runChoice.previewDisplays = [.iPad]
        #expect(plan.previewDisplays == [.iPad])
        #expect(plan.runDisplays == [.iPad])
        #expect(!plan.makesNothing)
    }

    @Test func aRunWithEveryRowOffMakesNothing() {
        var plan = plan
        plan.runChoice.makesScreenshots = false
        #expect(plan.makesNothing)
        #expect(plan.runDisplays.isEmpty)
        plan.alsoMakes.makesAppPreview = true
        plan.runChoice.previewDisplays = []
        #expect(plan.makesNothing, "An App Preview on no device is nothing")
    }

    // MARK: - Presets

    private let devices: [ScreenshotDisplayType] = [.iPhone, .iPad, .iPhoneDuo, .watch]

    @Test(arguments: [AutopilotRunPreset.everything, .screenshots, .headerAndSearch, .appPreview])
    func eachPresetIsRecognizedOnceApplied(preset: AutopilotRunPreset) {
        var plan = plan
        preset.apply(to: &plan, devices: devices, canReuse: true)
        #expect(AutopilotRunPreset.matching(plan, devices: devices) == preset)
    }

    @Test func everythingPlansEveryDeviceTheArtworkAndAnAppPreview() {
        var plan = plan
        AutopilotRunPreset.everything.apply(to: &plan, devices: devices, canReuse: false)
        #expect(plan.displayTypes == [.iPhone, .iPhoneDuo, .iPad, .watch])
        #expect(plan.alsoMakes.makesArtwork)
        #expect(plan.previewDisplays == [.iPhone, .iPad])

        // Leaving a device out is no longer everything.
        plan.setPlans(.watch, false)
        #expect(AutopilotRunPreset.matching(plan, devices: devices) == .custom)
    }

    @Test func headerAndSearchReusesTheLastCapturesWhenThereAreSome() {
        var plan = plan
        AutopilotRunPreset.headerAndSearch.apply(to: &plan, devices: devices, canReuse: true)
        #expect(!plan.makesScreenshots)
        #expect(plan.reusesCaptures)
        #expect(plan.alsoMakes.makesArtwork)
        #expect(!plan.alsoMakes.makesAppPreview)

        var fresh = self.plan
        AutopilotRunPreset.headerAndSearch.apply(to: &fresh, devices: devices, canReuse: false)
        #expect(!fresh.reusesCaptures, "Nothing to reuse")
    }

    @Test func anAppPreviewWithNoDevicesGetsIPhoneAndIPad() {
        var plan = plan
        plan.runChoice.previewDisplays = []
        AutopilotRunPreset.appPreview.apply(to: &plan, devices: devices, canReuse: false)
        #expect(plan.previewDisplays == [.iPhone, .iPad])
        #expect(!plan.makesScreenshots)
    }

    @Test func anyOtherMixIsCustomAndCustomChangesNothing() {
        var plan = plan
        plan.alsoMakes.makesAppPreview = true
        #expect(AutopilotRunPreset.matching(plan, devices: devices) == .custom, "Screenshots and an App Preview")
        let before = plan
        AutopilotRunPreset.custom.apply(to: &plan, devices: devices, canReuse: true)
        #expect(plan == before)
    }

    // MARK: - Languages

    /// English, German and French on the App Store; Polish in the app only.
    private var languagesPlan: AutopilotPlan {
        var plan = plan
        plan.localeCodes = ["en-US", "de-DE", "fr-FR", "pl"]
        plan.newLocaleCodes = ["pl"]
        return plan
    }

    @Test func primaryOnlyKeepsTheStoresLanguagesForAll() {
        var plan = languagesPlan
        #expect(plan.storeLocaleCodes == ["en-US", "de-DE", "fr-FR"])
        #expect(plan.availableLocaleCodes == ["en-US", "de-DE", "fr-FR", "pl"])

        plan.setLanguageMode(.primary)
        #expect(plan.localeCodes == ["en-US"])
        #expect(plan.storeLocaleCodes == ["en-US", "de-DE", "fr-FR"])

        plan.setLanguageMode(.all)
        #expect(plan.localeCodes == ["en-US", "de-DE", "fr-FR"])
        #expect(plan.runChoice.storeLocaleCodes == nil)
    }

    @Test func allKeepsTheNewLanguagesTheRunHad() {
        var plan = languagesPlan
        plan.setLanguageMode(.chosen)
        plan.setLanguageMode(.all)
        #expect(plan.localeCodes == ["en-US", "de-DE", "fr-FR", "pl"])
    }

    @Test func chosenLanguagesFollowTheStoresOrderAndKeepThePrimary() {
        var plan = languagesPlan
        plan.setLanguageMode(.primary)
        plan.setChooses("pl", true)
        plan.setChooses("fr-FR", true)
        #expect(plan.runChoice.languages == .chosen)
        #expect(plan.localeCodes == ["en-US", "fr-FR", "pl"])

        plan.setChooses("en-US", false)
        #expect(plan.localeCodes.first == "en-US", "Picks and the design start from the primary language")
        plan.setChooses("fr-FR", false)
        #expect(plan.localeCodes == ["en-US", "pl"])
    }
}
#endif
