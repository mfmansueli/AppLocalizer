//
//  IPhoneDuoTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// iPhone Duo, the foldable, as a third set templates render: App Store
/// Connect's values, which captures belong in it (either display's, as
/// App Store Connect takes both; Autopilot asks for the inner one's), its
/// checks, its canvas and frame, and a row in the set that has nothing to
/// push until it has captures.
@MainActor
@Suite("iPhone Duo")
struct IPhoneDuoTests {
    private static let inner = PixelSize(width: 2007, height: 2853)
    private static let outer = PixelSize(width: 1398, height: 2034)
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)

    private func layout(_ display: ScreenshotDisplayType, template: ScreenshotTemplate = ScreenshotsSampleData.template) -> ScreenshotLayout {
        engine.layout(
            template, slot: 0, locale: .englishUS, displayType: display,
            caption: ScreenshotsTestFixtures.caption("en-US", slot: 0)
        )
    }

    private func capture(_ size: PixelSize) -> ScreenshotCapture {
        ScreenshotsSampleData.capture(locale: "en-US", display: .iPhoneDuo, slot: 0, pixelSize: size)
    }

    // MARK: - Display type

    @Test func itIsAppStoreConnectsIPhoneDuoSet() {
        let duo = ScreenshotDisplayType.iPhoneDuo
        #expect(duo.apiValue == "APP_IPHONE_DUO")
        #expect(ScreenshotDisplayType(apiValue: "APP_IPHONE_DUO") == .iPhoneDuo)
        #expect(duo.previewType == "IPHONE_DUO")
        #expect(duo.title == "iPhone Duo")
        #expect(duo.shortTitle == "iPhone Duo")
        #expect(duo.deviceName == "iPhone Duo")
        #expect(duo.portraitPixelSize == Self.inner)
        #expect(duo.defaultPixelSize == Self.inner)
    }

    @Test func templatesRenderItBetweenIPhoneAndIPadWithTheSetsCaptions() {
        #expect(ScreenshotDisplayType.rendered == [.iPhone, .iPhoneDuo, .iPad])
        #expect(ScreenshotDisplayType.studio == [.iPhone, .iPhoneDuo, .iPad, .watch, .visionPro])
        let duo = ScreenshotDisplayType.iPhoneDuo
        #expect(duo.isRendered)
        #expect(duo.hasCaptions)
        #expect(!duo.hasOwnScreens)
        #expect(!duo.isTablet)
    }

    @Test func onlyIPhoneDuoSaysWhenAppleStartsRequiringIt() {
        #expect(ScreenshotDisplayType.iPhoneDuo.upcomingRequirement == "Required from April 2027 for apps built with the iOS 27.1 SDK")
        #expect(ScreenshotDisplayType.allCases.filter { $0.upcomingRequirement != nil } == [.iPhoneDuo])
    }

    /// The Sets menu lists it with the sizes Apple requires, saying when.
    @Test func theDisplayMenuSaysWhenItsRequired() {
        #expect(DisplayTypeMenu.subtitle(.iPhoneDuo, size: ScreenshotDisplayType.iPhoneDuo.portraitPixelSize) == "2007 × 2853 px · from April 2027")
        #expect(DisplayTypeMenu.subtitle(.iPhone, size: ScreenshotDisplayType.iPhone.portraitPixelSize) == "1320 × 2868 px")
    }

    @Test func itsThumbnailIsWiderThanAnIPhonesAtTheSameHeight() {
        // 2007 / 2853 against 1320 / 2868: about 1.53 times as wide.
        #expect(ScreenshotDisplayType.iPhoneDuo.thumbnailWidth(phone: 100, tablet: 150) == 153)
        #expect(ScreenshotDisplayType.iPhone.thumbnailWidth(phone: 100, tablet: 150) == 100)
        #expect(ScreenshotDisplayType.iPad.thumbnailWidth(phone: 100, tablet: 150) == 150)
        #expect(ScreenshotDisplayType.iPhoneDuo.symbolName == "rectangle.split.2x1")
    }

    // MARK: - Capture sizes

    @Test(arguments: [
        (PixelSize(width: 2007, height: 2853), ScreenshotDisplayType.iPhoneDuo),
        (PixelSize(width: 2853, height: 2007), .iPhoneDuo),
        (PixelSize(width: 1398, height: 2034), .iPhoneDuo),
        (PixelSize(width: 2034, height: 1398), .iPhoneDuo),
        (PixelSize(width: 1320, height: 2868), .iPhone),
        (PixelSize(width: 2064, height: 2752), .iPad),
        (PixelSize(width: 1668, height: 2420), .iPad),
    ])
    func eachCaptureSizeBelongsToOneDevice(size: PixelSize, device: ScreenshotDisplayType) {
        #expect(CaptureSizeRules.deviceClass(of: size) == device)
        #expect(CaptureSizeRules.displayType(pixelSize: size, deviceName: nil) == device)
        #expect(CaptureSizeRules.isSameDevice(size, as: device))
    }

    @Test func theSimulatorsNameGoesBeforeTheSize() {
        #expect(CaptureSizeRules.displayType(pixelSize: PixelSize(width: 1320, height: 2868), deviceName: "iPhone Duo") == .iPhoneDuo)
        #expect(CaptureSizeRules.displayType(pixelSize: nil, deviceName: "iphone duo") == .iPhoneDuo)
        #expect(CaptureSizeRules.displayType(pixelSize: Self.inner, deviceName: "iPhone 17 Pro Max") == .iPhone)
    }

    /// App Store Connect's iPhone Duo set takes 2007 × 2853, 2853 × 2007,
    /// 1398 × 2034 and 2034 × 1398.
    @Test(arguments: [
        PixelSize(width: 2007, height: 2853), PixelSize(width: 2853, height: 2007),
        PixelSize(width: 1398, height: 2034), PixelSize(width: 2034, height: 1398),
    ])
    func eitherDisplaysCapturesFitTheSet(size: PixelSize) {
        #expect(CaptureSizeRules.fits(size, in: .iPhoneDuo))
        let capture = ScreenshotsSampleData.capture(locale: "en-US", display: .iPhoneDuo, slot: 0, pixelSize: size)
        #expect(CaptureCoverage.fits(capture, display: .iPhoneDuo))
        #expect(!CaptureCoverage.fits(capture, display: .iPhone))
    }

    @Test func onlyTheOuterDisplaysSizesAreTheOuterDisplay() {
        #expect(CaptureSizeRules.isDuoOuterDisplay(Self.outer))
        #expect(CaptureSizeRules.isDuoOuterDisplay(Self.outer.rotated))
        #expect(!CaptureSizeRules.isDuoOuterDisplay(Self.inner))
        #expect(!CaptureSizeRules.fits(PixelSize(width: 1320, height: 2868), in: .iPhoneDuo), "Narrower than either display")
    }

    // MARK: - Checks

    @Test func anInnerDisplayCapturePassesTheSizeCheck() {
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.inner), layout: layout(.iPhoneDuo)) == nil)
    }

    @Test func anOuterDisplayCapturePassesInADeviceFrame() {
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.outer), layout: layout(.iPhoneDuo)) == nil)
    }

    /// Full bleed, the outer display's capture would be stretched to the
    /// inner display's width.
    @Test func anOuterDisplayCaptureFullBleedIsScaledTooMuch() throws {
        var band = ScreenshotsSampleData.template
        band.caption.placement = .band
        let fullBleed = layout(.iPhoneDuo, template: band)
        #expect(fullBleed.isFullBleed)
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.inner), layout: fullBleed) == nil)
        let check = try #require(ScreenshotChecker.captureSizeCheck(capture(Self.outer), layout: fullBleed))
        #expect(check.status == .failed)
        #expect(check.shortReason == "Wrong size")
        #expect(check.text == "Wrong size: the capture is 1398 × 2034; it would be scaled by 44%.")
    }

    @Test func anIPhoneCaptureInTheDuoSetAndADuoCaptureInTheIPhoneSetAreTheWrongDevice() throws {
        let phone = try #require(ScreenshotChecker.captureSizeCheck(capture(PixelSize(width: 1320, height: 2868)), layout: layout(.iPhoneDuo)))
        #expect(phone.text == "Wrong size: the capture is 1320 × 2868, an iPhone screenshot. Retake it on an iPhone Duo simulator.")

        let duo = try #require(ScreenshotChecker.captureSizeCheck(capture(Self.inner), layout: layout(.iPhone)))
        #expect(duo.text == "Wrong size: the capture is 2007 × 2853, an iPhone Duo screenshot. Retake it on an iPhone 17 Pro Max simulator.")

        let outerOnIPhone = try #require(ScreenshotChecker.captureSizeCheck(capture(Self.outer), layout: layout(.iPhone)))
        #expect(outerOnIPhone.text.contains("an iPhone Duo screenshot"))
    }

    // MARK: - Canvas and frame

    @Test func itRendersAtTheInnerDisplaysSizeInEitherOrientation() {
        #expect(layout(.iPhoneDuo).canvas.pixelSize == Self.inner)
        var landscape = ScreenshotsSampleData.template
        landscape.canvas.duo = .landscape
        #expect(layout(.iPhoneDuo, template: landscape).canvas.pixelSize == Self.inner.rotated)
        #expect(layout(.iPhone, template: landscape).canvas.pixelSize == PixelSize(width: 1320, height: 2868), "iPhone keeps its own")
    }

    /// The simulator's inner display captures landscape: without an
    /// orientation of its own, the Duo canvas turns to fit it instead of
    /// cropping it into a Wrong size render. A set one stays, and so does
    /// every other device's.
    @Test func anUnsetDuoCanvasLiesTheWayItsCaptureDoes() {
        let template = ScreenshotsSampleData.template
        #expect(template.canvas.duo == nil)
        let landscape = engine.layout(
            template, slot: 0, locale: .englishUS, displayType: .iPhoneDuo,
            caption: ScreenshotsTestFixtures.caption("en-US", slot: 0), captureSize: Self.inner.rotated
        )
        #expect(landscape.canvas.pixelSize == Self.inner.rotated)
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.inner.rotated), layout: landscape) == nil)
        #expect(template.canvas.following(Self.inner, on: .iPhoneDuo) == template.canvas, "A portrait capture keeps it portrait")
        #expect(template.canvas.following(Self.inner.rotated, on: .iPhone) == template.canvas)
        #expect(template.canvas.following(nil, on: .iPhoneDuo) == template.canvas)

        var portrait = template
        portrait.canvas.duo = .portrait
        #expect(portrait.canvas.following(Self.inner.rotated, on: .iPhoneDuo).orientation(for: .iPhoneDuo) == .portrait)
    }

    /// Alba's set: every Duo capture landscape, the template with no Duo
    /// orientation. None is the wrong size, and the render key says it's
    /// turned, so no portrait render made before comes back.
    @Test func landscapeDuoCapturesArentTheWrongSize() throws {
        var document = ScreenshotsDebugDocuments.standard
        for slot in 0..<document.slotCount {
            document.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhoneDuo, slot: slot, pixelSize: Self.inner.rotated))
        }
        let matrix = ScreenshotsTestFixtures.matrix(document)
        let duo = matrix.localizedCells.filter { $0.key.displayType == .iPhoneDuo }
        #expect(!duo.isEmpty)
        #expect(!duo.contains { cell in cell.checks.contains { $0.status == .failed && $0.shortReason == "Wrong size" } })
        let cell = try #require(matrix.cell(locale: "en-US", displayType: .iPhoneDuo, slot: 0))
        #expect(cell.state.isPending)
        #expect(cell.layout?.canvas.pixelSize == Self.inner.rotated)
        let template = try #require(document.template)
        let portraitKey = RenderKey(
            templateHash: template.contentHash, locale: "en-US", displayType: .iPhoneDuo, slot: 0, caption: cell.caption, captureID: cell.capture?.capture.id
        )
        guard case let .render(job) = cell.image else { Issue.record("Not a render"); return }
        #expect(job.key != portraitKey)
    }

    @Test func aTemplateFromBeforeIPhoneDuoIsPortraitThere() throws {
        let canvas = try JSONDecoder().decode(TemplateCanvas.self, from: Data(#"{ "iphone": "landscape", "ipad": "landscape" }"#.utf8))
        #expect(canvas.duo == nil)
        #expect(canvas.orientation(for: .iPhoneDuo) == .portrait)
        #expect(canvas.orientation(for: .iPhone) == .landscape)
        #expect(TemplateCanvas.path(for: .iPhoneDuo) == "canvas.duo")
        #expect(TemplateCanvas.path(for: .iPhone) == "canvas.iphone")
        #expect(TemplateCanvas.path(for: .iPad) == "canvas.ipad")
    }

    @Test func anAssistantCanTurnTheDuoCanvas() throws {
        let applier = TemplateOperationApplier(fonts: ScreenshotsTestFixtures.fonts)
        let turned = try applier.applying([.replace("canvas.duo", with: "landscape")], to: ScreenshotsSampleData.template).get()
        #expect(turned.canvas.orientation(for: .iPhoneDuo) == .landscape)
        let refused = applier.applying([.replace("canvas.duo", with: "sideways")], to: ScreenshotsSampleData.template)
        #expect(throws: TemplateRefusals.self) { try refused.get() }
    }

    @Test func itsFrameIsUnfoldedWithoutAnIsland() throws {
        let shape = ScreenshotLayoutEngine.deviceShape(for: .iPhoneDuo)
        #expect(!shape.hasIsland)
        let phone = ScreenshotLayoutEngine.deviceShape(for: .iPhone)
        let tablet = ScreenshotLayoutEngine.deviceShape(for: .iPad)
        #expect(shape.corner < phone.corner && shape.corner > tablet.corner, "Between an iPhone's round corners and an iPad's")
        let device = try #require(layout(.iPhoneDuo).device)
        #expect(device.island == nil)
    }

    // MARK: - Set

    @Test func withoutCapturesTheDuoRowHasNothingToPush() {
        let document = ScreenshotsDebugDocuments.standard
        let matrix = ScreenshotsTestFixtures.matrix(document)
        #expect(matrix.displays.contains(.iPhoneDuo))
        let row = matrix.row(locale: "en-US", displayType: .iPhoneDuo)
        #expect(row.count == document.slotCount)
        #expect(row.allSatisfy { $0.state == .noCapture })
        #expect(!matrix.localizedCells.contains { $0.key.displayType == .iPhoneDuo && $0.state.isPending })
        #expect(!matrix.failedCells.contains { $0.key.displayType == .iPhoneDuo })
    }

    @Test func withInnerDisplayCapturesTheDuoRowRendersFromTheTemplate() throws {
        var document = ScreenshotsDebugDocuments.standard
        for slot in 0..<document.slotCount {
            document.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhoneDuo, slot: slot))
        }
        let matrix = ScreenshotsTestFixtures.matrix(document)
        let cell = try #require(matrix.cell(locale: "en-US", displayType: .iPhoneDuo, slot: 0))
        #expect(cell.state.isPending)
        #expect(cell.layout?.canvas.pixelSize == Self.inner)
        #expect(cell.caption?.headline == matrix.cell(locale: "en-US", displayType: .iPhone, slot: 0)?.caption?.headline)
    }

    // MARK: - MCP

    @Test(arguments: ["iphone_duo", "iPhoneDuo", "duo", "APP_IPHONE_DUO"])
    func theToolsNameIt(_ name: String) {
        #expect(ScreenshotDisplayType(mcpValue: name) == .iPhoneDuo)
    }

    @Test func theToolsDescribeItsInnerDisplayAndTheRequirement() {
        let json = ScreenshotDisplayType.iPhoneDuo.mcpJSON
        #expect(ScreenshotDisplayType.iPhoneDuo.mcpValue == "iphone_duo")
        #expect(json["displayType"]?.stringValue == "iphone_duo")
        #expect(json["display"]?.stringValue == "inner (unfolded)")
        #expect(json["requirement"]?.stringValue == "Required from April 2027 for apps built with the iOS 27.1 SDK")
        #expect(json["portraitPixelSize"]?["width"]?.intValue == 2007)
        #expect(ScreenshotDisplayType.iPhone.mcpJSON["requirement"] == nil)
    }

    @Test func autopilotSaysHowToCaptureTheInnerDisplay() throws {
        // Open, the inner display is wider than tall; both ways are taken.
        #expect(AutopilotRun.capturePixelSize(.iPhoneDuo) == "2853 × 2007 or 2007 × 2853 (the inner display, open)")
        let how = try #require(AutopilotRun.howToCapture(.iPhoneDuo))
        #expect(how.contains("1398 × 2034"))
        // A UI test's screenshot is the cover display, even with the Duo
        // open, and the test closes the app too soon for simctl: AppLocalizer
        // records the inner display during the test (`DisplayRecorder`).
        #expect(how.contains("A UI test's screenshot (XCUIScreen.main) is the cover display, and the test closes the app right after it"))
        #expect(how.contains("call start_display_recording (it opens the Duo and records the inner display)"))
        #expect(how.contains("then call finish_display_recording with that path"))
        #expect(how.contains("with an upload ID for report_capture; the project needs no change"))
        // Without a UI test, simctl still captures it.
        #expect(how.contains("xcrun simctl io <udid> screenshot --display=<the 2007 × 2853 display's ID from xcrun simctl io <udid> enumerate>"))
    }

    /// Its simulator starts closed and no command opens it: AppLocalizer
    /// does, in Device Hub, so the assistant never opens it itself, and
    /// reports a Duo AppLocalizer couldn't open once and goes on.
    @Test func autopilotSaysTheSimulatorStartsClosedAndAppLocalizerOpensIt() throws {
        let how = try #require(AutopilotRun.howToCapture(.iPhoneDuo))
        #expect(how.contains("It starts closed"))
        #expect(how.contains("no command opens it: AppLocalizer opens it itself (it presses Open in the Duo's window in Device Hub)"))
        #expect(how.contains("Don't open Device Hub, press anything there, or shut down, reboot or erase the Duo yourself"))
        #expect(!how.contains("the person opens it"))
        #expect(how.contains("If start_display_recording says the Duo isn't open"))
        #expect(how.contains("report one problem with affectsDevice: true saying which"))
        #expect(ScreenshotDisplayType.allCases.filter(\.simulatorStartsClosed) == [.iPhoneDuo])
        // By hand only when AppLocalizer can't: its own window has the poses.
        #expect(DeviceHub.openingSteps.hasPrefix("In iPhone Duo’s window in Device Hub, choose Open in the poses at the bottom"))
        #expect(DeviceHub.bundleIdentifier == "com.apple.dt.Devices")
        let link = DeviceHub.windowLink(for: "9F1D621D-9735-4702-9F15-4D2792E475BA")
        #expect(link?.absoluteString == "devices://device/open?id=9F1D621D-9735-4702-9F15-4D2792E475BA")
    }

    /// Switching its displays' power to open it crashed the simulator's
    /// SpringBoard on every start: the assistant is told not to. A stuck Duo
    /// (a spinner, launches that hang) is reported like a closed one, as
    /// AppLocalizer restarts it itself (`DuoWatcher`), opens it and gives
    /// its screens back.
    @Test func autopilotNeverChangesTheDisplaysAndLeavesAStuckDuoToAppLocalizer() throws {
        let how = try #require(AutopilotRun.howToCapture(.iPhoneDuo))
        #expect(how.contains("Never change its displays with xcrun simctl io … screenConfig, which crashes its SpringBoard on every start"))
        #expect(how.contains("or its inner display shows only a spinner, or SpringBoard crashed and xcrun simctl launch hangs (stuck)"))
        #expect(how.contains("with \"AppLocalizer opens iPhone Duo\" as proposedFix, and go on with the other devices"))
        #expect(how.contains("and restarts a stuck one"))
        #expect(how.contains("next_step gives you its screens again once it's open"))
        #expect(!how.contains("Restart iPhone Duo in Device Hub"))
        // By hand only when the helper can't look at it.
        #expect(DeviceHub.restartSteps.hasPrefix("If its inner display shows only a spinner, shut it down there"))
        #expect(!DeviceHub.openingSteps.contains("spinner"))
    }

    @Test func autopilotTakesTheInnerDisplayAndSendsTheOuterOneBack() throws {
        try AutopilotCenter.checkSize(Self.inner, for: .iPhoneDuo)
        try AutopilotCenter.checkSize(Self.inner.rotated, for: .iPhoneDuo)
        let outer = #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(Self.outer, for: .iPhoneDuo) }
        #expect(outer?.message.hasPrefix("A 1398 × 2034 capture is iPhone Duo’s outer display.") == true)
        #expect(outer?.message.contains("capture the inner one, unfolded") == true)
        let phone = #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(PixelSize(width: 1320, height: 2868), for: .iPhoneDuo) }
        #expect(phone?.message == "A 1320 × 2868 capture doesn’t fit iPhone Duo, which takes 2007 × 2853 or 2853 × 2007. Capture on iPhone Duo.")
    }
}
#endif
