//
//  PrivacySDK.swift
//  AppLocalizer
//

import Foundation

/// A third-party SDK a scan found, e.g. RevenueCat 5.14.2.
struct PrivacySDK: Hashable, Codable, Sendable {
    var name: String
    var version: String?

    /// "RevenueCat 5.14.2".
    var title: String {
        version.map { "\(name) \($0)" } ?? name
    }
}
