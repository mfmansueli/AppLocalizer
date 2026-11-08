//
//  StoreRatingLookup.swift
//  AppLocalizer
//

import Foundation

/// Reads an app's average rating and its count per country from the
/// iTunes Lookup API, the numbers the App Store shows on the app's page
/// there. Answers are kept a day per storefront (`cache`), so each country
/// is asked at most once a day.
struct StoreRatingLookup: Sendable {
    /// Fetches a URL's body; URLSession by default, canned data in tests.
    var fetch: @Sendable (URL) async throws -> Data = { url in
        try await URLSession.shared.data(from: url).0
    }

    /// The answers kept from earlier lookups; nil asks every time.
    var cache: StoreRatingCache? = .shared
    var now: @Sendable () -> Date = { Date() }

    /// Looks every country up at once, or takes today's answer. A country
    /// that can't be read stays unknown.
    func ratings(appID: String, countries: Set<String>) async -> StoreRatings {
        let date = now()
        var ratings = StoreRatings.unchecked
        var asking: Set<String> = []
        for country in countries {
            if let kept = await cache?.answer(appID: appID, country: country, at: date) {
                ratings.record(kept.status, count: kept.count, inCountry: country)
            } else {
                asking.insert(country)
            }
        }
        return await withTaskGroup(of: (String, Reading).self) { group in
            for country in asking {
                group.addTask {
                    guard let url = Self.url(appID: appID, country: country), let data = try? await fetch(url) else {
                        return (country, Reading(status: .unknown, count: nil))
                    }
                    return (country, Self.reading(in: data))
                }
            }
            for await (country, reading) in group {
                ratings.record(reading.status, count: reading.count, inCountry: country)
                if reading.status != .unknown {
                    await cache?.keep(StoreRatingCache.Answer(status: reading.status, count: reading.count, date: date), appID: appID, country: country)
                }
            }
            return ratings
        }
    }

    /// What one answer says: the average (or none yet) and how many
    /// ratings it's from.
    struct Reading: Hashable, Sendable {
        var status: StoreRatings.Status
        var count: Int?
    }

    /// `https://itunes.apple.com/lookup?id=…&country=de`.
    static func url(appID: String, country: String) -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: appID),
            URLQueryItem(name: "country", value: country.lowercased()),
        ]
        return components?.url
    }

    /// The first result's `averageUserRating`. No result (not sold in that
    /// country) or no ratings yet is unrated; anything else unreadable is
    /// unknown.
    static func status(in data: Data) -> StoreRatings.Status {
        reading(in: data).status
    }

    /// The first result's `averageUserRating` and `userRatingCount`.
    static func reading(in data: Data) -> Reading {
        guard let answer = try? JSONDecoder().decode(Answer.self, from: data) else { return Reading(status: .unknown, count: nil) }
        guard let app = answer.results.first, let average = app.averageUserRating, (app.userRatingCount ?? 1) > 0 else {
            return Reading(status: .unrated, count: nil)
        }
        return Reading(status: .rated(average), count: app.userRatingCount)
    }

    private struct Answer: Decodable {
        var results: [AnswerApp]
    }

    private struct AnswerApp: Decodable {
        var averageUserRating: Double?
        var userRatingCount: Int?
    }
}
