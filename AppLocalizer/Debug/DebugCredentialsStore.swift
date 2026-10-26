//
//  DebugCredentialsStore.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// An in-memory `CredentialsStore` for DEBUG scenes: starts empty and
/// forgets everything when the app quits.
final class DebugCredentialsStore: CredentialsStore {
    private var credentials: AppStoreConnectCredentials?

    func load() throws -> AppStoreConnectCredentials? { credentials }
    func save(_ credentials: AppStoreConnectCredentials) throws { self.credentials = credentials }
    func delete() throws { credentials = nil }
}
#endif
