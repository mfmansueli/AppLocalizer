//
//  StoreRatings.swift
//  AppLocalizer
//

import Foundation

/// The app's average App Store rating in each country a template's
/// laurels and badges are checked against.
struct StoreRatings: Hashable, Sendable {
    /// Average ratings by country (ISO 3166, uppercase).
    private(set) var averages: [String: Double] = [:]
    /// The countries the App Store answered for: one of these without an
    /// average has no rating there yet.
    private(set) var checked: Set<String> = []

    /// Nothing looked up yet.
    static let unchecked = StoreRatings()

    /// What the App Store says about one country.
    enum Status: Hashable, Sendable {
        case rated(Double)
        case unrated
        /// Not looked up, or the answer couldn't be read.
        case unknown
    }

    func status(inCountry country: String) -> Status {
        let country = country.uppercased()
        if let average = averages[country] { return .rated(average) }
        return checked.contains(country) ? .unrated : .unknown
    }

    /// The rating in the country whose flag stands for `locale`: Germany
    /// for de-DE, Japan for ja.
    func status(for locale: StoreLocale) -> Status {
        status(inCountry: locale.regionCode)
    }

    mutating func record(_ status: Status, inCountry country: String) {
        let country = country.uppercased()
        switch status {
        case let .rated(average):
            averages[country] = average
            checked.insert(country)
        case .unrated:
            averages[country] = nil
            checked.insert(country)
        case .unknown:
            break
        }
    }

    /// These ratings with `other`'s answers on top.
    func merging(_ other: StoreRatings) -> StoreRatings {
        var merged = self
        for country in other.checked {
            merged.record(other.status(inCountry: country), inCountry: country)
        }
        return merged
    }
}
