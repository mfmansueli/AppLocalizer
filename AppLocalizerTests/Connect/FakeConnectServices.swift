//
//  FakeConnectServices.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Records what the connect screen verified, answers with `verifyError`.
@MainActor
final class FakeConnectServices: ConnectServices {
    var verifyError: (any Error)?
    /// Runs inside `verify`, to look at the model while Apple is "asked".
    var whileVerifying: (() -> Void)?
    private(set) var verified: [AppStoreConnectCredentials] = []

    func verify(_ credentials: AppStoreConnectCredentials) async throws {
        verified.append(credentials)
        whileVerifying?()
        if let verifyError { throw verifyError }
    }
}
