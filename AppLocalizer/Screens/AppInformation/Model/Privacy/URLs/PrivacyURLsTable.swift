//
//  PrivacyURLsTable.swift
//  AppLocalizer
//

import Foundation

/// The Privacy URLs tab: each locale's Privacy Policy URL and User Privacy
/// Choices URL, App Store Connect's values with queued changes on top.
///
/// The Privacy Policy URL is a Store Page field, so its changes are Store
/// Page's own, made by `ListingChangeBuilder` with the same ids and writes:
/// an edit here shows in Store Page and the other way round. The User
/// Privacy Choices URL only exists here; its changes are App Information's.
struct PrivacyURLsTable: Hashable, Sendable {
    let appID: StoreApp.ID
    let content: PrivacyURLsContent
    /// The policy URLs as a Store Page listing, queued edits laid on.
    private(set) var listing: StoreListing
    /// Queued choices URLs by locale.
    private(set) var queuedChoices: [StoreLocale: String] = [:]

    /// Store Page's builder for app-level fields. App Privacy never edits a
    /// version's fields, so the version is a placeholder no change matches.
    var policyBuilder: ListingChangeBuilder {
        var ids = ListingResourceIDs(versionID: Self.noVersion, appInfoID: content.appInfoID)
        for remote in content.locales {
            ids.appInfoLocalizations[remote.locale] = remote.localizationID
        }
        return ListingChangeBuilder(appID: appID, ids: ids, versionString: "")
    }

    var choicesBuilder: AppInformationChangeBuilder {
        AppInformationChangeBuilder(appID: appID, ids: AppInformationResourceIDs(appID: appID, appInfoID: content.appInfoID))
    }

    private static let noVersion = "appPrivacy-none"

    init(appID: StoreApp.ID, content: PrivacyURLsContent, changes: [PendingChange]) {
        self.appID = appID
        self.content = content
        let locales = content.locales.map { LocaleListing(locale: $0.locale, remote: [.privacyPolicyURL: $0.policyURL]) }
        listing = StoreListing(
            appName: "",
            version: ListingVersion("", state: .readyForDistribution),
            primaryLocale: content.primaryLocale,
            locales: locales
        )
        let builder = policyBuilder
        builder.apply(changes.filter { $0.id.hasSuffix(".\(ListingField.privacyPolicyURL.rawValue)") }, to: &listing)
        let choices = choicesBuilder
        for remote in content.locales {
            queuedChoices[remote.locale] = choices.queuedPrivacyChoicesURL(remote.locale, in: changes)
        }
    }

    var locales: [StoreLocale] { content.locales.map(\.locale) }

    // MARK: - Values

    func policyURL(_ locale: StoreLocale) -> String {
        listing.value(.privacyPolicyURL, in: locale)
    }

    func choicesURL(_ locale: StoreLocale) -> String {
        queuedChoices[locale] ?? content.remote(locale)?.choicesURL ?? ""
    }

    /// A queued change App Store Connect doesn't have yet (the dot).
    func isPolicyPending(_ locale: StoreLocale) -> Bool {
        listing.change(for: ListingFieldKey(locale, .privacyPolicyURL)) != nil
    }

    func isChoicesPending(_ locale: StoreLocale) -> Bool {
        queuedChoices[locale] != nil
    }

    /// "Not a valid https URL", or nil. The policy URL is required.
    func policyProblem(_ locale: StoreLocale) -> String? {
        let value = policyURL(locale)
        if value.trimmingCharacters(in: .whitespaces).isEmpty { return String(localized: "Required") }
        return ListingFieldValidator.isValidURL(value) ? nil : ListingBlockReason.invalidURL.message
    }

    func choicesProblem(_ locale: StoreLocale) -> String? {
        let value = choicesURL(locale)
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return ListingFieldValidator.isValidURL(value) ? nil : ListingBlockReason.invalidURL.message
    }

    // MARK: - Coverage

    /// Locales with a valid Privacy Policy URL.
    var policyCount: Int {
        locales.count { policyProblem($0) == nil }
    }

    var choicesCount: Int {
        locales.count { !choicesURL($0).isEmpty && choicesProblem($0) == nil }
    }

    /// Locales whose Privacy Policy URL is empty: Fill Missing fills these.
    var missingPolicyLocales: [StoreLocale] {
        locales.filter { policyURL($0).trimmingCharacters(in: .whitespaces).isEmpty }
    }

    // MARK: - Changes

    /// The queue's change for the policy URL of `locale` set to `value`:
    /// the id it has, and the change, or nil when it's back at App Store
    /// Connect's value and the queued one should go.
    func policyChange(_ locale: StoreLocale, to value: String) -> (id: String, change: PendingChange?) {
        var edited = listing
        edited.edit(.privacyPolicyURL, in: locale, to: value.trimmingCharacters(in: .whitespacesAndNewlines))
        let builder = policyBuilder
        let id = builder.changeID(for: ListingFieldKey(locale, .privacyPolicyURL))
        return (id, builder.changes(for: edited).first { $0.id == id })
    }

    func choicesChange(_ locale: StoreLocale, to value: String) -> (id: String, change: PendingChange?) {
        let builder = choicesBuilder
        let id = builder.privacyChoicesChangeID(locale)
        guard let remote = content.remote(locale) else { return (id, nil) }
        return (id, builder.privacyChoicesChange(for: remote, to: value))
    }
}
