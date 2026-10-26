//
//  DebugStorePageServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `StorePageServices` for DEBUG scenes: the sample apps' canned data, or
/// `error`. Never contacts App Store Connect.
@MainActor
struct DebugStorePageServices: StorePageServices {
    var error: AppStoreConnectError?

    func summary(for app: StoreApp) async throws -> StorePageSummary {
        if let error { throw error }
        return DebugSummaries.storePage(for: app.id)
    }
}
#endif
