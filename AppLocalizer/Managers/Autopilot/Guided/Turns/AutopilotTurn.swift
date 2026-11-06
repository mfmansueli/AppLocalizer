//
//  AutopilotTurn.swift
//  AppLocalizer
//

import Foundation

/// A stop where the run waits for the person, as a notification says it:
/// "Autopilot needs you: choose the look", with the app and when the run
/// started. Only stages the run reached by itself count: a stage the
/// person moved it to (Approve, Use These) isn't news.
enum AutopilotTurn: Hashable, Sendable {
    case pick
    case choose
    case review

    /// The turn a stage change brings, or nil.
    static func turn(from old: AutopilotStage?, to new: AutopilotStage) -> AutopilotTurn? {
        guard old != new, let old else { return nil }
        switch new {
        case .pick: return .pick
        case .choose: return .choose
        // Watch the App Preview is part of the review.
        case .watchPreview: return .review
        // Ready after Watch is the person's approval.
        case .ready: return old == .watchPreview ? nil : .review
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .pick: String(localized: "Autopilot needs you: pick the captures")
        case .choose: String(localized: "Autopilot needs you: choose the look")
        case .review: String(localized: "Autopilot needs you: review everything, then push")
        }
    }

    /// "Lumen Journal · the run started at 2:02 PM".
    func body(appName: String, startedAt: Date?) -> String {
        guard let startedAt else { return appName }
        let time = startedAt.formatted(date: Calendar.current.isDateInToday(startedAt) ? .omitted : .abbreviated, time: .shortened)
        return String(localized: "\(appName) · the run started at \(time)")
    }
}
