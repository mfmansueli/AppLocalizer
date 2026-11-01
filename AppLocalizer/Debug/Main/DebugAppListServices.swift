//
//  DebugAppListServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `AppListServices` for DEBUG scenes: canned apps, or `error`, optionally
/// after `delay` (a long one keeps the loading skeleton on screen). The
/// sample apps draw their own icons; `teamName` is what App Store Connect
/// would call the team.
@MainActor
struct DebugAppListServices: AppListServices {
    var apps: [StoreApp] = DebugFixtures.apps
    var error: AppStoreConnectError?
    var delay: Duration?
    var teamName: String?

    func apps() async throws -> [StoreApp] {
        if let delay { try await Task.sleep(for: delay) }
        if let error { throw error }
        return apps
    }

    func teamName() async throws -> String? {
        teamName
    }

    func iconURL(appID _: StoreApp.ID) async throws -> URL? {
        nil
    }
}
#endif
