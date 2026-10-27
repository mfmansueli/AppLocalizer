//
//  FakeCredentialsStore.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// An in-memory `CredentialsStore` that can be told to fail.
final class FakeCredentialsStore: CredentialsStore {
    var stored: [AppStoreConnectCredentials]
    var loadError: (any Error)?
    var saveError: (any Error)?
    var deleteError: (any Error)?
    private(set) var deletedKeyIDs: [String] = []

    init(stored: [AppStoreConnectCredentials] = []) {
        self.stored = stored
    }

    func loadAll() throws -> [AppStoreConnectCredentials] {
        if let loadError { throw loadError }
        return stored
    }

    func save(_ credentials: AppStoreConnectCredentials) throws {
        if let saveError { throw saveError }
        if let index = stored.firstIndex(where: { $0.keyID == credentials.keyID }) {
            stored[index] = credentials
        } else {
            stored.append(credentials)
        }
    }

    func delete(keyID: String) throws {
        deletedKeyIDs.append(keyID)
        if let deleteError { throw deleteError }
        stored.removeAll { $0.keyID == keyID }
    }
}
