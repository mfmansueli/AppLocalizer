//
//  AutopilotStripAction.swift
//  AppLocalizer
//

import Foundation

/// A button on the Autopilot strip.
enum AutopilotStripAction: Hashable, Sendable {
    case runAutopilot
    case open
    case setUpAssistant
    case importCaptures
    case reviewPush

    var title: String {
        switch self {
        case .runAutopilot: String(localized: "Run Autopilot…")
        case .open: String(localized: "Open")
        case .setUpAssistant: String(localized: "Set Up Assistant…")
        case .importCaptures: String(localized: "Import Captures…")
        case .reviewPush: String(localized: "Review & Push…")
        }
    }

    /// "Open Autopilot" when it sits next to Review & Push.
    var secondaryTitle: String {
        self == .open ? String(localized: "Open Autopilot") : title
    }

    var identifier: String {
        switch self {
        case .runAutopilot: "studio.autopilot.run"
        case .open: "studio.autopilot.open"
        case .setUpAssistant: "studio.autopilot.setUp"
        case .importCaptures: "studio.autopilot.import"
        case .reviewPush: "studio.autopilot.reviewPush"
        }
    }
}
