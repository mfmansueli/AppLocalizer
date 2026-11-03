//
//  AutopilotScreenRequest.swift
//  AppLocalizer
//

import Foundation

/// Suggest Screens, asked and not answered yet: what the person asked for
/// ("one that shows the streak"), if anything.
struct AutopilotScreenRequest: Codable, Hashable, Sendable {
    var ask: String?
    var askedAt: Date
}
