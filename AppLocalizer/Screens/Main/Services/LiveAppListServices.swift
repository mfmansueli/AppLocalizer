//
//  LiveAppListServices.swift
//  AppLocalizer
//

import Foundation

/// The real `AppListServices`: `GET /v1/apps`, every page.
@MainActor
struct LiveAppListServices: AppListServices {
    let client: AppStoreConnectClient

    func apps() async throws -> [StoreApp] {
        try await client.apps()
    }
}
