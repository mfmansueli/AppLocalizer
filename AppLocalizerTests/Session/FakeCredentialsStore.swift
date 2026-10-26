//
//  FakeCredentialsStore.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// An in-memory `CredentialsStore` that can be told to fail.
final class FakeCredentialsStore: CredentialsStore {
    var stored: AppStoreConnectCredentials?
    var loadError: (any Error)?
    var saveError: (any Error)?
    var deleteError: (any Error)?
    private(set) var deletes = 0

    init(stored: AppStoreConnectCredentials? = nil) {
        self.stored = stored
    }

    func load() throws -> AppStoreConnectCredentials? {
        if let loadError { throw loadError }
        return stored
    }

    func save(_ credentials: AppStoreConnectCredentials) throws {
        if let saveError { throw saveError }
        stored = credentials
    }

    func delete() throws {
        deletes += 1
        if let deleteError { throw deleteError }
        stored = nil
    }
}
