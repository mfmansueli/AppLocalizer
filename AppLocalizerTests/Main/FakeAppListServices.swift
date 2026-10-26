//
//  FakeAppListServices.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Answers with `apps`, or throws `error`; counts the loads.
@MainActor
final class FakeAppListServices: AppListServices {
    var apps: [StoreApp]
    var error: (any Error)?
    private(set) var loads = 0

    init(apps: [StoreApp] = []) {
        self.apps = apps
    }

    func apps() async throws -> [StoreApp] {
        loads += 1
        if let error { throw error }
        return apps
    }
}
