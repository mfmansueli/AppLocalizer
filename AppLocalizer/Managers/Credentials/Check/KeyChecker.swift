//
//  KeyChecker.swift
//  AppLocalizer
//

import Foundation

/// Checks a key against App Store Connect: Connect does it before saving a
/// key, Settings → Account on "Test Connection". `LiveKeyChecker` asks
/// Apple; DEBUG scenes and tests use canned ones.
protocol KeyChecker: Sendable {
    /// Throws `AppStoreConnectError.unauthorized` (401), `.forbidden` (403)
    /// or a `URLError` when the key can't be used.
    func check(_ credentials: AppStoreConnectCredentials) async throws -> KeyAccessCheck
}
