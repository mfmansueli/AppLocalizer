//
//  StoreListing.swift
//  AppLocalizer
//

import Foundation

/// The store page of one app version in every locale it has: the editing
/// model behind Coverage, Editor, Fill, Find and Replace, Import and
/// Translate. App-level fields (name, subtitle, privacy policy URL) are part
/// of it too, and stay editable when the version itself is read-only.
///
/// Every change goes through a method here, so the rules in `ListingFieldDraft`
/// always apply. Pending changes for Review & Push are `pendingChanges`.
struct StoreListing: Hashable, Sendable {
    var appName: String
    let version: ListingVersion
    let primaryLocale: StoreLocale
    /// In the order they were added, primary first. Translation plans follow
    /// this order; the coverage grid uses `displayLocales`.
    private(set) var locales: [StoreLocale]
    private var entries: [StoreLocale: LocaleListing]

    init(appName: String, version: ListingVersion, primaryLocale: StoreLocale, locales: [LocaleListing]) {
        self.appName = appName
        self.version = version
        self.primaryLocale = primaryLocale
        var ordered = [primaryLocale]
        var entries = [primaryLocale: LocaleListing(locale: primaryLocale)]
        for listing in locales {
            if entries[listing.locale] == nil, listing.locale != primaryLocale { ordered.append(listing.locale) }
            entries[listing.locale] = listing
        }
        self.locales = ordered
        self.entries = entries
    }

    // MARK: - Reading

    /// The primary locale first, then the rest by English name, as the
    /// coverage grid lists them.
    var displayLocales: [StoreLocale] {
        [primaryLocale] + locales.dropFirst().sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Fields this version has: all nine, minus What's New on a first version.
    var fields: [ListingField] {
        ListingField.allCases.filter { applies($0) }
    }

    /// App Store locales not in the listing yet, for "Add Locale".
    var addableLocales: [StoreLocale] {
        StoreLocaleCatalog.all.filter { entries[$0] == nil }
    }

    func contains(_ locale: StoreLocale) -> Bool {
        entries[locale] != nil
    }

    func localeListing(_ locale: StoreLocale) -> LocaleListing? {
        entries[locale]
    }

    func draft(_ field: ListingField, in locale: StoreLocale) -> ListingFieldDraft {
        entries[locale]?[field] ?? ListingFieldDraft()
    }

    func draft(_ key: ListingFieldKey) -> ListingFieldDraft {
        draft(key.field, in: key.locale)
    }

    /// The local value: what the editor shows.
    func value(_ field: ListingField, in locale: StoreLocale) -> String {
        draft(field, in: locale).local
    }

    func applies(_ field: ListingField) -> Bool {
        field.applies(toFirstVersion: version.isFirstVersion)
    }

    /// App-level fields are always editable; version-level ones only while
    /// the version is.
    func canEdit(_ field: ListingField) -> Bool {
        applies(field) && (field.level == .app || version.isEditable)
    }

    func validation(of field: ListingField, in locale: StoreLocale) -> ListingFieldValidation {
        ListingFieldValidator.validate(value(field, in: locale), for: field)
    }

    // MARK: - Locales

    /// Adds an empty locale ("Add Locale"). Nothing is created in App Store
    /// Connect until one of its fields is pushed.
    mutating func addLocale(_ locale: StoreLocale) {
        guard entries[locale] == nil else { return }
        locales.append(locale)
        entries[locale] = LocaleListing(locale: locale)
    }

    /// Removes a locale added here that has nothing in App Store Connect
    /// yet. Deleting a live localization isn't modeled; returns false then.
    @discardableResult
    mutating func removeLocale(_ locale: StoreLocale) -> Bool {
        guard locale != primaryLocale, let listing = entries[locale], !listing.hasRemoteText else { return false }
        entries[locale] = nil
        locales.removeAll { $0 == locale }
        return true
    }

    // MARK: - Editing

    /// You changed a field. Adds the locale if it's new; ignored when the
    /// field can't be edited in this version.
    mutating func edit(_ field: ListingField, in locale: StoreLocale, to value: String) {
        update(field, in: locale) { $0.edit(value) }
    }

    /// You accepted a machine translation. URLs are copied, never
    /// translated, so they aren't tagged.
    mutating func acceptMachineTranslation(_ value: String, for field: ListingField, in locale: StoreLocale) {
        update(field, in: locale) { draft in
            if field.isURL { draft.edit(value) } else { draft.acceptMachineTranslation(value) }
        }
    }

    /// "Mark Reviewed" on one field.
    mutating func markReviewed(_ field: ListingField, in locale: StoreLocale) {
        entries[locale]?[field].markReviewed()
    }

    /// "Mark Reviewed" for every field of a locale.
    mutating func markReviewed(_ locale: StoreLocale) {
        for field in ListingField.allCases {
            markReviewed(field, in: locale)
        }
    }

    /// Discards one pending change ("×" in the review sheet).
    mutating func discard(_ key: ListingFieldKey) {
        entries[key.locale]?[key.field].discard()
    }

    /// "Discard All".
    mutating func discardAll() {
        for key in pendingChanges.map(\.key) {
            discard(key)
        }
    }

    mutating func resolveConflict(_ key: ListingFieldKey, keeping choice: ListingConflictChoice) {
        entries[key.locale]?[key.field].resolveConflict(keeping: choice)
    }

    /// These changes reached App Store Connect.
    mutating func markPushed(_ keys: some Sequence<ListingFieldKey>) {
        for key in keys {
            entries[key.locale]?[key.field].markPushed()
        }
    }

    /// A fresh fetch of one field from App Store Connect.
    mutating func updateRemote(_ value: String, for field: ListingField, in locale: StoreLocale) {
        addLocale(locale)
        entries[locale]?[field].updateRemote(value)
    }

    /// Runs a change on one draft if the field is editable, adding the
    /// locale when needed.
    mutating func update(_ field: ListingField, in locale: StoreLocale, _ change: (inout ListingFieldDraft) -> Void) {
        guard canEdit(field) else { return }
        addLocale(locale)
        guard var listing = entries[locale] else { return }
        change(&listing[field])
        entries[locale] = listing
    }
}
