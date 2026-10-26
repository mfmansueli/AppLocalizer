//
//  LiveAppInformationServices.swift
//  AppLocalizer
//

import Foundation

/// The real `AppInformationServices`, backed by App Store Connect.
@MainActor
struct LiveAppInformationServices: AppInformationServices {
    let client: AppStoreConnectClient

    func summary(for _: StoreApp) async throws -> AppInformationSummary {
        throw AppStoreConnectError.notFound(detail: String(localized: "App Information isn't available yet."))
    }
}
