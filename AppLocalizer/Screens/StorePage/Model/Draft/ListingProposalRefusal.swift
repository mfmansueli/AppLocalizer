//
//  ListingProposalRefusal.swift
//  AppLocalizer
//

import Foundation

/// Why an assistant's proposal was refused, worded so the assistant can act
/// on it. Proposals go through the same validation as a manual edit.
enum ListingProposalRefusal: Hashable, Sendable {
    case unknownLocale(String)
    /// An App Store locale the app doesn't have yet; the person adds it.
    case localeNotInListing(StoreLocale)
    /// The field belongs to a version that's read-only.
    case notEditable(version: String)
    case overLimit(count: Int, limit: ListingTextLimit)
    case invalidURL

    var reason: String {
        switch self {
        case let .unknownLocale(code):
            String(localized: "“\(code)” isn’t an App Store locale.")
        case let .localeNotInListing(locale):
            String(localized: "\(locale.name) isn’t one of this app’s locales yet. Ask the person to add it in AppLocalizer.")
        case let .notEditable(version):
            String(localized: "Version \(version) is read-only and there’s no editable version.")
        case let .overLimit(count, limit):
            String(localized: "Over the limit: \(count) of \(limit.maximum) \(limit.unit.name).")
        case .invalidURL:
            String(localized: "Not a full https:// URL.")
        }
    }
}
