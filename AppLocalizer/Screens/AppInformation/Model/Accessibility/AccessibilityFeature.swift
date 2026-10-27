//
//  AccessibilityFeature.swift
//  AppLocalizer
//

import Foundation

/// One of the nine Accessibility Nutrition Label features, with the
/// `supports…` attribute that stores it, what it means for people, and
/// Apple's evaluation criteria.
enum AccessibilityFeature: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case voiceOver
    case voiceControl
    case largerText
    case sufficientContrast
    case darkInterface
    case differentiateWithoutColor
    case reducedMotion
    case captions
    case audioDescriptions

    var id: String { rawValue }

    var name: String {
        switch self {
        case .voiceOver: String(localized: "VoiceOver")
        case .voiceControl: String(localized: "Voice Control")
        case .largerText: String(localized: "Larger Text")
        case .sufficientContrast: String(localized: "Sufficient Contrast")
        case .darkInterface: String(localized: "Dark Interface")
        case .differentiateWithoutColor: String(localized: "Differentiate Without Color Alone")
        case .reducedMotion: String(localized: "Reduced Motion")
        case .captions: String(localized: "Captions")
        case .audioDescriptions: String(localized: "Audio Descriptions")
        }
    }

    /// The editor's one-line meaning.
    var meaning: String {
        switch self {
        case .voiceOver:
            String(localized: "People who are blind or have low vision can use every common task with the screen reader.")
        case .voiceControl:
            String(localized: "People can operate every control and enter text by speaking.")
        case .largerText:
            String(localized: "Text grows with the system setting, to at least 200%, without being cut off.")
        case .sufficientContrast:
            String(localized: "Text and controls meet contrast ratios that people with low vision can read.")
        case .darkInterface:
            String(localized: "The app has a dark appearance and follows the system setting.")
        case .differentiateWithoutColor:
            String(localized: "Meaning is never carried by color alone.")
        case .reducedMotion:
            String(localized: "Animations that can cause discomfort are reduced or replaced when Reduce Motion is on.")
        case .captions:
            String(localized: "Video and audio content has captions.")
        case .audioDescriptions:
            String(localized: "Video content has spoken descriptions of what’s on screen.")
        }
    }

    /// The `accessibilityDeclarations` attribute.
    var apiKey: String {
        switch self {
        case .voiceOver: "supportsVoiceover"
        case .voiceControl: "supportsVoiceControl"
        case .largerText: "supportsLargerText"
        case .sufficientContrast: "supportsSufficientContrast"
        case .darkInterface: "supportsDarkInterface"
        case .differentiateWithoutColor: "supportsDifferentiateWithoutColorAlone"
        case .reducedMotion: "supportsReducedMotion"
        case .captions: "supportsCaptions"
        case .audioDescriptions: "supportsAudioDescriptions"
        }
    }

    /// Apple's evaluation criteria for the feature.
    var criteriaURL: URL {
        let slug = switch self {
        case .voiceOver: "voiceover"
        case .voiceControl: "voice-control"
        case .largerText: "larger-text"
        case .sufficientContrast: "sufficient-contrast"
        case .darkInterface: "dark-interface"
        case .differentiateWithoutColor: "differentiate-without-color-alone"
        case .reducedMotion: "reduced-motion"
        case .captions: "captions"
        case .audioDescriptions: "audio-descriptions"
        }
        return URL(string: "https://developer.apple.com/help/app-store-connect/manage-app-accessibility/\(slug)-evaluation-criteria")!
    }

    /// Voice Control doesn't exist on watchOS and tvOS, and Larger Text
    /// isn't asked on macOS.
    func isAvailable(on family: DeviceFamily) -> Bool {
        switch self {
        case .voiceControl: family != .appleWatch && family != .appleTV
        case .largerText: family != .mac
        default: true
        }
    }

    /// Why Apple doesn't ask about it on `family`.
    func unavailableReason(on family: DeviceFamily) -> String {
        switch self {
        case .largerText:
            String(localized: "Larger Text isn’t asked on \(family.name), where text follows the window and the system’s text size.")
        default:
            String(localized: "\(name) isn’t available on \(family.name), so Apple doesn’t ask about it here.")
        }
    }

    /// "About the Labels ↗".
    static let overviewURL = URL(string: "https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels")!
}
