//
//  RetentionServices.swift
//  AppLocalizer
//

import Foundation

/// What Pricing → Retention reads: the app's retention messages and
/// offers, the Asset Library's images, and the translator Translate All
/// uses. The live one reads App Store Connect; DEBUG scenes use sample
/// data.
@MainActor
protocol RetentionServices {
    /// Messages, offers and languages, for `subscriptions` (Pricing's).
    func content(for app: StoreApp, subscriptions: [RetentionSubscription]) async throws -> RetentionContent
    /// The library's images, every size (the sheet says which fit).
    func libraryImages(for app: StoreApp) async throws -> [RetentionImage]
    var translator: any ListingTranslator { get }
}
