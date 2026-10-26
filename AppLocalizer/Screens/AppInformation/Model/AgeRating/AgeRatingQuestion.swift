//
//  AgeRatingQuestion.swift
//  AppLocalizer
//

import Foundation

/// One question of Apple's 2025 age rating questionnaire, with the
/// `ageRatingDeclarations` attribute that stores it.
///
/// Health or wellness topics is a Yes/No question here: the API stores
/// `healthOrWellnessTopics` as a boolean, though the design drew None /
/// Infrequent / Frequent.
enum AgeRatingQuestion: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case cartoonViolence
    case realisticViolence
    case graphicViolence
    case sexualContent
    case graphicSexualContent
    case profanity
    case horror
    case matureThemes
    case substances
    case weapons
    case medical
    case wellness
    case messaging
    case userGeneratedContent
    case socialMedia
    case advertising
    case webAccess
    case parentalControls
    case ageAssurance
    case simulatedGambling
    case contests
    case lootBoxes
    case gambling

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cartoonViolence: String(localized: "Cartoon or fantasy violence")
        case .realisticViolence: String(localized: "Realistic violence")
        case .graphicViolence: String(localized: "Prolonged graphic or sadistic realistic violence")
        case .sexualContent: String(localized: "Sexual content or nudity")
        case .graphicSexualContent: String(localized: "Graphic sexual content and nudity")
        case .profanity: String(localized: "Profanity or crude humor")
        case .horror: String(localized: "Horror or fear themes")
        case .matureThemes: String(localized: "Mature or suggestive themes")
        case .substances: String(localized: "Alcohol, tobacco or drug use or references")
        case .weapons: String(localized: "Guns or other weapons")
        case .medical: String(localized: "Medical or treatment information")
        case .wellness: String(localized: "Health or wellness topics")
        case .messaging: String(localized: "Messaging and chat")
        case .userGeneratedContent: String(localized: "User-generated content")
        case .socialMedia: String(localized: "Social media")
        case .advertising: String(localized: "Advertising")
        case .webAccess: String(localized: "Unrestricted web access")
        case .parentalControls: String(localized: "Parental controls")
        case .ageAssurance: String(localized: "Age assurance")
        case .simulatedGambling: String(localized: "Simulated gambling")
        case .contests: String(localized: "Contests")
        case .lootBoxes: String(localized: "Loot boxes")
        case .gambling: String(localized: "Real-money gambling")
        }
    }

    /// The `ageRatingDeclarations` attribute.
    var apiKey: String {
        switch self {
        case .cartoonViolence: "violenceCartoonOrFantasy"
        case .realisticViolence: "violenceRealistic"
        case .graphicViolence: "violenceRealisticProlongedGraphicOrSadistic"
        case .sexualContent: "sexualContentOrNudity"
        case .graphicSexualContent: "sexualContentGraphicAndNudity"
        case .profanity: "profanityOrCrudeHumor"
        case .horror: "horrorOrFearThemes"
        case .matureThemes: "matureOrSuggestiveThemes"
        case .substances: "alcoholTobaccoOrDrugUseOrReferences"
        case .weapons: "gunsOrOtherWeapons"
        case .medical: "medicalOrTreatmentInformation"
        case .wellness: "healthOrWellnessTopics"
        case .messaging: "messagingAndChat"
        case .userGeneratedContent: "userGeneratedContent"
        case .socialMedia: "socialMedia"
        case .advertising: "advertising"
        case .webAccess: "unrestrictedWebAccess"
        case .parentalControls: "parentalControls"
        case .ageAssurance: "ageAssurance"
        case .simulatedGambling: "gamblingSimulated"
        case .contests: "contests"
        case .lootBoxes: "lootBox"
        case .gambling: "gambling"
        }
    }

    var group: AgeRatingQuestionGroup {
        switch self {
        case .cartoonViolence, .realisticViolence, .graphicViolence, .sexualContent, .graphicSexualContent, .profanity, .horror,
             .matureThemes, .substances, .weapons, .medical, .wellness:
            .content
        case .messaging, .userGeneratedContent, .socialMedia, .advertising, .webAccess, .parentalControls, .ageAssurance:
            .capabilities
        case .simulatedGambling, .contests, .lootBoxes, .gambling:
            .gambling
        }
    }

    /// Whether it's answered None / Infrequent / Frequent.
    var hasLevels: Bool { answers.count == 3 }

    /// The answers it takes, in the picker's order.
    var answers: [AgeRatingAnswer] {
        switch self {
        case .wellness, .messaging, .userGeneratedContent, .socialMedia, .advertising, .webAccess, .parentalControls, .ageAssurance,
             .lootBoxes, .gambling:
            [.negative, .affirmative]
        default:
            [.none, .infrequent, .frequent]
        }
    }

    /// The answer of an untouched questionnaire: None or No.
    var defaultAnswer: AgeRatingAnswer { answers[0] }

    static func question(apiKey: String) -> AgeRatingQuestion? {
        allCases.first { $0.apiKey == apiKey }
    }
}
