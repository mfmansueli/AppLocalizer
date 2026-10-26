//
//  StoreLocaleMatch.swift
//  AppLocalizer
//

import Foundation

/// What `StoreLocaleCatalog.resolve(_:)` made of a locale code.
enum StoreLocaleMatch: Hashable, Sendable {
    /// The code, or a known alias of it, is an App Store locale.
    case exact(StoreLocale)
    /// Only the language matched, and it has one App Store locale (`de` → `de-DE`).
    case inferred(StoreLocale)
    /// The language has several App Store locales (`pt` → Brazil or Portugal).
    case ambiguous([StoreLocale])
    case unknown

    /// The locale to use, when there's exactly one.
    var locale: StoreLocale? {
        switch self {
        case let .exact(locale), let .inferred(locale): locale
        case .ambiguous, .unknown: nil
        }
    }
}
