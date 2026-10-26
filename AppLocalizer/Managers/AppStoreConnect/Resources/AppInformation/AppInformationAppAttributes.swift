//
//  AppInformationAppAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `apps` attributes App Information reads: content rights
/// (`USES_THIRD_PARTY_CONTENT` or `DOES_NOT_USE_THIRD_PARTY_CONTENT`, nil
/// when never answered) and the accessibility URL, one per app.
struct AppInformationAppAttributes: Decodable, Sendable {
    var contentRightsDeclaration: String?
    var accessibilityUrl: String?
}
