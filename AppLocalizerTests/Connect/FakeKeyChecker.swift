//
//  FakeKeyChecker.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Records which keys were checked and answers with `result`.
@MainActor
final class FakeKeyChecker: KeyChecker {
    var error: (any Error)?
    var result = KeyAccessCheck(appCount: 6, milliseconds: 182, salesAccess: .readable, date: Date(timeIntervalSince1970: 1_800_000_000))
    /// Runs inside `check`, to look at a model while Apple is "asked".
    var whileChecking: (() -> Void)?
    private(set) var checked: [AppStoreConnectCredentials] = []

    nonisolated func check(_ credentials: AppStoreConnectCredentials) async throws -> KeyAccessCheck {
        try await answer(credentials)
    }

    private func answer(_ credentials: AppStoreConnectCredentials) throws -> KeyAccessCheck {
        checked.append(credentials)
        whileChecking?()
        if let error { throw error }
        return result
    }
}
