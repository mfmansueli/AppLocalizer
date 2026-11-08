//
//  GuidedTemplatePreviewTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Look step's template preview on every device the app ships on: the
/// ones the run doesn't make with a + and Add … to the Run, the real
/// layouts with Lumen's captions and captures, Mac on a MacBook at 16:10,
/// iPhone Duo, Mac and Apple Vision Pro borrowing the iPad captures,
/// Apple Watch's bare screens, and the note under each.
@MainActor
@Suite("Guided template preview")
struct GuidedTemplatePreviewTests {
    private let data = ScreenshotsSampleData.self

    private func builder(
        _ document: ScreenshotsDocument = ScreenshotsDebugDocuments.document(for: .standard),
        plan: AutopilotPlan = StudioDebugRuns.plan
    ) -> GuidedTemplatePreviewBuilder {
        GuidedTemplatePreviewBuilder(
            document: document, plan: plan, appID: ScreenshotsTestFixtures.app.id, appName: "Lumen", primary: .englishUS,
            engine: ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts), sampleCaptions: ScreenshotsViewModel.sampleCaptions
        )
    }

    /// Lumen on every device, its Mac app captured too.
    private var withMac: ScreenshotsDocument {
        var document = DebugEveryDevice.document
        DebugEveryDevice.addMac(to: &document)
        return document
    }

    // MARK: - Devices

    @Test func theDevicesTheAppShipsOnInTheAppStoresOrder() {
        let devices = GuidedTemplatePreviewDevices.devices(for: [.watch, .mac, .iPad, .iPhone, .iPhoneDuo, .visionPro])
        #expect(devices == [.iPhone, .iPad, .iPhoneDuo, .mac, .visionPro, .watch])
        #expect(GuidedTemplatePreviewDevices.devices(for: [.iPad, .iPhone]) == [.iPhone, .iPad], "No Mac without a Mac app")
        #expect(GuidedTemplatePreviewDevices.devices(for: []) == [.iPhone])
    }

    @Test func aDeviceNoLongerOfferedFallsBackToTheFirstInTheRun() {
        let devices: [ScreenshotDisplayType] = [.iPhone, .iPad, .mac]
        #expect(GuidedTemplatePreviewDevices.device(.mac, in: devices) == .mac)
        #expect(GuidedTemplatePreviewDevices.device(.watch, in: devices) == .iPhone)
        #expect(GuidedTemplatePreviewDevices.device(nil, in: devices) == .iPhone)
        #expect(GuidedTemplatePreviewDevices.device(nil, in: [.mac, .iPad], inRun: [.iPad]) == .iPad)
    }

    @Test func titlesAndSizes() {
        #expect(GuidedTemplatePreviewDevices.sizeTitle(.mac) == "Mac · 2880 × 1800")
        #expect(GuidedTemplatePreviewDevices.sizeTitle(.iPhone, size: PixelSize(width: 1320, height: 2868)) == "iPhone 6.9″ · 1320 × 2868")
        #expect(GuidedTemplatePreviewDevices.sizeTitle(.iPhoneDuo).hasPrefix("iPhone Duo · inner display · "))
        #expect(GuidedTemplatePreviewDevices.key(.mac) == "mac")
        #expect(GuidedTemplatePreviewDevices.title(.mac) == "Mac")
        #expect(GuidedTemplatePreviewDevices.title(.visionPro) == "Vision Pro")
    }

    @Test func aDeviceNotInTheRunCarriesAPlus() {
        #expect(GuidedTemplatePreviewDevices.label(.mac, isInRun: false) == "Mac +")
        #expect(GuidedTemplatePreviewDevices.label(.iPad, isInRun: true) == "iPad")
        #expect(GuidedTemplatePreviewDevices.help(.mac, isInRun: false) == "Mac · 2880 × 1800 · not in this run yet")
        #expect(GuidedTemplatePreviewDevices.help(.mac, isInRun: true) == "Mac · 2880 × 1800 · in this run")
    }

    @Test func theRunCountSaysHowManyDevicesTheRunMakes() {
        let devices: [ScreenshotDisplayType] = [.iPhone, .iPad, .mac, .watch]
        #expect(GuidedTemplatePreviewDevices.runCount(devices, inRun: [.iPhone, .iPad]) == "2 of 4 devices in this run · + means not in this run")
        #expect(GuidedTemplatePreviewDevices.runCount(devices, inRun: devices) == nil, "Nothing to say when the run makes them all")
    }

    // MARK: - iPhone and iPad

    @Test func iPhoneShowsTheFirstFiveScreensWithTheirCaptures() {
        let preview = builder().preview(.arcade, on: .iPhone, locale: .englishUS)
        #expect(preview.items.count == 5)
        #expect(preview.items.map(\.name) == Array(data.slotNames.prefix(5)))
        #expect(preview.items.allSatisfy { $0.hasCapture && !$0.showsPrimaryInterface && !$0.borrowsIPad })
        #expect(preview.items.allSatisfy { $0.job.layout.canvas.pixelSize == PixelSize(width: 1320, height: 2868) })
        #expect(preview.sizeTitle == "iPhone 6.9″ · 1320 × 2868")
        #expect(preview.note.hasPrefix("The App Store scales this set down for smaller iPhones"))
        #expect(preview.items[2].label == "3 · \(data.slotNames[2])")
    }

    @Test func theCaptionsAreTheLanguagesOwn() {
        let english = builder().preview(.arcade, on: .iPhone, locale: .englishUS)
        let german = builder().preview(.arcade, on: .iPhone, locale: .german)
        #expect(english.items[0].job.key != german.items[0].job.key)
        #expect(german.items[0].job.layout.locale == "de-DE")
    }

    @Test func anIPadLanguageNotCapturedYetSaysWhoseInterfaceShows() {
        // Lumen's iPad is captured in English, German, French and Japanese only.
        let preview = builder().preview(.arcade, on: .iPad, locale: .arabic)
        let allShowPrimary = preview.items.allSatisfy(\.showsPrimaryInterface)
        #expect(allShowPrimary)
        #expect(preview.note.contains("Lumen’s iPad interface isn’t captured in Arabic yet"), "\(preview.note)")
        let german = builder().preview(.arcade, on: .iPad, locale: .german)
        #expect(!german.items.contains { $0.showsPrimaryInterface })
        #expect(!german.note.contains("isn’t captured"))
    }

    // MARK: - Mac

    @Test func macLaysTheTemplateOutOnAMacBook() {
        let preview = builder(withMac, plan: StudioDebugRuns.everyDevicePlan).preview(.arcade, on: .mac, locale: .german)
        #expect(preview.items.count == 5)
        #expect(preview.items.allSatisfy { $0.hasCapture && !$0.borrowsIPad })
        #expect(preview.items.allSatisfy { $0.job.capture?.displayType == .mac })
        #expect(preview.items.allSatisfy { $0.job.layout.canvas.pixelSize == PixelSize(width: 2880, height: 1800) })
        #expect(preview.items.allSatisfy { $0.job.layout.device?.isLaptop == true }, "A MacBook, with its base")
        #expect(preview.sizeTitle == "Mac · 2880 × 1800")
        #expect(preview.note.hasPrefix("Mac App Store screenshots, 16:10: Lumen’s Mac app on a MacBook"))
        #expect(!preview.note.contains("stand in"))
    }

    @Test func macBorrowsTheIPadScreensUntilItsCaptured() {
        let preview = builder().preview(.arcade, on: .mac, locale: .german)
        #expect(preview.items.count == 5)
        let allBorrow = preview.items.allSatisfy(\.borrowsIPad)
        #expect(allBorrow)
        #expect(preview.items.allSatisfy { $0.job.capture?.displayType == .iPad })
        #expect(preview.items.allSatisfy { $0.job.layout.canvas.pixelSize == PixelSize(width: 2880, height: 1800) })
        #expect(preview.note.contains("Its iPad screens stand in until Autopilot captures the Mac app."))
    }

    @Test func macNotInTheRunIsOnlyAPreviewUntilAdded() {
        let preview = builder(withMac, plan: StudioDebugRuns.everyDevicePlan).preview(.arcade, on: .mac, locale: .englishUS)
        #expect(!preview.isInRun)
        #expect(preview.notInRunText == "Mac isn’t in this run yet, so this is only a preview. Add it and Autopilot captures and makes these screenshots too.")
        #expect(preview.addTitle == "Add Mac to the Run")
        var plan = StudioDebugRuns.everyDevicePlan
        plan.setPlans(.mac, true)
        #expect(builder(withMac, plan: plan).preview(.arcade, on: .mac, locale: .englishUS).isInRun)
        #expect(builder().preview(.arcade, on: .iPhone, locale: .englishUS).isInRun, "iPhone is always in the run")
    }

    // MARK: - iPhone Duo and Apple Vision Pro

    @Test func iPhoneDuoBorrowsTheIPadScreensUntilItsCaptured() {
        var plan = StudioDebugRuns.plan
        plan.setPlans(.iPhoneDuo, true)
        let preview = builder(plan: plan).preview(.arcade, on: .iPhoneDuo, locale: .englishUS)
        #expect(preview.items.count == 5)
        let allBorrow = preview.items.allSatisfy(\.borrowsIPad)
        #expect(allBorrow)
        #expect(preview.items.allSatisfy { $0.job.capture?.displayType == .iPad })
        #expect(preview.note.contains("runs Lumen’s iPad layout"))
        #expect(preview.note.contains("The cover display shows the iPhone set."), "Inner display only, by default")
    }

    @Test func visionProShowsItsOwnWindowsWhenCaptured() {
        let preview = builder(DebugEveryDevice.document, plan: StudioDebugRuns.everyDevicePlan).preview(.arcade, on: .visionPro, locale: .englishUS)
        #expect(preview.items.count == DebugEveryDevice.visionWindows.count)
        #expect(preview.items.map(\.name) == DebugEveryDevice.visionWindows.map { data.slotNames[$0.slot] })
        #expect(preview.items.allSatisfy { $0.hasCapture && !$0.borrowsIPad })
        #expect(preview.items.allSatisfy { $0.job.layout.canvas.pixelSize == ScreenshotDisplayType.visionPro.defaultPixelSize })
        #expect(!preview.items[0].job.layout.lines.isEmpty, "The template's caption over the window")
        #expect(preview.note == "The template’s colors and type, with Lumen’s window in space.")
    }

    @Test func visionProBorrowsTheIPadScreensFromThePlan() {
        let preview = builder(plan: StudioDebugRuns.everyDevicePlan).preview(.arcade, on: .visionPro, locale: .englishUS)
        #expect(preview.items.count == StudioDebugRuns.everyDevicePlan.screens(on: .visionPro).count)
        let allBorrow = preview.items.allSatisfy(\.borrowsIPad)
        #expect(allBorrow)
        #expect(preview.note.contains("its iPad screens stand in"))
    }

    // MARK: - Apple Watch

    @Test func appleWatchShowsTheBareScreens() {
        let preview = builder(DebugEveryDevice.document, plan: StudioDebugRuns.everyDevicePlan).preview(.arcade, on: .watch, locale: .englishUS)
        #expect(preview.isWatch)
        #expect(preview.items.map(\.name) == DebugEveryDevice.watchScreens.map(\.name))
        #expect(preview.items.allSatisfy { $0.job.layout.isFullBleed && $0.job.layout.lines.isEmpty })
        #expect(preview.note.contains("no template is applied: this is what people will see"))
    }

    @Test func appleWatchWithoutCapturesSaysWhenTheyCome() {
        let preview = builder(plan: StudioDebugRuns.everyDevicePlan).preview(.arcade, on: .watch, locale: .englishUS)
        #expect(preview.items.count == DebugEveryDevice.watchScreens.count, "The plan's watch screens")
        #expect(!preview.items.contains { $0.hasCapture })
        #expect(preview.note.contains("watch screens show here once Autopilot captures them"))
    }

    // MARK: - Without captures

    @Test func aSetWithoutCapturesStillPreviewsFiveScreens() {
        var document = ScreenshotsDebugDocuments.document(for: .standard)
        document.captures = CaptureIndex()
        let preview = builder(document).preview(.cinema, on: .iPhone, locale: .englishUS)
        #expect(preview.items.count == 5)
        #expect(!preview.items.contains { $0.hasCapture })
        #expect(preview.note.contains("no captures yet"))
    }

    // MARK: - New templates

    /// Social Proof and Arcade, the two latest starters (Templates · 14).
    @Test func socialProofAndArcadeAreNew() {
        let new = TemplateStarter.allCases.filter(\.isNew)
        #expect(new == [.socialProof, .arcade])
    }
}
