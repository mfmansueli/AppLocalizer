//
//  LiveStorePageServices.swift
//  AppLocalizer
//

import Foundation

/// The real `StorePageServices`, backed by App Store Connect. Requests go
/// one at a time, which keeps the hourly quota for the person's own work and
/// the order predictable.
@MainActor
struct LiveStorePageServices: StorePageServices {
    let client: AppStoreConnectClient
    var machineTranslations: any MachineTranslationStore = FileMachineTranslationStore.shared
    var translator: any ListingTranslator = AppleListingTranslator()

    func summary(for app: StoreApp) async throws -> StorePageSummary {
        let content = try await content(for: app, versionID: nil)
        let tags = MachineTranslationScope.tags(in: machineTranslations, appID: app.id, ids: content.ids)
        return content.summary(machineTranslated: tags)
    }

    func content(for app: StoreApp, versionID: String?) async throws -> StorePageContent {
        try await StorePageContentLoader(client: client).content(for: app, versionID: versionID)
    }

    func inAppTexts(for app: StoreApp) async throws -> InAppTextsContent {
        try await InAppTextsLoader(client: client).content(for: app)
    }

    func screenshots(for _: StoreApp, content: StorePageContent) async throws -> ScreenshotCoverage {
        var counts: [StoreLocale: [ScreenshotDevice: Int]] = [:]
        for locale in content.locales {
            guard let localizationID = content.ids.versionLocalizations[locale] else { continue }
            let sets = try await client.appScreenshotSets(localizationID: localizationID)
            counts[locale] = ScreenshotDevice.counts(in: sets.map { ($0.attributes.screenshotDisplayType, $0.screenshotCount) })
        }
        return ScreenshotCoverage(primaryLocale: content.primaryLocale, counts: counts)
    }
}
