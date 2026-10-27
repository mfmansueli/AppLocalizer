//
//  DebugAppInformationChanges.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Pending changes for App Information's DEBUG scenes, built the way the
/// pages build them from Lumen's sample data.
@MainActor
enum DebugAppInformationChanges {
    static var builder: AppInformationChangeBuilder {
        let content = DebugAppInformationContent.lumen(versionID: nil)
        return AppInformationChangeBuilder(appID: DebugFixtures.AppID.lumen, ids: content.ids, versionString: content.version?.versionString)
    }

    /// Claude Code's seven age rating answers; `confirmed` ones can push.
    static func assistantAgeAnswers(confirmed: Set<AgeRatingQuestion>) -> [PendingChange] {
        let values = DebugAppInformationContent.ageRating
        let source = ChangeSource.assistant(client: DebugAppInformationContent.assistant)
        return DebugAppInformationContent.assistantAgeAnswers.compactMap { question, answer in
            builder.ageAnswerChange(question, from: values, to: answer, source: source, confirmed: confirmed.contains(question))
        }
    }

    /// Health or wellness and user-generated content confirmed: "5 not
    /// confirmed yet".
    static let confirmedInAgeScene: Set<AgeRatingQuestion> = [.wellness, .userGeneratedContent]

    /// A family's declaration changed to `features`, on the sample's cards.
    static func declaration(
        _ family: DeviceFamily,
        _ features: Set<AccessibilityFeature>,
        sample: DebugAppInformationContent.AccessibilitySample = .lumen
    ) -> PendingChange? {
        let content = DebugAppInformationContent.accessibility(sample)
        guard let card = builder.accessibilityCards(content, with: []).first(where: { $0.family == family }) else { return nil }
        return builder.declarationChange(for: card, answer: AccessibilityAnswer(features: features))
    }

    /// iPhone adds Reduced Motion: "Published · changes waiting".
    static var iPhoneAddsReducedMotion: PendingChange? {
        declaration(.iPhone, DebugAppInformationContent.iPhoneFeatures.union([.reducedMotion]))
    }

    /// iPad's draft gains Voice Control and Reduced Motion.
    static var iPadToSeven: PendingChange? {
        declaration(.iPad, DebugAppInformationContent.iPhoneFeatures.union([.reducedMotion]))
    }

    /// Apple Vision Pro's draft, which can't publish: + Reduced Motion.
    static var visionAddsReducedMotion: PendingChange? {
        declaration(.vision, DebugAppInformationContent.iPhoneFeatures.union([.reducedMotion]))
    }

    /// Apple Vision Pro's draft without Voice Control, with Reduced Motion.
    static var visionSwapsVoiceControl: PendingChange? {
        declaration(.vision, DebugAppInformationContent.iPhoneFeatures.subtracting([.voiceControl]).union([.reducedMotion]))
    }

    /// The accessibility URL without https://.
    static var invalidURL: PendingChange? {
        builder.accessibilityURLChange(from: "https://lumen.example/accessibility", to: "lumen.example/accessibility")
    }
}
#endif
