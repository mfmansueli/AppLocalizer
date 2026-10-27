//
//  PrivacyManifestMismatch.swift
//  AppLocalizer
//

import Foundation

/// The cross-check's finding: an SDK's privacy manifest declares a data
/// type the worksheet says isn't collected, e.g. "Sentry 8.36.0’s privacy
/// manifest declares Other Diagnostic Data, but the worksheet says it isn’t
/// collected".
struct PrivacyManifestMismatch: Identifiable, Hashable, Sendable {
    /// e.g. "Sentry 8.36.0".
    var sdk: String
    var type: PrivacyDataType

    var id: String { "\(sdk)|\(type.rawValue)" }

    var message: String {
        String(localized: "\(sdk)’s privacy manifest declares \(type.name), but the worksheet says it isn’t collected.")
    }
}
