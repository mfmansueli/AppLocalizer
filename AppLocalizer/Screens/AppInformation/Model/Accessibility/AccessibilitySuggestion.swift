//
//  AccessibilitySuggestion.swift
//  AppLocalizer
//

import Foundation

/// An assistant's suggestion for one feature on one family
/// (`propose_accessibility_declaration`), shown in the editor as a CC tag.
struct AccessibilitySuggestion: Hashable, Codable, Sendable {
    var feature: AccessibilityFeature
    var supports: Bool
    var confidence: SuggestionConfidence
    /// Why, e.g. "Every color comes from the asset catalog with a dark
    /// variant."
    var rationale: String
    /// The assistant's name, e.g. "Claude Code".
    var client: String
}
