//
//  ScreenshotOrientation.swift
//  AppLocalizer
//

import Foundation

/// A canvas orientation, per display type in the template.
enum ScreenshotOrientation: String, Codable, Hashable, Sendable, CaseIterable {
    case portrait
    case landscape

    var title: String {
        switch self {
        case .portrait: String(localized: "Portrait")
        case .landscape: String(localized: "Landscape")
        }
    }
}
