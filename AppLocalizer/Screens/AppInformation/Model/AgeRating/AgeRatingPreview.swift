//
//  AgeRatingPreview.swift
//  AppLocalizer
//

import Foundation

/// What the rating preview shows: the rating the answers give, the one
/// the App Store uses (higher when overridden), and the regional ratings.
struct AgeRatingPreview: Hashable, Sendable {
    /// From the answers alone.
    var calculated: AgeRating
    /// The calculated rating, or the override when it's higher.
    var effective: AgeRating
    /// e.g. "16+" or "R 18+".
    var australia: String
    /// Self-rated, e.g. "L", "A10".
    var brazil: String
    /// e.g. "All", "12+".
    var korea: String
}
