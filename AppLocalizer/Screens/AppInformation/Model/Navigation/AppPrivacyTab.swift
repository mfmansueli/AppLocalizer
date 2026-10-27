//
//  AppPrivacyTab.swift
//  AppLocalizer
//

import Foundation

/// The App Privacy page's tabs.
enum AppPrivacyTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case worksheet
    case checklist
    case urls

    var id: String { rawValue }

    var title: String {
        switch self {
        case .worksheet: String(localized: "Worksheet")
        case .checklist: String(localized: "Fill in App Store Connect")
        case .urls: String(localized: "Privacy URLs")
        }
    }
}
