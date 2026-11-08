//
//  DebugRetentionServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Retention's sample data for Lumen Journal (no messages for the other
/// apps), the Asset Library's four images, and the canned translator.
struct DebugRetentionServices: RetentionServices {
    var launch: RetentionDebugLaunch?
    var translator: any ListingTranslator = DebugListingTranslator()

    func content(for app: StoreApp, subscriptions: [RetentionSubscription]) async throws -> RetentionContent {
        guard app.id == DebugFixtures.AppID.lumen else {
            return RetentionContent(subscriptions: subscriptions, messages: [], offers: [], languages: RetentionLanguages.standard, sourceLocale: .englishUS)
        }
        return RetentionContent(
            subscriptions: subscriptions,
            messages: launch?.remoteMessages ?? [RetentionSampleData.liveMessage],
            offers: RetentionSampleData.offers,
            languages: RetentionLanguages.standard,
            sourceLocale: .englishUS
        )
    }

    func libraryImages(for app: StoreApp) async throws -> [RetentionImage] {
        app.id == DebugFixtures.AppID.lumen ? RetentionSampleData.images : []
    }
}
#endif
