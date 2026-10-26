//
//  DebugAppInformationServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `AppInformationServices` for DEBUG scenes: the sample apps' canned data, or
/// `error`. Never contacts App Store Connect.
@MainActor
struct DebugAppInformationServices: AppInformationServices {
    var error: AppStoreConnectError?

    func summary(for app: StoreApp) async throws -> AppInformationSummary {
        if let error { throw error }
        return DebugSummaries.appInformation(for: app.id)
    }
}
#endif
