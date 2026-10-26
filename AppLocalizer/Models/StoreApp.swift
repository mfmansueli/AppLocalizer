//
//  StoreApp.swift
//  AppLocalizer
//

import Foundation

/// An app in the App Store Connect account. ("App" would clash with
/// SwiftUI's `App` protocol.)
struct StoreApp: Identifiable, Hashable, Sendable {
    /// App Store Connect's resource ID (the Apple ID), e.g. `1234567890`.
    var id: String
    var name: String
    var bundleID: String
    var sku: String?
    /// The locale the store listing falls back to, e.g. `en-US`.
    var primaryLocale: String?
    /// nil draws a letter tile.
    var icon: AppIcon?
}

extension StoreApp {
    init(_ resource: AppStoreConnectResource<AppAttributes>) {
        self.init(
            id: resource.id,
            name: resource.attributes.name,
            bundleID: resource.attributes.bundleId,
            sku: resource.attributes.sku,
            primaryLocale: resource.attributes.primaryLocale
        )
    }
}
