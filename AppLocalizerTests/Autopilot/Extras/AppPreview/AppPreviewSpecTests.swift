//
//  AppPreviewSpecTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Apple's App Preview rules per device.
@Suite("App Preview spec")
struct AppPreviewSpecTests {
    @Test func iPhoneTakes886By1920EitherWay() throws {
        let portrait = try #require(AppPreviewSpec.spec(for: .iPhone, landscape: false))
        #expect(portrait.pixelSize == PixelSize(width: 886, height: 1920))
        #expect(!portrait.isLandscape)
        let landscape = try #require(AppPreviewSpec.spec(for: .iPhone, landscape: true))
        #expect(landscape.pixelSize == PixelSize(width: 1920, height: 886))
        #expect(landscape.isLandscape)
    }

    @Test func iPadTakes1200By1600EitherWay() {
        #expect(AppPreviewSpec.spec(for: .iPad, landscape: false)?.pixelSize == PixelSize(width: 1200, height: 1600))
        #expect(AppPreviewSpec.spec(for: .iPad, landscape: true)?.pixelSize == PixelSize(width: 1600, height: 1200))
    }

    @Test func otherDevicesTakeNone() {
        for display in [ScreenshotDisplayType.iPhoneDuo, .watch, .visionPro, .mac, .appleTV] {
            #expect(AppPreviewSpec.spec(for: display, landscape: false) == nil)
            #expect(!AppPreviewSpec.displayTypes.contains(display))
        }
        #expect(AppPreviewSpec.displayTypes == [.iPhone, .iPad])
    }

    @Test func theRulesAreApples() throws {
        let spec = try #require(AppPreviewSpec.spec(for: .iPhone, landscape: false))
        #expect(spec.framesPerSecond == 30)
        #expect(spec.minimumSeconds == 15)
        #expect(spec.maximumSeconds == 30)
        #expect(spec.targetSeconds == 24)
        #expect(spec.maximumBytes == 500 * 1024 * 1024)
    }

    @Test func thePosterTimeCodeIsHoursMinutesSecondsFrames() throws {
        var spec = try #require(AppPreviewSpec.spec(for: .iPhone, landscape: false))
        #expect(spec.posterTimeCode == "00:00:05:00")
        spec.posterSeconds = 65.5
        #expect(spec.posterTimeCode == "00:01:05:15")
    }
}
