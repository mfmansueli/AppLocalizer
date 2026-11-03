//
//  AutopilotPickTab.swift
//  AppLocalizer
//

import Foundation

/// Pick captures' tabs when the run makes both screenshots and an App
/// Preview.
enum AutopilotPickTab: String, CaseIterable, Hashable, Sendable {
    case screenshots
    case recording

    var title: String {
        switch self {
        case .screenshots: String(localized: "Screenshots")
        case .recording: String(localized: "App Preview recording")
        }
    }
}
