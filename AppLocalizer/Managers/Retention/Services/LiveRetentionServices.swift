//
//  LiveRetentionServices.swift
//  AppLocalizer
//

import Foundation

/// Retention read from App Store Connect (API 4.6).
struct LiveRetentionServices: RetentionServices {
    let client: AppStoreConnectClient
    var translator: any ListingTranslator = AppleListingTranslator()

    func content(for app: StoreApp, subscriptions: [RetentionSubscription]) async throws -> RetentionContent {
        try await RetentionLoader(transport: client).content(for: app, subscriptions: subscriptions)
    }

    func libraryImages(for app: StoreApp) async throws -> [RetentionImage] {
        try await client.assetLibraryFiles(appID: app.id).compactMap(RetentionImage.init)
    }
}
