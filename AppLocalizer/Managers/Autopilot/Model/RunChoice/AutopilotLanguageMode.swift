//
//  AutopilotLanguageMode.swift
//  AppLocalizer
//

import Foundation

/// The plan's Languages: All, the primary language only, or Choose….
enum AutopilotLanguageMode: String, Codable, Hashable, Sendable, CaseIterable {
    case all
    case primary
    case chosen
}
