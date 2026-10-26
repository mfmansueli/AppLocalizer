//
//  DebugKeyChecker.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// A `KeyChecker` for DEBUG scenes: accepts any key after `delay` (so the
/// "Checking…" state is visible) with the sample account's numbers, or
/// fails with `error`.
struct DebugKeyChecker: KeyChecker {
    var error: (any Error & Sendable)?
    var delay: Duration = .milliseconds(300)
    var salesAccess: SalesAccess = .readable

    func check(_: AppStoreConnectCredentials) async throws -> KeyAccessCheck {
        try await Task.sleep(for: delay)
        if let error { throw error }
        return KeyAccessCheck(appCount: DebugFixtures.apps.count, milliseconds: 182, salesAccess: salesAccess, date: .now)
    }
}
#endif
