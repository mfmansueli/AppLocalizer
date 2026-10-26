//
//  LiveStorePageServices.swift
//  AppLocalizer
//

import Foundation

/// The real `StorePageServices`, backed by App Store Connect.
@MainActor
struct LiveStorePageServices: StorePageServices {
    let client: AppStoreConnectClient

    func summary(for _: StoreApp) async throws -> StorePageSummary {
        throw AppStoreConnectError.notFound(detail: String(localized: "Store Page isn't available yet."))
    }
}
