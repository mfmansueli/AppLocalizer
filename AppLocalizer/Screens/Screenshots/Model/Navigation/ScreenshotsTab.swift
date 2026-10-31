//
//  ScreenshotsTab.swift
//  AppLocalizer
//

import Foundation

/// The screenshots bar's views.
enum ScreenshotsTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    /// The App Store preview, with Screenshot Autopilot above it.
    case preview
    case sets
    case template
    case captions
    case captures

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preview: String(localized: "Preview")
        case .sets: String(localized: "Sets")
        case .template: String(localized: "Template")
        case .captions: String(localized: "Captions")
        case .captures: String(localized: "Captures")
        }
    }

    /// The template editor needs the window's width: the sidebar hides
    /// while it shows.
    var hidesSidebar: Bool { self == .template }
}
