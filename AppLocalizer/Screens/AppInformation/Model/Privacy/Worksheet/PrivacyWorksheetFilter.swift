//
//  PrivacyWorksheetFilter.swift
//  AppLocalizer
//

import Foundation

/// The worksheet's filter: every answered type, or only what needs a look.
enum PrivacyWorksheetFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case unreviewed
    case lowConfidence
    case openQuestions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .unreviewed: String(localized: "Unreviewed")
        case .lowConfidence: String(localized: "Low confidence")
        case .openQuestions: String(localized: "Open questions")
        }
    }
}
