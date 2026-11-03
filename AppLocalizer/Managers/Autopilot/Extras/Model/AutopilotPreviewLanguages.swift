//
//  AutopilotPreviewLanguages.swift
//  AppLocalizer
//

import Foundation

/// Which languages get an App Preview of their own: the primary one only
/// (the App Store shows it in the others), or every language.
enum AutopilotPreviewLanguages: String, Codable, CaseIterable, Hashable, Sendable {
    case primary
    case all
}
