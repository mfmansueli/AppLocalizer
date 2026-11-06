//
//  GuidedPickToggle.swift
//  AppLocalizer
//

import Foundation

/// The Look step's pick button under a previewed template or scene: add
/// it, take it out, or, with three picked, put it in the last one's place
/// (as picking a fourth does).
enum GuidedPickToggle {
    /// "Add to My Picks", "✓ Pick 2 · Remove", "Replace Pick 3 With This".
    /// `number` is the previewed one's pick (1-based), nil when it isn't
    /// picked.
    static func title(number: Int?, picked: Int, maximum: Int = AutopilotShotStyle.maximumTemplates) -> String {
        if let number { return String(localized: "✓ Pick \(number) · Remove") }
        if picked >= maximum { return String(localized: "Replace Pick \(maximum) With This") }
        return String(localized: "Add to My Picks")
    }

    /// Adding is the prominent action; Remove isn't.
    static func isProminent(number: Int?) -> Bool { number == nil }
}
