//
//  FakeAppListServices.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Answers with `apps`, or throws `error`; counts the loads. `iconURLs`
/// are the icons by app ID (an app missing has none), `teamName` the
/// team's name, and `teamNameError` what asking for it throws.
@MainActor
final class FakeAppListServices: AppListServices {
    var apps: [StoreApp]
    var error: (any Error)?
    var teamName: String?
    var teamNameError: (any Error)?
    var iconURLs: [StoreApp.ID: URL] = [:]
    var iconError: (any Error)?
    private(set) var loads = 0
    private(set) var iconRequests: [StoreApp.ID] = []

    init(apps: [StoreApp] = []) {
        self.apps = apps
    }

    func apps() async throws -> [StoreApp] {
        loads += 1
        if let error { throw error }
        return apps
    }

    func teamName() async throws -> String? {
        if let teamNameError { throw teamNameError }
        return teamName
    }

    func iconURL(appID: StoreApp.ID) async throws -> URL? {
        iconRequests.append(appID)
        if let iconError { throw iconError }
        return iconURLs[appID]
    }
}
