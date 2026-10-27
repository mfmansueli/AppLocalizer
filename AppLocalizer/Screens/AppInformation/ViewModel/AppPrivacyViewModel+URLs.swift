//
//  AppPrivacyViewModel+URLs.swift
//  AppLocalizer
//

import Foundation

// The Privacy URLs tab: App Store Connect's URLs with queued edits on top.
// Edits queue Review & Push changes; the Privacy Policy URL's are Store
// Page's own, so either page shows them.
extension AppPrivacyViewModel {
    func loadURLs() async {
        if urls.value == nil { urls = .loading }
        do {
            urls = try await .loaded(services.privacyURLs(for: app))
        } catch {
            urls = .failed(String(localized: "Couldn’t load the privacy URLs."))
        }
    }

    /// Refresh: reloads the URLs once they were shown.
    func reloadURLsIfLoaded() async {
        guard urls.value != nil else { return }
        await loadURLs()
    }

    /// The URLs with what's queued for this app laid on top.
    var urlsTable: PrivacyURLsTable? {
        urls.value.map { PrivacyURLsTable(appID: app.id, content: $0, changes: queue.changes(for: app.id)) }
    }

    func setPolicyURL(_ locale: StoreLocale, to value: String) {
        guard let table = urlsTable else { return }
        let (id, change) = table.policyChange(locale, to: value)
        apply(change, id: id)
    }

    func setChoicesURL(_ locale: StoreLocale, to value: String) {
        guard let table = urlsTable else { return }
        let (id, change) = table.choicesChange(locale, to: value)
        apply(change, id: id)
    }

    /// "Fill Missing from English (U.S.)": empty Privacy Policy URLs take
    /// the primary locale's.
    func fillMissingPolicyURLs() {
        guard let table = urlsTable else { return }
        let primary = table.content.primaryLocale
        let source = table.policyURL(primary)
        guard !source.isEmpty else { return }
        let missing = table.missingPolicyLocales.filter { $0 != primary }
        for locale in missing {
            setPolicyURL(locale, to: source)
        }
        say(String(localized: "Filled \(missing.count) locales from \(primary.name). They wait in Review & Push."))
    }

    /// "Privacy Policy URL 37 of 39 locales · User Privacy Choices URL 13 of 39".
    var urlsCoverageText: String? {
        guard let table = urlsTable else { return nil }
        let total = table.locales.count
        return String(localized: "Privacy Policy URL \(table.policyCount) of \(total) locales · User Privacy Choices URL \(table.choicesCount) of \(total)")
    }

    /// Queues or discards, keeping the queue's bookkeeping like the other
    /// App Information edits.
    private func apply(_ change: PendingChange?, id: String) {
        if let owner {
            owner.apply(change, id: id)
        } else if let change {
            queue.upsert(change)
        } else {
            queue.discard(id: id)
        }
    }
}
