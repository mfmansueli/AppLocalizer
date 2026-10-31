//
//  AutopilotShortening.swift
//  AppLocalizer
//

import Foundation

/// A caption that didn't fit, shortened by the assistant while localizing:
/// the ready step asks the person to check it reads well.
struct AutopilotShortening: Codable, Hashable, Sendable {
    var locale: String
    var slot: Int
    var before: String
    var after: String
    var client: String
}
