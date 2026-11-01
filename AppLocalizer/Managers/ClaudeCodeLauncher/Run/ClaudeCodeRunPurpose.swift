//
//  ClaudeCodeRunPurpose.swift
//  AppLocalizer
//

import Foundation

/// What a run started from AppLocalizer is for: it names the run, picks
/// its permissions, and lets each screen find its own run.
enum ClaudeCodeRunPurpose: Hashable, Sendable {
    /// Setup's test, "List my apps in AppLocalizer".
    case test
    /// Ask on a suggestion bar, e.g. "Store Page".
    case ask(area: String)
    case suggestEverything
    case autopilot
    /// Translate Missing on Store Page.
    case translation
    /// Translate captions in Screenshots.
    case captions
    case privacyScan

    /// "Suggest Everything", "Ask · Store Page".
    var title: String {
        switch self {
        case .test: String(localized: "Setup test")
        case let .ask(area): String(localized: "Ask · \(area)")
        case .suggestEverything: String(localized: "Suggest Everything")
        case .autopilot: String(localized: "Screenshot Autopilot")
        case .translation: String(localized: "Translate missing languages")
        case .captions: String(localized: "Translate captions")
        case .privacyScan: String(localized: "App Privacy scan")
        }
    }

    var permissions: ClaudeCodePermissions {
        switch self {
        case .test: .appLocalizerOnly
        case .autopilot: .autopilot
        case .ask, .suggestEverything, .translation, .captions, .privacyScan: .readProject
        }
    }
}
