//
//  GuidedLiveLookTextTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Look's line beside Screenshots: the set's look, and whether it's on the
/// App Store yet.
@MainActor
@Suite("Guided look · the current look's line")
struct GuidedLiveLookTextTests {
    private static let app = "Bruma – Gay Dating Nearby"

    /// Bruma's said "On the App Store now: Bruma… Caption above device ·
    /// template v1" with nothing pushed.
    @Test func aLookNotPushedYetSaysSo() {
        let text = ScreenshotStudioModel.liveLookText(
            template: "\(Self.app) · Caption above device", app: Self.app, version: 1, isLive: false
        )
        #expect(text == "Your look so far: Caption above device · template v1, not on the App Store yet")
    }

    @Test func aPushedLookIsOnTheAppStore() {
        let text = ScreenshotStudioModel.liveLookText(
            template: "\(Self.app) · Caption above device", app: Self.app, version: 4, isLive: true
        )
        #expect(text == "On the App Store now: Caption above device · template v4")
    }

    @Test func aLookOfItsOwnKeepsItsName() {
        let text = ScreenshotStudioModel.liveLookText(template: "Northpier Night", app: Self.app, version: nil, isLive: true)
        #expect(text == "On the App Store now: Northpier Night")
    }

    @Test func withoutALookItSaysWhatsThere() {
        #expect(ScreenshotStudioModel.liveLookText(template: nil, app: Self.app, version: nil, isLive: true)
            == "On the App Store now: screenshots made outside AppLocalizer")
        #expect(ScreenshotStudioModel.liveLookText(template: nil, app: Self.app, version: nil, isLive: false)
            == "On the App Store now: no screenshots yet")
    }
}
#endif
