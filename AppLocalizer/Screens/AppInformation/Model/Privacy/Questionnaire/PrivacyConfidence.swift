//
//  PrivacyConfidence.swift
//  AppLocalizer
//

import Foundation

/// How sure an assistant is about one App Privacy answer. It describes the
/// evidence, not whether the answer is good or bad, so its badge stays
/// neutral.
enum PrivacyConfidence: String, CaseIterable, Identifiable, Hashable, Codable, Comparable, Sendable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: String(localized: "Low")
        case .medium: String(localized: "Medium")
        case .high: String(localized: "High")
        }
    }

    /// What the level means, for the badge's help text.
    var meaning: String {
        switch self {
        case .low: String(localized: "Depends on something outside the repo")
        case .medium: String(localized: "Inferred from how an SDK is used")
        case .high: String(localized: "A manifest or the code says so")
        }
    }

    /// The badge's filled bars: one, two or three.
    var bars: Int {
        switch self {
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }

    static func < (lhs: PrivacyConfidence, rhs: PrivacyConfidence) -> Bool {
        lhs.bars < rhs.bars
    }
}
