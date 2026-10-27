//
//  PrivacyQuestionEffect.swift
//  AppLocalizer
//

import Foundation

/// What answering an open question Yes or No does: a line that says so,
/// and the answer it gives the data types the question affects (none when
/// the assistant didn't say).
struct PrivacyQuestionEffect: Hashable, Codable, Sendable {
    /// e.g. "Both are marked not collected."
    var summary: String
    var answer: PrivacyAnswer?
}
