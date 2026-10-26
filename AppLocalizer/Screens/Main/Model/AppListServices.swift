//
//  AppListServices.swift
//  AppLocalizer
//

import Foundation

/// What the app library needs from outside itself. `LiveAppListServices`
/// asks App Store Connect; tests and DEBUG scenes use canned apps.
@MainActor
protocol AppListServices {
    /// Every app in the account, sorted by name.
    func apps() async throws -> [StoreApp]
}
