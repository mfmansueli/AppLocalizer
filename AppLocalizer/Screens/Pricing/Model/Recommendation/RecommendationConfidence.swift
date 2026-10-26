//
//  RecommendationConfidence.swift
//  AppLocalizer
//

import Foundation

/// The three-bar confidence badge. Neutral in color: it says what a
/// suggestion is based on, not whether it's good.
enum RecommendationConfidence: Int, CaseIterable, Comparable, Hashable, Sendable {
    /// Purchasing power only.
    case low = 1
    /// Backed by the app's sales in the territory.
    case medium
    /// Backed by an earlier price change there.
    case high

    /// How many of the three bars are filled.
    var bars: Int { rawValue }

    var title: String {
        switch self {
        case .low: "Low confidence"
        case .medium: "Medium confidence"
        case .high: "High confidence"
        }
    }

    /// The suggestion popover's note.
    var note: String {
        switch self {
        case .low: "Purchasing power only. Your sales here are too few to say more."
        case .medium: "Backed by your sales, not by a price test. Expect more starts; Results will show how many."
        case .high: "Backed by an earlier price change in this territory."
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
