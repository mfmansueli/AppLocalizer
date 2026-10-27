//
//  AgeRatingCalculator.swift
//  AppLocalizer
//

import Foundation

/// Works out the rating preview from the questionnaire, so the page can
/// show the result while you answer.
///
/// Apple doesn't publish its exact mapping from answers to ratings, so this
/// follows the design prototype's table (`prototype-logic.js`, `rate`):
///
/// - Graphic sexual content or prolonged graphic violence at any level
///   makes the app Unrated.
/// - Each content answer raises the rating to its level, Infrequent /
///   Frequent: cartoon violence 9+ / 13+, realistic violence 16+ / 18+,
///   sexual content 16+ / 18+, profanity 9+ / 13+, horror 9+ / 13+, mature
///   themes 9+ / 16+, alcohol, tobacco or drugs 13+ / 16+, weapons 9+ / 13+,
///   medical 13+ / 16+, simulated gambling 13+ / 18+, contests 4+ / 9+.
///   Health or wellness topics (Yes/No in the API) is 9+.
/// - Social media is 13+, unrestricted web access 16+, loot boxes 9+,
///   real-money gambling 18+. The other capabilities don't change it.
/// - Australia: at least 16+ with social media or loot boxes, and R 18+
///   with any simulated gambling. Brazil (self-rated): L (A6 with
///   user-generated content), A10, A14, A16, A18. Korea: All, All, 12+,
///   15+, 19+.
///
/// The regional ratings follow the effective rating, so an override moves
/// them too (the prototype kept them on the calculated one).
enum AgeRatingCalculator {
    static func preview(for answers: AgeRatingAnswers, override: AgeRating? = nil) -> AgeRatingPreview {
        let calculated = rating(for: answers)
        let effective = max(calculated, override ?? calculated)
        return AgeRatingPreview(
            calculated: calculated,
            effective: effective,
            australia: australia(effective, answers: answers),
            brazil: brazil(effective, answers: answers),
            korea: korea(effective)
        )
    }

    /// The rating the answers give on their own.
    static func rating(for answers: AgeRatingAnswers) -> AgeRating {
        if answers[.graphicSexualContent].isPresent || answers[.graphicViolence].isPresent { return .unrated }
        var rating = AgeRating.fourPlus
        for question in AgeRatingQuestion.allCases {
            if let level = level(for: question, answer: answers[question]), level > rating { rating = level }
        }
        return rating
    }

    /// The rating one answer asks for, or nil when it asks for nothing.
    static func level(for question: AgeRatingQuestion, answer: AgeRatingAnswer) -> AgeRating? {
        guard answer.isPresent else { return nil }
        if let levels = contentLevels[question] {
            return answer == .frequent ? levels.frequent : levels.infrequent
        }
        return switch question {
        case .wellness, .lootBoxes: .ninePlus
        case .socialMedia: .thirteenPlus
        case .webAccess: .sixteenPlus
        case .gambling: .eighteenPlus
        default: nil
        }
    }

    private static let contentLevels: [AgeRatingQuestion: (infrequent: AgeRating, frequent: AgeRating)] = [
        .cartoonViolence: (.ninePlus, .thirteenPlus),
        .realisticViolence: (.sixteenPlus, .eighteenPlus),
        .sexualContent: (.sixteenPlus, .eighteenPlus),
        .profanity: (.ninePlus, .thirteenPlus),
        .horror: (.ninePlus, .thirteenPlus),
        .matureThemes: (.ninePlus, .sixteenPlus),
        .substances: (.thirteenPlus, .sixteenPlus),
        .weapons: (.ninePlus, .thirteenPlus),
        .medical: (.thirteenPlus, .sixteenPlus),
        .simulatedGambling: (.thirteenPlus, .eighteenPlus),
        .contests: (.fourPlus, .ninePlus),
    ]

    private static func australia(_ rating: AgeRating, answers: AgeRatingAnswers) -> String {
        guard rating != .unrated else { return AgeRating.unrated.title }
        if answers[.simulatedGambling].isPresent, rating < .eighteenPlus { return "R 18+" }
        if answers[.socialMedia].isPresent || answers[.lootBoxes].isPresent, rating < .sixteenPlus { return AgeRating.sixteenPlus.title }
        return rating.title
    }

    private static func brazil(_ rating: AgeRating, answers: AgeRatingAnswers) -> String {
        switch rating {
        case .fourPlus: answers[.userGeneratedContent].isPresent ? "A6" : "L"
        case .ninePlus: "A10"
        case .thirteenPlus: "A14"
        case .sixteenPlus: "A16"
        case .eighteenPlus: "A18"
        case .unrated: "—"
        }
    }

    private static func korea(_ rating: AgeRating) -> String {
        switch rating {
        case .fourPlus, .ninePlus: String(localized: "All")
        case .thirteenPlus: "12+"
        case .sixteenPlus: "15+"
        case .eighteenPlus: "19+"
        case .unrated: "—"
        }
    }
}
