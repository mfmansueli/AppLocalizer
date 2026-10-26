//
//  DebugConnectServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `ConnectServices` for DEBUG scenes: accepts any well-formed key after a
/// short pause (so the "Checking key…" state is visible), or fails with
/// `error`.
@MainActor
struct DebugConnectServices: ConnectServices {
    var error: AppStoreConnectError?

    func verify(_: AppStoreConnectCredentials) async throws {
        try await Task.sleep(for: .milliseconds(300))
        if let error { throw error }
    }
}
#endif
