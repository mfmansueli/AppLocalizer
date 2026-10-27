//
//  AccessibilityDeclarationAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `accessibilityDeclarations` attributes: one Accessibility Nutrition
/// Label for a device family (`IPHONE`, `IPAD`, `APPLE_TV`, `APPLE_WATCH`,
/// `MAC`, `VISION`), its state (`DRAFT`, `PUBLISHED`, `REPLACED`) and the
/// nine features. A declaration with every feature false says the app
/// doesn't indicate support.
struct AccessibilityDeclarationAttributes: Decodable, Sendable {
    var deviceFamily: String?
    var state: String?
    var supportsVoiceover: Bool?
    var supportsVoiceControl: Bool?
    var supportsLargerText: Bool?
    var supportsSufficientContrast: Bool?
    var supportsDarkInterface: Bool?
    var supportsDifferentiateWithoutColorAlone: Bool?
    var supportsReducedMotion: Bool?
    var supportsCaptions: Bool?
    var supportsAudioDescriptions: Bool?

    /// The `supports…` booleans by attribute name.
    var supports: [String: Bool] {
        [
            "supportsVoiceover": supportsVoiceover,
            "supportsVoiceControl": supportsVoiceControl,
            "supportsLargerText": supportsLargerText,
            "supportsSufficientContrast": supportsSufficientContrast,
            "supportsDarkInterface": supportsDarkInterface,
            "supportsDifferentiateWithoutColorAlone": supportsDifferentiateWithoutColorAlone,
            "supportsReducedMotion": supportsReducedMotion,
            "supportsCaptions": supportsCaptions,
            "supportsAudioDescriptions": supportsAudioDescriptions,
        ].compactMapValues(\.self)
    }
}
