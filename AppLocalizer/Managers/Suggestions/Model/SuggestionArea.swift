//
//  SuggestionArea.swift
//  AppLocalizer
//

import Foundation

/// The two sections that take field suggestions. MCP calls them `store` and
/// `info`.
enum SuggestionArea: String, CaseIterable, Codable, Hashable, Sendable {
    case storePage = "store"
    case appInformation = "info"

    var title: String {
        switch self {
        case .storePage: String(localized: "Store Page")
        case .appInformation: String(localized: "App Information")
        }
    }

    var section: AppWorkspaceSection {
        switch self {
        case .storePage: .storePage
        case .appInformation: .appInformation
        }
    }
}
