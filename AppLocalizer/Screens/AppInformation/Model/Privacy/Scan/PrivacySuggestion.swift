//
//  PrivacySuggestion.swift
//  AppLocalizer
//

import Foundation

/// An assistant's answer for one data type (`propose_privacy_answers`),
/// with how sure it is, why, and the evidence. It's only a suggestion: it
/// counts once the person accepts it.
struct PrivacySuggestion: Hashable, Codable, Sendable {
    var answer: PrivacyAnswer
    var confidence: PrivacyConfidence
    /// One line, e.g. "RevenueCat sends receipts to its servers and keeps
    /// purchase history per app user ID."
    var rationale: String
    var evidence: [PrivacyEvidence]
    /// e.g. "Claude Code".
    var client: String
}
