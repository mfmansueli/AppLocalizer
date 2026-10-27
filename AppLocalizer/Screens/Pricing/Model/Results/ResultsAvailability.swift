//
//  ResultsAvailability.swift
//  AppLocalizer
//

import Foundation

/// Whether a push's 28 days are up.
enum ResultsAvailability: Hashable, Sendable {
    /// "Day 1 of 28"; results arrive on `arrivesOn`.
    case tooEarly(day: Int, arrivesOn: Date)
    case ready
}
