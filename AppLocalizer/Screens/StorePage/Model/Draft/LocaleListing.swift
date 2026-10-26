//
//  LocaleListing.swift
//  AppLocalizer
//

import Foundation

/// One locale's fields of a listing. Fields never fetched read as empty.
struct LocaleListing: Hashable, Sendable {
    let locale: StoreLocale
    private var drafts: [ListingField: ListingFieldDraft]

    init(locale: StoreLocale, remote: [ListingField: String] = [:], machineTranslated: Set<ListingField> = []) {
        self.locale = locale
        drafts = remote.reduce(into: [:]) { drafts, entry in
            drafts[entry.key] = ListingFieldDraft(remote: entry.value, isMachineTranslated: machineTranslated.contains(entry.key))
        }
    }

    subscript(field: ListingField) -> ListingFieldDraft {
        get { drafts[field] ?? ListingFieldDraft() }
        set { drafts[field] = newValue }
    }

    /// The local value of a field.
    func value(_ field: ListingField) -> String {
        self[field].local
    }

    /// No field has any text, locally or remotely ("Korean has no text yet").
    var isEmpty: Bool {
        drafts.values.allSatisfy { $0.local.isEmpty && $0.remote.isEmpty }
    }

    /// Some field exists in App Store Connect.
    var hasRemoteText: Bool {
        drafts.values.contains { !$0.remote.isEmpty }
    }
}
