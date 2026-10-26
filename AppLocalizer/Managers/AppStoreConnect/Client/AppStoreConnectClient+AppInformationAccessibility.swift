//
//  AppStoreConnectClient+AppInformationAccessibility.swift
//  AppLocalizer
//

import Foundation

// Accessibility Nutrition Labels. Saving, publishing and deleting are
// `PushRequest`s: `POST /v1/accessibilityDeclarations` (deviceFamily and
// the nine `supports…` booleans, related to the app), `PATCH
// /v1/accessibilityDeclarations/{id}` (the booleans, or `publish: true`;
// drafts only) and `DELETE /v1/accessibilityDeclarations/{id}` (drafts only).
extension AppStoreConnectClient {
    /// Every declaration of the app, any family and state
    /// (`GET /v1/apps/{id}/accessibilityDeclarations`).
    func accessibilityDeclarations(appID: String) async throws -> [AppStoreConnectResource<AccessibilityDeclarationAttributes>] {
        try await allPages(of: "/v1/apps/\(appID)/accessibilityDeclarations", query: [URLQueryItem(name: "limit", value: "200")])
    }
}
