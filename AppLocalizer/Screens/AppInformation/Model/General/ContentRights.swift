//
//  ContentRights.swift
//  AppLocalizer
//

import Foundation

/// The answer to "Does the app contain, show or access third-party
/// content?" (`contentRightsDeclaration` on the app).
enum ContentRights: String, CaseIterable, Hashable, Sendable {
    case usesThirdPartyContent = "USES_THIRD_PARTY_CONTENT"
    case doesNotUseThirdPartyContent = "DOES_NOT_USE_THIRD_PARTY_CONTENT"

    var title: String {
        switch self {
        case .usesThirdPartyContent: String(localized: "Yes")
        case .doesNotUseThirdPartyContent: String(localized: "No")
        }
    }
}
