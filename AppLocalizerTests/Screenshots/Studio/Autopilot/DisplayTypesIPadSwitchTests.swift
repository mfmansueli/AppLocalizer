//
//  DisplayTypesIPadSwitchTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The plan's iPad switch on its display types: iPhone always, iPad 13″
/// last when on.
@Suite("[ScreenshotDisplayType].hasIPad")
struct DisplayTypesIPadSwitchTests {
    @Test(arguments: [
        ([ScreenshotDisplayType.iPhone], false),
        ([.iPhone, .iPad], true),
        ([.iPad], true),
        ([], false),
    ])
    func itReadsWhetherIPadIsIn(displays: [ScreenshotDisplayType], hasIPad: Bool) {
        #expect(displays.hasIPad == hasIPad)
    }

    @Test func turningItOnAddsIPadOnceAfterIPhoneAndOffLeavesIPhone() {
        var displays: [ScreenshotDisplayType] = [.iPhone]
        displays.hasIPad = true
        #expect(displays == [.iPhone, .iPad])
        displays.hasIPad = true
        #expect(displays == [.iPhone, .iPad])
        displays.hasIPad = false
        #expect(displays == [.iPhone])
    }

    @Test(arguments: [[ScreenshotDisplayType](), [.iPad], [.iPad, .iPad]])
    func iPhoneIsAlwaysThere(start: [ScreenshotDisplayType]) {
        var turnedOff = start
        turnedOff.hasIPad = false
        #expect(turnedOff == [.iPhone])
        var turnedOn = start
        turnedOn.hasIPad = true
        #expect(turnedOn == [.iPhone, .iPad])
    }
}
