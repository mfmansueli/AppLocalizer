//
//  AppKnowledge.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer has learned about an app from its assistant, beyond
/// the look: the answers to its `AppQuestion`s and the music picked. Every
/// run's recording, design and store texts start from it.
struct AppKnowledge: Codable, Hashable, Sendable {
    /// By `AppQuestion` raw value, so an answer to a question a later
    /// version drops still loads.
    var answers: [String: AppAnswer] = [:]
    var music: AppMusicPick?

    /// An answer this old is asked for again: apps change.
    static let oldAfter: TimeInterval = 120 * 24 * 60 * 60

    var isEmpty: Bool { answers.isEmpty && music == nil }

    func answer(to question: AppQuestion) -> String? {
        answers[question.rawValue]?.text
    }

    mutating func set(_ question: AppQuestion, text: String?, by client: String?, at date: Date) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        answers[question.rawValue] = AppAnswer(text: trimmed?.isEmpty == false ? trimmed : nil, answeredAt: date, answeredBy: client)
    }

    /// What's worth asking: never answered, or answered long ago.
    func due(now: Date) -> [AppQuestion] {
        AppQuestion.allCases.filter { question in
            guard let answer = answers[question.rawValue] else { return true }
            return now.timeIntervalSince(answer.answeredAt) > Self.oldAfter
        }
    }

    /// `newer`'s answers over these; what it doesn't answer stays.
    func merging(_ newer: AppKnowledge) -> AppKnowledge {
        var merged = self
        merged.answers.merge(newer.answers) { $1 }
        if let music = newer.music { merged.music = music }
        return merged
    }
}
