//
//  DebugAppInformationContent+Accessibility.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension DebugAppInformationContent {
    /// The design's accessibility states for Lumen, which runs on iPhone,
    /// iPad, Apple Watch and Apple Vision Pro, with no live version on
    /// Vision Pro yet (it's new in 1.4).
    enum AccessibilitySample {
        /// iPhone published, iPad a draft, Apple Watch not declared, Vision
        /// Pro a draft that can't publish yet.
        case lumen
        /// Nothing declared on any device, no URL.
        case neverDeclared
        /// Only iPhone, as a draft.
        case iPhoneDraft
    }

    static let iPhoneFeatures: Set<AccessibilityFeature> = [
        .voiceOver, .voiceControl, .largerText, .sufficientContrast, .darkInterface, .differentiateWithoutColor,
    ]
    static let iPadDraftID = "lumen-a11y-ipad-draft"

    static func accessibility(_ sample: AccessibilitySample) -> AccessibilityContent {
        let declarations: [AccessibilityDeclaration] = switch sample {
        case .lumen:
            [
                declaration("lumen-a11y-iphone", .iPhone, .published, iPhoneFeatures),
                declaration(iPadDraftID, .iPad, .draft, iPhoneFeatures.subtracting([.voiceControl])),
                declaration("lumen-a11y-vision-draft", .vision, .draft, iPhoneFeatures),
            ]
        case .neverDeclared:
            []
        case .iPhoneDraft:
            [declaration("lumen-a11y-iphone-draft", .iPhone, .draft, [.voiceOver, .largerText, .sufficientContrast, .darkInterface])]
        }
        return AccessibilityContent(
            families: [.iPhone, .iPad, .appleWatch, .vision],
            liveFamilies: [.iPhone, .iPad, .appleWatch],
            declarations: declarations,
            accessibilityURL: sample == .lumen ? "https://lumen.example/accessibility" : "",
            upcomingVersion: "1.4"
        )
    }

    private static func declaration(
        _ id: String,
        _ family: DeviceFamily,
        _ state: AccessibilityDeclarationState,
        _ features: Set<AccessibilityFeature>
    ) -> AccessibilityDeclaration {
        AccessibilityDeclaration(id: id, family: family, state: state, answer: AccessibilityAnswer(features: features))
    }

    /// Another sample app: iPhone and iPad, both published.
    static func releasedAccessibility() -> AccessibilityContent {
        AccessibilityContent(
            families: [.iPhone, .iPad],
            liveFamilies: [.iPhone, .iPad, .appleWatch],
            declarations: [
                declaration("a11y-iphone", .iPhone, .published, [.voiceOver, .darkInterface]),
                declaration("a11y-ipad", .iPad, .published, [.voiceOver, .darkInterface]),
            ],
            accessibilityURL: "",
            upcomingVersion: nil
        )
    }
}
#endif
