//
//  CaptionsFilter.swift
//  AppLocalizer
//

import Foundation

/// The Captions toolbar's filter.
enum CaptionsFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    /// Rows with a missing, overflowing or machine-translated caption.
    case needsAttention

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .needsAttention: String(localized: "Needs attention")
        }
    }
}
