//
//  DebugCredentialsStore.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// An in-memory `CredentialsStore` for DEBUG scenes: starts with `keys`
/// (none by default) and forgets everything when the app quits.
final class DebugCredentialsStore: CredentialsStore {
    private var keys: [AppStoreConnectCredentials]

    init(keys: [AppStoreConnectCredentials] = []) {
        self.keys = keys
    }

    func loadAll() throws -> [AppStoreConnectCredentials] { keys }

    func save(_ credentials: AppStoreConnectCredentials) throws {
        if let index = keys.firstIndex(where: { $0.keyID == credentials.keyID }) {
            keys[index] = credentials
        } else {
            keys.append(credentials)
        }
    }

    func delete(keyID: String) throws {
        keys.removeAll { $0.keyID == keyID }
    }
}
#endif
