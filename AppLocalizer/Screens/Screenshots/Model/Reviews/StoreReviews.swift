//
//  StoreReviews.swift
//  AppLocalizer
//

import Foundation

/// The app's 5-star App Store reviews per country that a Reviews slot
/// (`slots[i].layout: quotes`) shows: three from the language's own
/// storefront, filled from the primary language's when it has fewer.
struct StoreReviews: Hashable, Sendable {
    /// How many reviews a Reviews slot shows.
    static let perSlot = 3

    /// Reviews by country (ISO 3166, uppercase), the best first.
    private(set) var byCountry: [String: [StoreQuote]] = [:]
    /// The countries the App Store answered for.
    private(set) var checked: Set<String> = []
    /// The primary language's country, whose reviews fill in.
    var primaryCountry: String?

    /// Nothing looked up yet.
    static let none = StoreReviews()

    mutating func record(_ quotes: [StoreQuote], inCountry country: String) {
        let country = country.uppercased()
        byCountry[country] = quotes
        checked.insert(country)
    }

    /// The three a Reviews slot shows for `locale`: its country's own, then
    /// the primary country's, marked borrowed. Fewer when there aren't
    /// three in all.
    func quotes(for locale: StoreLocale) -> [StoreQuote] {
        let country = locale.regionCode.uppercased()
        var quotes = Array((byCountry[country] ?? []).prefix(Self.perSlot))
        guard quotes.count < Self.perSlot, let primary = primaryCountry?.uppercased(), primary != country else { return quotes }
        let borrowed = (byCountry[primary] ?? []).filter { candidate in !quotes.contains { $0.text == candidate.text } }
        for var quote in borrowed.prefix(Self.perSlot - quotes.count) {
            quote.isBorrowed = true
            quotes.append(quote)
        }
        return quotes
    }

    /// Whether `locale`'s country was looked up.
    func isChecked(_ locale: StoreLocale) -> Bool {
        checked.contains(locale.regionCode.uppercased())
    }

    /// These reviews with `other`'s answers on top.
    func merging(_ other: StoreReviews) -> StoreReviews {
        var merged = self
        for country in other.checked {
            merged.record(other.byCountry[country] ?? [], inCountry: country)
        }
        merged.primaryCountry = other.primaryCountry ?? primaryCountry
        return merged
    }

    /// The reviews worth quoting from a storefront's 5-star ones: short
    /// enough to read on a screenshot, long enough to say something, each
    /// once, newest first.
    static func pick(_ reviews: [StoreQuote]) -> [StoreQuote] {
        var seen: Set<String> = []
        return reviews.filter { quote in
            let text = quote.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (24...180).contains(text.count), !quote.name.isEmpty, seen.insert(text).inserted else { return false }
            return true
        }
    }
}
