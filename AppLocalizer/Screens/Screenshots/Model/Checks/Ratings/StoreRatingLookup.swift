//
//  StoreRatingLookup.swift
//  AppLocalizer
//

import Foundation

/// Reads an app's average rating per country from the iTunes Lookup API,
/// the numbers the App Store shows on the app's page there.
struct StoreRatingLookup: Sendable {
    /// Fetches a URL's body; URLSession by default, canned data in tests.
    var fetch: @Sendable (URL) async throws -> Data = { url in
        try await URLSession.shared.data(from: url).0
    }

    /// Looks every country up at once. A country that can't be read stays
    /// unknown.
    func ratings(appID: String, countries: Set<String>) async -> StoreRatings {
        await withTaskGroup(of: (String, StoreRatings.Status).self) { group in
            for country in countries {
                group.addTask {
                    guard let url = Self.url(appID: appID, country: country), let data = try? await fetch(url) else {
                        return (country, .unknown)
                    }
                    return (country, Self.status(in: data))
                }
            }
            var ratings = StoreRatings.unchecked
            for await (country, status) in group {
                ratings.record(status, inCountry: country)
            }
            return ratings
        }
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
        guard let answer = try? JSONDecoder().decode(Answer.self, from: data) else { return .unknown }
        guard let app = answer.results.first, let average = app.averageUserRating, (app.userRatingCount ?? 1) > 0 else {
            return .unrated
        }
        return .rated(average)
    }

    private struct Answer: Decodable {
        var results: [AnswerApp]
    }

    private struct AnswerApp: Decodable {
        var averageUserRating: Double?
        var userRatingCount: Int?
    }
}
