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

    /// The team's name as App Store Connect's certificates give it; nil
    /// when the team has none.
    func teamName() async throws -> String?

    /// An app's icon from its latest build; nil before its first build.
    func iconURL(appID: StoreApp.ID) async throws -> URL?
}
