//
//  SuggestionConfidence.swift
//  AppLocalizer
//

import Foundation

/// How sure an assistant is about an accessibility feature. Never high:
/// code shows intent, not that people can finish a task with the feature.
enum SuggestionConfidence: String, Hashable, Codable, Sendable {
    case low
    case medium

    var title: String {
        switch self {
        case .low: String(localized: "Low")
        case .medium: String(localized: "Medium")
        }
    }
}
