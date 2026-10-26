//
//  AppInformationServices.swift
//  AppLocalizer
//

import Foundation

/// What the App Information section needs from outside itself. `LiveAppInformationServices`
/// talks to App Store Connect; tests and DEBUG scenes use canned data.
@MainActor
protocol AppInformationServices {
    /// The numbers the overview cards and the sidebar show for one app.
    func summary(for app: StoreApp) async throws -> AppInformationSummary
}
