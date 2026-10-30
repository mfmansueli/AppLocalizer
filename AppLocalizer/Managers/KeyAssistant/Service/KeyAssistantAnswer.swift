//
//  KeyAssistantAnswer.swift
//  AppLocalizer
//

import Foundation

/// A model's answer to one request: its text, the tokens it counted (when
/// the vendor said) and how long it took.
struct KeyAssistantAnswer: Hashable, Sendable {
    var text: String
    var tokens: Int?
    var duration: Duration
}
