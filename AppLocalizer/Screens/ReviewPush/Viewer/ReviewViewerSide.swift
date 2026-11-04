//
//  ReviewViewerSide.swift
//  AppLocalizer
//

import Foundation

/// Which side of a slot's old → new the viewer shows: what's on App Store
/// Connect now, or what the push sends.
enum ReviewViewerSide: String, CaseIterable, Hashable, Sendable {
    case live
    case new

    /// "Live Now", "New".
    var title: String {
        switch self {
        case .live: String(localized: "Live Now")
        case .new: String(localized: "New")
        }
    }

    var other: ReviewViewerSide { self == .live ? .new : .live }
}
