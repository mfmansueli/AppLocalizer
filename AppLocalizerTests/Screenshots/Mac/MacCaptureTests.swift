//
//  MacCaptureTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Mac as an Autopilot device: App Store Connect's APP_DESKTOP set, always
/// landscape at 2880 × 1800, captured as the whole of this Mac's screen
/// (no simulator), and named "mac" over MCP.
@MainActor
@Suite("Mac captures")
struct MacCaptureTests {
    private static let macBook = PixelSize(width: 2880, height: 1800)
    private static let macBookPro = PixelSize(width: 3024, height: 1964)

    // MARK: - Display type

    @Test func itIsAppStoreConnectsDesktopSetAlwaysLandscape() {
        let mac = ScreenshotDisplayType.mac
        #expect(mac.apiValue == "APP_DESKTOP")
        #expect(mac.isRendered)
        #expect(!mac.isStandard, "Only apps that run on Mac have the set")
        #expect(mac.isAlwaysLandscape)
        #expect(ScreenshotDisplayType.visionPro.isAlwaysLandscape)
        #expect(!ScreenshotDisplayType.iPad.isAlwaysLandscape)
        #expect(mac.defaultPixelSize == Self.macBook)
        #expect(mac.symbolName == "laptopcomputer")
        #expect(mac.deviceName == "Mac")
    }

    @Test func itsCanvasIsALandscapeMacBookScreen() {
        #expect(ScreenshotCanvas(display: .mac, orientation: .landscape).pixelSize == Self.macBook)
        #expect(ScreenshotsSampleData.template.canvas.orientation(for: .mac) == .landscape, "Whatever the template says for iPad")
    }

    @Test(arguments: ["mac", "macos", "desktop", "app_desktop", "MAC"])
    func mcpNamesIt(_ name: String) {
        #expect(ScreenshotDisplayType(mcpValue: name) == .mac)
        #expect(ScreenshotDisplayType.mac.mcpValue == "mac")
    }

    // MARK: - Capture sizes

    @Test(arguments: [
        PixelSize(width: 2880, height: 1800), PixelSize(width: 3024, height: 1964), PixelSize(width: 2560, height: 1600),
        PixelSize(width: 1280, height: 800), PixelSize(width: 3456, height: 2234),
    ])
    func aMacsWholeScreenIsAMacCapture(_ size: PixelSize) {
        #expect(CaptureSizeRules.isMacScreen(size))
        #expect(CaptureSizeRules.deviceClass(of: size) == .mac)
        #expect(CaptureSizeRules.displayType(pixelSize: size, deviceName: nil) == .mac)
    }

    @Test func otherDevicesOnTheirSideAreNot() {
        // iPad, iPad mini (1.52), iPhone and iPhone Duo's inner display, all landscape.
        let sizes = [
            PixelSize(width: 2752, height: 2064), PixelSize(width: 2266, height: 1488),
            PixelSize(width: 2868, height: 1320), PixelSize(width: 2853, height: 2007),
        ]
        for size in sizes {
            #expect(!CaptureSizeRules.isMacScreen(size), "\(size.title)")
            #expect(CaptureSizeRules.deviceClass(of: size) != .mac, "\(size.title)")
        }
        #expect(!CaptureSizeRules.isMacScreen(Self.macBook.rotated), "Portrait")
        #expect(!CaptureSizeRules.isMacScreen(PixelSize(width: 1152, height: 720)), "Smaller than Apple's 1280 × 800")
    }

    @Test func theDeviceNameSaysMac() {
        #expect(CaptureSizeRules.displayType(pixelSize: nil, deviceName: "Mac") == .mac)
        #expect(CaptureSizeRules.displayType(pixelSize: nil, deviceName: "MacBook Pro") == .mac)
        #expect(CaptureSizeRules.displayType(pixelSize: Self.macBook, deviceName: "iPad Pro 13-inch (M5)") == .iPad, "The name wins")
    }

    @Test func aRetinaMacFitsWithoutScaling() {
        #expect(CaptureSizeRules.fits(Self.macBook, in: .mac))
        #expect(CaptureSizeRules.fits(PixelSize(width: 2560, height: 1600), in: .mac))
        #expect(!CaptureSizeRules.fits(PixelSize(width: 1440, height: 900), in: .mac))
    }

    // MARK: - Autopilot's check

    @Test func autopilotTakesAMacsWholeScreen() throws {
        try AutopilotCenter.checkSize(Self.macBook, for: .mac)
        try AutopilotCenter.checkSize(Self.macBookPro, for: .mac)
    }

    @Test func autopilotRefusesAWindowOrAnotherDevice() {
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(PixelSize(width: 2200, height: 1800), for: .mac) }
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(PixelSize(width: 2752, height: 2064), for: .mac) }
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(Self.macBook.rotated, for: .mac) }
        do {
            try AutopilotCenter.checkSize(PixelSize(width: 1100, height: 800), for: .mac)
            Issue.record("A window isn't the whole screen")
        } catch {
            #expect(error.localizedDescription.contains("isn’t a Mac’s whole screen"), "\(error.localizedDescription)")
        }
    }

    // MARK: - This Mac

    @Test func thisMacIsAlwaysReadyWithoutASimulator() throws {
        let inventory = try SimulatorInventory.parse(DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: false, hasDuo: false)))
        let status = inventory.status(for: .mac)
        #expect(status == .ready(simulator: "This Mac", runtime: SimulatorInventory.macOSName))
        #expect(status.canCapture)
        #expect(SimulatorInventory.macOSName.hasPrefix("macOS "))
        #expect(inventory.simulator(for: .mac) == nil)
        #expect(ScreenshotDisplayType.mac.simulatorDeviceTypes.isEmpty)
        #expect(ScreenshotDisplayType.mac.simulatorPlatform == "macOS")
    }
}
#endif
