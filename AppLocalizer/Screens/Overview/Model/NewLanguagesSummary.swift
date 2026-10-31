//
//  NewLanguagesSummary.swift
//  AppLocalizer
//

import Foundation

/// The overview's word on languages the app supports that its App Store
/// page doesn't have: the Suggestions card's "New languages" line ("Polish,
/// Turkish, Hebrew") and the Store page card's "Languages" line ("12 · 3
/// more in the app", "12 · 2 new to push").
struct NewLanguagesSummary: Hashable, Sendable {
    /// Locales with an App Store page.
    var storeCount: Int
    /// The project's languages to suggest, in the project's order: not on
    /// the App Store, not added and not said Not Now to.
    var pending: [StoreLocale]
    /// New pages queued and not pushed.
    var addedCount: Int

    init(storeCount: Int, pending: [StoreLocale], addedCount: Int) {
        self.storeCount = storeCount
        self.pending = pending
        self.addedCount = addedCount
    }

    /// Reads it for `appID` from its Store page numbers, what the project
    /// supports and the queue. Languages are suggested only while the
    /// version can change.
    @MainActor
    init(appID: StoreApp.ID, storePage: StorePageSummary, appSupport: AppSupportCenter?, changes: [PendingChange]) {
        let added = ListingChangeBuilder.newLocaleCodes(in: changes, appID: appID).subtracting(storePage.localeCodes)
        let pending = storePage.hasEditableVersion
            ? appSupport?.pendingLanguages(for: appID, storeLocales: storePage.localeCodes + added.sorted()) ?? []
            : []
        self.init(storeCount: storePage.localeCount, pending: pending.compactMap(\.storeLocale), addedCount: added.count)
    }

    /// "Polish, Turkish, Hebrew", or "None".
    var suggestionText: String {
        pending.isEmpty ? String(localized: "None") : pending.map(\.name).joined(separator: ", ")
    }

    /// Whether the Suggestions card's line has languages to name.
    var hasSuggestions: Bool { !pending.isEmpty }

    /// "12 · 2 new to push · 1 more in the app", "12 · 3 more in the app",
    /// or nil when there's nothing new to say.
    var languagesText: String? {
        var parts: [String] = []
        if addedCount > 0 { parts.append(String(localized: "\(addedCount) new to push")) }
        if !pending.isEmpty { parts.append(String(localized: "\(pending.count) more in the app")) }
        guard !parts.isEmpty else { return nil }
        return ([storeCount.formatted()] + parts).joined(separator: " · ")
    }
}
