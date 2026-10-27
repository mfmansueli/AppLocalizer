//
//  DebugAppListServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `AppListServices` for DEBUG scenes: canned apps, or `error`, optionally
/// after `delay` (a long one keeps the loading skeleton on screen).
@MainActor
struct DebugAppListServices: AppListServices {
    var apps: [StoreApp] = DebugFixtures.apps
    var error: AppStoreConnectError?
    var delay: Duration?

    func apps() async throws -> [StoreApp] {
        if let delay { try await Task.sleep(for: delay) }
        if let error { throw error }
        return apps
    }
}
#endif
