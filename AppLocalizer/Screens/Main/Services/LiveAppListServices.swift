//
//  LiveAppListServices.swift
//  AppLocalizer
//

import Foundation

/// The real `AppListServices`: `GET /v1/apps`, every page; the team's name
/// from its certificates; each icon from the app's latest build.
@MainActor
struct LiveAppListServices: AppListServices {
    let client: AppStoreConnectClient

    func apps() async throws -> [StoreApp] {
        try await client.apps()
    }

    func teamName() async throws -> String? {
        try await client.teamName()
    }

    func iconURL(appID: StoreApp.ID) async throws -> URL? {
        try await client.appIconURL(appID: appID)
    }
}
