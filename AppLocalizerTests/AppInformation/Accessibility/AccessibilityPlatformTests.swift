//
//  AccessibilityPlatformTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What each device family is asked, which families an app has, and the
/// accessibility URL's rules.
@Suite("Accessibility platforms")
struct AccessibilityPlatformTests {
    @Test func voiceControlIsntAskedOnWatchAndTVAndLargerTextIsntAskedOnMac() {
        #expect(DeviceFamily.iPhone.features == AccessibilityFeature.allCases)
        #expect(DeviceFamily.appleWatch.unavailableFeatures == [.voiceControl])
        #expect(DeviceFamily.appleTV.unavailableFeatures == [.voiceControl])
        #expect(DeviceFamily.mac.unavailableFeatures == [.largerText])
        #expect(DeviceFamily.vision.unavailableFeatures.isEmpty)
        #expect(AccessibilityFeature.voiceControl.unavailableReason(on: .appleWatch)
            == "Voice Control isn’t available on Apple Watch, so Apple doesn’t ask about it here.")
    }

    @Test func familiesComeFromPlatformsAndDeclarationsInTheCardsOrder() {
        #expect(AccessibilityContent.families(platforms: ["IOS"], declared: []) == [.iPhone, .iPad])
        #expect(AccessibilityContent.families(platforms: ["VISION_OS", "IOS"], declared: [.appleWatch]) == [.iPhone, .iPad, .appleWatch, .vision])
        #expect(AccessibilityContent.families(platforms: ["MAC_OS", nil], declared: []) == [.mac])
    }

    @Test func eachFeatureHasItsAttributeAndCriteria() {
        #expect(Set(AccessibilityFeature.allCases.map(\.apiKey)).count == 9)
        #expect(AccessibilityFeature.voiceOver.apiKey == "supportsVoiceover")
        #expect(AccessibilityFeature.differentiateWithoutColor.apiKey == "supportsDifferentiateWithoutColorAlone")
        for feature in AccessibilityFeature.allCases {
            #expect(feature.criteriaURL.scheme == "https")
            #expect(feature.criteriaURL.host == "developer.apple.com")
        }
    }

    @Test(arguments: ["", "https://example.com/accessibility", "https://lumen.example", "HTTPS://Example.com/a"])
    func validURLs(_ text: String) {
        #expect(AccessibilityURLValidator.problem(in: text) == nil)
    }

    @Test(arguments: ["lumen.example/accessibility", "http://example.com", "https://localhost/a", "https://exa mple.com", "mailto:a@b.com"])
    func invalidURLs(_ text: String) {
        #expect(AccessibilityURLValidator.problem(in: text) == "Enter a full https address, like https://example.com/accessibility.")
    }
}
