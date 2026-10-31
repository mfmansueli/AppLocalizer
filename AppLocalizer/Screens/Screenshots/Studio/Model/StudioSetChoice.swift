//
//  StudioSetChoice.swift
//  AppLocalizer
//

import Foundation

/// The header's Live · New: what's on the App Store now, or the set
/// waiting in Review & Push.
enum StudioSetChoice: String, CaseIterable, Hashable, Sendable, Identifiable {
    case live
    case new

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: String(localized: "Live")
        case .new: String(localized: "New")
        }
    }
}
