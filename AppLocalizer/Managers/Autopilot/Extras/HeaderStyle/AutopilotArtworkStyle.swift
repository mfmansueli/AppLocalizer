//
//  AutopilotArtworkStyle.swift
//  AppLocalizer
//

import Foundation

/// Where the header and search concepts come from (the plan's Header
/// style): up to three scene templates Claude Design adapts to the app,
/// or three concepts of its own. The raw values are the brief's
/// `art_style`.
enum AutopilotArtworkStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case templates
    case free

    var title: String {
        switch self {
        case .templates: String(localized: "Start from templates")
        case .free: String(localized: "Go freely")
        }
    }
}
