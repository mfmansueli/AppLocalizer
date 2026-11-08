//
//  AppKnowledge+MCP.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer knows of the app, and what it still wants to know, as
/// the MCP tools hand them over.
extension AppKnowledge {
    /// `appKnowledge`: every answer by question, and the music picked.
    var mcpJSON: JSONValue {
        var json: [String: JSONValue] = [:]
        for question in AppQuestion.allCases {
            if let text = answer(to: question) { json[question.rawValue] = .string(text) }
        }
        if let music {
            json["music"] = ["track": .string(music.track.rawValue), "reason": .string(music.reason)]
        }
        return .object(json)
    }

    /// `[{id, ask, why}]`.
    static func questionsJSON(_ questions: [AppQuestion]) -> JSONValue {
        .array(questions.map { ["id": .string($0.rawValue), "ask": .string($0.ask), "why": .string($0.why)] })
    }

    /// The tracks to pick from: id, title and sound.
    static var musicLibraryJSON: JSONValue {
        .array(AppPreviewTrack.library.map { ["track": .string($0.rawValue), "title": .string($0.title), "sound": .string($0.mood)] })
    }

    /// `next_step` before the run's first capture or recording.
    static func askStepJSON(_ questions: [AppQuestion], asksMusic: Bool) -> JSONValue {
        var json: [String: JSONValue] = [
            "action": "answer_app_questions",
            "questions": questionsJSON(questions),
            "how": .string(how),
        ]
        if asksMusic { json["musicLibrary"] = musicLibraryJSON }
        return .object(json)
    }

    private static let how = """
    AppLocalizer wants to know these about the app, and remembers the answers for every run. Answer from the project: \
    its docs, views, navigation, onboarding copy and UI tests. Be concrete and use the app's own words. Call \
    answer_app_questions once with every answer, leaving out the answer text for what the project doesn't say; when \
    musicLibrary is here, also pick the track that fits soundMood, with music_track and a one-sentence music_reason. \
    Then call next_step.
    """
}
