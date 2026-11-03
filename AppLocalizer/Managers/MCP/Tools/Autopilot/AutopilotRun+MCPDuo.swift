//
//  AutopilotRun+MCPDuo.swift
//  AppLocalizer
//

import Foundation

/// iPhone Duo's inner and cover displays, for `get_capture_plan` and
/// `next_step`.
extension AutopilotRun {
    /// The iPhone Duo device's `poses`: which slots (1-based) are captured
    /// open (the inner display) and which closed (the cover display).
    var mcpDuoPoses: JSONValue {
        [
            "shows": .string(plan.duoScreens.rawValue),
            "both": plan.duoScreens == .both ? .string(plan.duoBoth.rawValue) : .null,
            "open": .array(plan.duoSlots(.open).map { .int($0 + 1) }),
            "closed": .array(plan.duoSlots(.closed).map { .int($0 + 1) }),
            "rule": .string(Self.duoRule(plan)),
        ]
    }

    /// What the person chose for iPhone Duo, for the assistant.
    static func duoRule(_ plan: AutopilotPlan) -> String {
        let steps = "The steps are the same screens as iPhone."
        switch (plan.duoScreens, plan.duoBoth) {
        case (.inner, _):
            return "iPhone Duo's screenshots show the inner display, unfolded: AppLocalizer opens the Duo in Device Hub. \(steps)"
        case (.cover, _):
            return "iPhone Duo's screenshots show the cover display: keep the Duo folded. \(steps)"
        case (.both, .sideBySide):
            return """
            Each iPhone Duo screen is captured twice, folded (pose closed, the cover display) and unfolded (pose open, \
            the inner display); AppLocalizer puts both in one image. Capture the closed ones first: the Duo starts \
            folded. \(steps)
            """
        case (.both, .separate):
            return """
            iPhone Duo's set has an inner screenshot of each screen, then a cover one for the first \
            \(plan.duoSeparateCovers) (Apple takes 10). Each target says its pose; capture the closed ones first: \
            the Duo starts folded. \(steps)
            """
        }
    }
}
