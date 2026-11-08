//
//  StoreRatingCache.swift
//  AppLocalizer
//

import Foundation

/// The App Store's rating answers per app and storefront, kept on this Mac
/// for a day: a laurel's default value refreshes daily, not on every
/// render.
actor StoreRatingCache {
    static let shared = StoreRatingCache(directory: URL.cachesDirectory.appending(path: "AppLocalizer/StoreRatings", directoryHint: .isDirectory))

    /// How long an answer is kept.
    static let lifetime: TimeInterval = 24 * 60 * 60

    /// One storefront's answer and when it came.
    struct Answer: Codable, Hashable, Sendable {
        var average: Double?
        var count: Int?
        var date: Date

        init(status: StoreRatings.Status, count: Int?, date: Date) {
            if case let .rated(value) = status { average = value }
            self.count = count
            self.date = date
        }

        var status: StoreRatings.Status {
            average.map { .rated($0) } ?? .unrated
        }
    }

    /// Where each app's answers are saved; nil keeps them in memory only.
    private let directory: URL?
    private var answers: [String: [String: Answer]] = [:]

    init(directory: URL?) {
        self.directory = directory
    }

    /// The answer for `country` if it's under a day old at `date`.
    func answer(appID: String, country: String, at date: Date) -> Answer? {
        guard let answer = loaded(appID)[country.uppercased()], date.timeIntervalSince(answer.date) < Self.lifetime,
              answer.date <= date else { return nil }
        return answer
    }

    func keep(_ answer: Answer, appID: String, country: String) {
        var kept = loaded(appID)
        kept[country.uppercased()] = answer
        answers[appID] = kept
        guard let file = file(for: appID), let data = try? JSONEncoder().encode(kept) else { return }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
    }

    private func loaded(_ appID: String) -> [String: Answer] {
        if let kept = answers[appID] { return kept }
        let kept = file(for: appID).flatMap { try? Data(contentsOf: $0) }.flatMap { try? JSONDecoder().decode([String: Answer].self, from: $0) } ?? [:]
        answers[appID] = kept
        return kept
    }

    private func file(for appID: String) -> URL? {
        directory?.appending(path: "\(appID).json")
    }
}
