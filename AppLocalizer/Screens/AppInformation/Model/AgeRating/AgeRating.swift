//
//  AgeRating.swift
//  AppLocalizer
//

import Foundation

/// An App Store age rating in Apple's 2025 scale, ordered from 4+ to
/// Unrated (which is above 18+: the app can't be on the App Store).
enum AgeRating: Int, CaseIterable, Identifiable, Comparable, Hashable, Codable, Sendable {
    case fourPlus = 4
    case ninePlus = 9
    case thirteenPlus = 13
    case sixteenPlus = 16
    case eighteenPlus = 18
    case unrated = 99

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .fourPlus: "4+"
        case .ninePlus: "9+"
        case .thirteenPlus: "13+"
        case .sixteenPlus: "16+"
        case .eighteenPlus: "18+"
        case .unrated: String(localized: "Unrated")
        }
    }

    /// `appStoreAgeRating` and `ageRatingOverrideV2` values.
    var apiValue: String {
        switch self {
        case .fourPlus: "FOUR_PLUS"
        case .ninePlus: "NINE_PLUS"
        case .thirteenPlus: "THIRTEEN_PLUS"
        case .sixteenPlus: "SIXTEEN_PLUS"
        case .eighteenPlus: "EIGHTEEN_PLUS"
        case .unrated: "UNRATED"
        }
    }

    init?(apiValue: String?) {
        guard let rating = Self.allCases.first(where: { $0.apiValue == apiValue }) else { return nil }
        self = rating
    }

    /// The ratings an override can pick: the ones above `calculated`.
    static func overrides(above calculated: AgeRating) -> [AgeRating] {
        [.ninePlus, .thirteenPlus, .sixteenPlus, .eighteenPlus].filter { $0 > calculated }
    }

    /// What App Store Connect shows for a value, including the older scale
    /// (`TWELVE_PLUS`, `SEVENTEEN_PLUS`) this enum doesn't model.
    static func title(forAPIValue value: String?) -> String? {
        guard let value else { return nil }
        if let rating = AgeRating(apiValue: value) { return rating.title }
        switch value {
        case "TWELVE_PLUS": return "12+"
        case "SEVENTEEN_PLUS": return "17+"
        default: return value
        }
    }

    static func < (lhs: AgeRating, rhs: AgeRating) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
