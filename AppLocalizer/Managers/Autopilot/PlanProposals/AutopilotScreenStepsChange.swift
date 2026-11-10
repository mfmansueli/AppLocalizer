//
//  AutopilotScreenStepsChange.swift
//  AppLocalizer
//

import Foundation

/// New steps for a screen the plan already has, sent outside a run's
/// capture: Alba's Streak and Animated scenes, reached another way in 1.1.
struct AutopilotScreenStepsChange: Codable, Hashable, Sendable {
    /// The screen's ID when it was sent, e.g. `streak`.
    var screenID: String
    /// "Streak": found by name when the ID is gone from the next plan.
    var name: String
    /// Apple Watch or Apple Vision Pro, for their own screens; nil for the
    /// set's, on iPhone and iPad.
    var displayType: ScreenshotDisplayType?
    /// "tab “Streak” → wait for the flame".
    var steps: String

    /// The device whose screens it changes: iPhone stands for the set.
    var device: ScreenshotDisplayType { displayType ?? .iPhone }

    /// The screen it changes in `plan`, by ID, then by name, on its device.
    func screen(in plan: AutopilotPlan) -> AutopilotScreen? {
        let screens = plan.screens(on: device)
        return screens.first { $0.id == screenID } ?? screens.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}
