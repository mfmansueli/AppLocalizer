//
//  StoreListing+Assistant.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// An assistant proposes text for a field, by App Store Connect locale
    /// code. Only exact codes are accepted (case and `_` don't matter).
    mutating func propose(
        _ value: String,
        for field: ListingField,
        localeCode: String,
        by client: String
    ) -> ListingProposalOutcome {
        guard let locale = StoreLocaleCatalog.locale(code: localeCode) else {
            return .refused(.unknownLocale(localeCode))
        }
        return propose(value, for: field, in: locale, by: client)
    }

    /// An assistant proposes text for a field. Refused when the locale
    /// isn't in the listing, the version is read-only, the value is over
    /// the limit or the URL is invalid; otherwise queued, or kept as a
    /// conflict when you've already changed the field.
    mutating func propose(
        _ value: String,
        for field: ListingField,
        in locale: StoreLocale,
        by client: String
    ) -> ListingProposalOutcome {
        guard contains(locale) else { return .refused(.localeNotInListing(locale)) }
        guard canEdit(field) else { return .refused(.notEditable(version: version.versionString)) }
        switch ListingFieldValidator.validate(value, for: field) {
        case let .overLimit(count, limit): return .refused(.overLimit(count: count, limit: limit))
        case .invalidURL: return .refused(.invalidURL)
        case .valid, .empty: break
        }
        var outcome = ListingProposalOutcome.unchanged
        update(field, in: locale) { outcome = $0.propose(value, by: client) }
        return outcome
    }

    /// "Reject All from <client>": discards every proposal that assistant
    /// made, including ones kept as conflicts. Returns how many.
    @discardableResult
    mutating func discardProposals(from client: String) -> Int {
        var count = 0
        for locale in locales {
            for field in ListingField.allCases {
                update(field, in: locale) { if $0.discardProposal(from: client) { count += 1 } }
            }
        }
        return count
    }
}
