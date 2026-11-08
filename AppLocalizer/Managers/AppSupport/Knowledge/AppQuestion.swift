//
//  AppQuestion.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer wants to know about an app that its App Store page
/// doesn't say, and only someone who read the project can tell: asked of
/// the connected assistant (`answer_app_questions`), remembered per app,
/// and asked again once the answer is old.
enum AppQuestion: String, Codable, CaseIterable, Hashable, Sendable {
    case previewStory
    case movingMoments
    case soundMood
    case difference
    case voice
    case offLimits

    /// The question, for the assistant.
    var ask: String {
        switch self {
        case .previewStory:
            "What story should a 20-second video of this app tell? Give the 3 to 5 things a person does, in order, each with what visibly happens on screen."
        case .movingMoments:
            "What moves in this app? List its animations, live updates, gestures and transitions, and the screen each is on."
        case .soundMood:
            "How should this app sound in a video? Say the mood, the pace, the instruments that fit and what would feel wrong, from who uses it and when."
        case .difference:
            "What does this app do that others in its category don't? Say it in the app's own terms."
        case .voice:
            "How does the app talk to its people? Describe its tone from its own copy, with a phrase it really uses."
        case .offLimits:
            "What must the store page and video never show or claim: sensitive content, unfinished features, legal or platform limits?"
        }
    }

    /// What the answer is for, so the assistant answers to the point.
    var why: String {
        switch self {
        case .previewStory: "AppLocalizer records the App Preview along this story."
        case .movingMoments: "Each moment of the App Preview has to show something moving; these are the ones to film."
        case .soundMood: "It chooses the App Preview's music."
        case .difference: "Screenshots, headers and store texts lead with it."
        case .voice: "Captions and store texts are written in it."
        case .offLimits: "Designs, captions and recordings keep clear of it."
        }
    }
}
