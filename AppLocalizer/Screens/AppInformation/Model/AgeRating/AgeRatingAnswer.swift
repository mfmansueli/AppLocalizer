//
//  AgeRatingAnswer.swift
//  AppLocalizer
//

import Foundation

/// An answer in the age rating questionnaire. Content questions take None,
/// Infrequent or Frequent; capabilities and the rest take Yes or No
/// (`AgeRatingQuestion.answers`).
enum AgeRatingAnswer: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case none
    case infrequent
    case frequent
    case negative
    case affirmative

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: String(localized: "None")
        case .infrequent: String(localized: "Infrequent")
        case .frequent: String(localized: "Frequent")
        case .negative: String(localized: "No")
        case .affirmative: String(localized: "Yes")
        }
    }

    /// Anything but None or No.
    var isPresent: Bool { self != .none && self != .negative }

    /// How App Store Connect stores it: `NONE`, `INFREQUENT`, `FREQUENT`,
    /// or a boolean.
    var apiValue: AppInformationAPIValue {
        switch self {
        case .none: .string("NONE")
        case .infrequent: .string("INFREQUENT")
        case .frequent: .string("FREQUENT")
        case .negative: .bool(false)
        case .affirmative: .bool(true)
        }
    }

    /// Reads App Store Connect's value, including the deprecated
    /// `INFREQUENT_OR_MILD` and `FREQUENT_OR_INTENSE`.
    init?(apiValue: AppInformationAPIValue) {
        switch apiValue {
        case .bool(true): self = .affirmative
        case .bool(false): self = .negative
        case .string("NONE"): self = .none
        case .string("INFREQUENT"), .string("INFREQUENT_OR_MILD"): self = .infrequent
        case .string("FREQUENT"), .string("FREQUENT_OR_INTENSE"): self = .frequent
        default: return nil
        }
    }
}
