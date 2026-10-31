//
//  StudioShotChip.swift
//  AppLocalizer
//

import Foundation

/// What's worth knowing about one screenshot in the preview.
enum StudioShotChip: Hashable, Sendable {
    /// This language has none of its own: the App Store shows the primary
    /// language's ("English").
    case fallback(language: String)
    /// In the new set, not pushed yet.
    case new
    /// The assistant shortened its caption to fit.
    case shortened

    var title: String {
        switch self {
        case let .fallback(language): language
        case .new: String(localized: "New")
        case .shortened: String(localized: "Shortened")
        }
    }

    var style: PillStyle {
        switch self {
        case .fallback: .warning
        case .new: .accent
        case .shortened: .machineTranslated
        }
    }

    var help: String {
        switch self {
        case let .fallback(language): String(localized: "No screenshots in this language: the App Store shows \(language).")
        case .new: String(localized: "New in this set; it isn’t on the App Store until you push.")
        case .shortened: String(localized: "The caption was shortened to fit two lines.")
        }
    }
}
