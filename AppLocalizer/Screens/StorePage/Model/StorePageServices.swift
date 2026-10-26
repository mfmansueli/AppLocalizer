//
//  StorePageServices.swift
//  AppLocalizer
//

import Foundation

/// What the Store Page section needs from outside itself. `LiveStorePageServices`
/// talks to App Store Connect; tests and DEBUG scenes use canned data.
@MainActor
protocol StorePageServices {
    /// The numbers the overview cards and the sidebar show for one app.
    func summary(for app: StoreApp) async throws -> StorePageSummary
}
