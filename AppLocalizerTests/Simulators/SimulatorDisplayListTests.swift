//
//  SimulatorDisplayListTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// `xcrun simctl io <udid> enumerate` as iPhone Duo's simulator prints it:
/// the inner display is found by its size, as its UUID changes each time
/// the simulator starts.
@Suite("Simulator display list")
struct SimulatorDisplayListTests {
    /// Trimmed from a real iPhone Duo on iOS 27.2.
    static let duo = """
    Port:
        UUID: B8FE8C1E-9A52-4791-86F4-BC2531D6608C
        Class: Unknown
        Port Identifier: com.apple.display.captureservice
        Power state: On

    Port:
        UUID: AAB69CF3-0026-4C8D-992F-62F0EB29006E
        Class: Display
        Port Identifier: com.apple.framebuffer.display
        Power state: On
        Display class: 1
        Default width: 7680
        Default height: 4320
        Default pixel format: 'BGRA'

    Port:
        UUID: 77D0F83D-032B-4393-9E06-26F25C2379F0
        Class: Display
        Port Identifier: com.apple.framebuffer.display
        Power state: On
        Display class: 0
        Default width: 2007
        Default height: 2853
        Default pixel format: 'BGRA'
        IOSurface port:
            width              = 2007
            height             = 2853
            bytes per row      = 8064

    Port:
        UUID: 855583FC-CF05-446D-81FD-D3C7DEB7A733
        Class: Display
        Port Identifier: com.apple.framebuffer.display
        Power state: On
        Display class: 0
        Default width: 1398
        Default height: 2034
        Default pixel format: 'BGRA'

    Port:
        UUID: D8752C37-D9E2-4CE7-BDB9-DCE7C00E681D
        Class: Unknown
        Power state: On
            Name: LCD
            Pixel Size: {1398, 2034}
    """

    @Test func onlyDisplaysWithASizeAreListed() {
        let list = SimulatorDisplayList.parse(Self.duo)
        #expect(list.displays.map(\.id) == [
            "AAB69CF3-0026-4C8D-992F-62F0EB29006E", "77D0F83D-032B-4393-9E06-26F25C2379F0", "855583FC-CF05-446D-81FD-D3C7DEB7A733",
        ])
        #expect(list.displays[1].size == PixelSize(width: 2007, height: 2853))
    }

    @Test func theInnerDisplayIsFoundBySizeEitherWayRound() {
        let list = SimulatorDisplayList.parse(Self.duo)
        let inner = ScreenshotDisplayType.iPhoneDuo.portraitPixelSize
        #expect(list.display(sized: inner)?.id == "77D0F83D-032B-4393-9E06-26F25C2379F0")
        #expect(list.display(sized: inner.rotated)?.id == "77D0F83D-032B-4393-9E06-26F25C2379F0")
        #expect(list.display(sized: PixelSize(width: 1398, height: 2034))?.id == "855583FC-CF05-446D-81FD-D3C7DEB7A733")
        #expect(list.display(sized: PixelSize(width: 1320, height: 2868)) == nil)
    }

    @Test(arguments: ["", "Unable to lookup in current state: Shutdown", "Port:\n    UUID: X\n    Class: Display"])
    func anythingElseListsNothing(text: String) {
        #expect(SimulatorDisplayList.parse(text).displays.isEmpty)
    }
}
