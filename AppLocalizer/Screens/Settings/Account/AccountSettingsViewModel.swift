//
//  AccountSettingsViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Settings → Account: the saved keys with their last check, "Test
/// Connection" per key, renaming and removing. The keys themselves live in
/// `AppSession`, so the account switcher follows every change.
@MainActor
@Observable
final class AccountSettingsViewModel {
    /// Keys whose "Test Connection" is running.
    private(set) var testing: Set<String> = []
    /// The last failed test per key ID; a passing test clears it.
    private(set) var failures: [String: KeyCheckFailure] = [:]
    /// Why the last remove or rename failed (the Keychain said no).
    private(set) var errorMessage: String?

    let session: AppSession
    private let checker: any KeyChecker

    init(session: AppSession, checker: any KeyChecker) {
        self.session = session
        self.checker = checker
    }

    var keys: [AppStoreConnectCredentials] { session.keys }

    func isInUse(_ keyID: String) -> Bool { session.currentKeyID == keyID }
    func isTesting(_ keyID: String) -> Bool { testing.contains(keyID) }
    func check(for keyID: String) -> KeyAccessCheck? { session.checks[keyID] }
    func failure(for keyID: String) -> KeyCheckFailure? { failures[keyID] }

    func account(for credentials: AppStoreConnectCredentials) -> TeamAccount {
        session.account(for: credentials)
    }

    /// The team's name as App Store Connect gives it, which an empty name
    /// goes back to.
    func teamNameFromAppStoreConnect(for keyID: String) -> String? {
        session.teamNames[keyID]
    }

    /// Signs one request with the key, as Connect did, and records what it
    /// can do.
    func test(keyID: String) async {
        guard let credentials = keys.first(where: { $0.keyID == keyID }), !testing.contains(keyID) else { return }
        testing.insert(keyID)
        defer { testing.remove(keyID) }
        do {
            let check = try await checker.check(credentials)
            session.record(check, for: keyID)
            failures[keyID] = nil
        } catch {
            failures[keyID] = KeyCheckFailure(error)
        }
    }

    func use(keyID: String) {
        session.select(keyID: keyID)
    }

    func remove(keyID: String) {
        do {
            try session.remove(keyID: keyID)
            failures[keyID] = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rename(keyID: String, to name: String) {
        do {
            try session.rename(keyID: keyID, to: name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
