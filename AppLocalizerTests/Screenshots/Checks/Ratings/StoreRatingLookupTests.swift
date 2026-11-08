//
//  StoreRatingLookupTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Reading the App Store's rating per country from the iTunes Lookup API:
/// a rated app, one with no ratings or not sold there, and an answer that
/// can't be read.
@Suite("StoreRatingLookup")
struct StoreRatingLookupTests {
    private static func answer(_ results: String) -> Data {
        Data(#"{"resultCount": 1, "results": [\#(results)]}"#.utf8)
    }

    @Test func theURLAsksForTheAppInTheCountry() throws {
        let url = try #require(StoreRatingLookup.url(appID: "6450000001", country: "DE"))
        #expect(url.absoluteString == "https://itunes.apple.com/lookup?id=6450000001&country=de")
    }

    @Test func theAnswerGivesTheAverageOrNone() {
        #expect(StoreRatingLookup.status(in: Self.answer(#"{"averageUserRating": 4.72, "userRatingCount": 310}"#)) == .rated(4.72))
        #expect(StoreRatingLookup.status(in: Self.answer(#"{"averageUserRating": 0, "userRatingCount": 0}"#)) == .unrated)
        #expect(StoreRatingLookup.status(in: Self.answer(#"{"trackName": "Lumen"}"#)) == .unrated)
        #expect(StoreRatingLookup.status(in: Data(#"{"resultCount": 0, "results": []}"#.utf8)) == .unrated, "Not sold there")
        #expect(StoreRatingLookup.status(in: Data("<html>".utf8)) == .unknown)
    }

    @Test func everyCountryIsLookedUp() async {
        let lookup = StoreRatingLookup(fetch: { url in
            let country = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "country" }?.value
            switch country {
            case "us": return Self.answer(#"{"averageUserRating": 4.8, "userRatingCount": 1200}"#)
            case "de": return Data(#"{"resultCount": 0, "results": []}"#.utf8)
            default: throw URLError(.notConnectedToInternet)
            }
        }, cache: nil)
        let ratings = await lookup.ratings(appID: "6450000001", countries: ["US", "DE", "JP"])
        #expect(ratings.status(inCountry: "US") == .rated(4.8))
        #expect(ratings.count(inCountry: "US") == 1200)
        #expect(ratings.status(inCountry: "de") == .unrated)
        #expect(ratings.status(inCountry: "JP") == .unknown, "A failed lookup stays unknown")
        #expect(ratings.status(for: .japanese) == .unknown)
        #expect(ratings.status(for: .german) == .unrated)
    }

    @Test func newerAnswersReplaceOlderOnes() {
        var old = StoreRatings.unchecked
        old.record(.rated(4.5), inCountry: "US")
        old.record(.rated(4.1), inCountry: "FR")
        var new = StoreRatings.unchecked
        new.record(.unrated, inCountry: "US")
        new.record(.unknown, inCountry: "FR")
        let merged = old.merging(new)
        #expect(merged.status(inCountry: "US") == .unrated)
        #expect(merged.status(inCountry: "FR") == .rated(4.1), "An unknown answer keeps what was known")
    }

    // MARK: - Once a day

    /// Counts the requests per country.
    private final class Asked: @unchecked Sendable {
        private let lock = NSLock()
        private var countries: [String] = []
        func add(_ country: String) { lock.withLock { countries.append(country) } }
        var all: [String] { lock.withLock { countries } }
    }

    @Test func eachStorefrontIsAskedOnceADay() async {
        let asked = Asked()
        let cache = StoreRatingCache(directory: nil)
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        func lookup(at date: Date) -> StoreRatingLookup {
            StoreRatingLookup(fetch: { url in
                let country = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "country" }?.value ?? ""
                asked.add(country)
                let korea = #"{"averageUserRating": 0, "userRatingCount": 0}"#
                return Self.answer(country == "kr" ? korea : #"{"averageUserRating": 4.7, "userRatingCount": 64}"#)
            }, cache: cache, now: { date })
        }
        let first = await lookup(at: start).ratings(appID: "1", countries: ["DE", "KR"])
        #expect(first.status(inCountry: "DE") == .rated(4.7))
        #expect(first.count(inCountry: "DE") == 64)
        #expect(first.status(inCountry: "KR") == .unrated)
        let later = await lookup(at: start.addingTimeInterval(6 * 3600)).ratings(appID: "1", countries: ["DE", "KR"])
        #expect(later == first, "Kept answers, counts included")
        #expect(asked.all.count == 2, "Six hours later nothing is asked again")
        _ = await lookup(at: start.addingTimeInterval(25 * 3600)).ratings(appID: "1", countries: ["DE"])
        #expect(asked.all.count == 3, "A day later Germany is asked again")
    }

    @Test func unreadableAnswersAreNotKept() async {
        let cache = StoreRatingCache(directory: nil)
        let failing = StoreRatingLookup(fetch: { _ in throw URLError(.notConnectedToInternet) }, cache: cache)
        _ = await failing.ratings(appID: "1", countries: ["US"])
        #expect(await cache.answer(appID: "1", country: "US", at: Date()) == nil)
    }
}
