//
//  DebugAppListServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `AppListServices` for DEBUG scenes: canned apps, or `error`.
@MainActor
struct DebugAppListServices: AppListServices {
    var apps: [StoreApp] = DebugFixtures.apps
    var error: AppStoreConnectError?

    func apps() async throws -> [StoreApp] {
        if let error { throw error }
        return apps
    }
}
#endif
