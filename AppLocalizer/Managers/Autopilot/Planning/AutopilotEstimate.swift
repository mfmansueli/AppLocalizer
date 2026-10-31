//
//  AutopilotEstimate.swift
//  AppLocalizer
//

import Foundation

/// How long a plan takes: about 7.5 seconds a capture on this Mac, then a
/// few minutes of design.
enum AutopilotEstimate {
    static let secondsPerCapture = 7.5

    static func captureMinutes(for captures: Int) -> Int {
        max(1, Int((Double(captures) * secondsPerCapture / 60).rounded()))
    }

    static func designMinutes(for kind: DesignProjectKind) -> Int {
        kind.usesDesignAI ? 3 : 1
    }

    /// "120 captures in 12 languages · about 15 min on this Mac, then about
    /// 3 min of design".
    static func summary(for plan: AutopilotPlan, design kind: DesignProjectKind, kept: Int = 0) -> String {
        let total = plan.targets.count
        let toCapture = max(0, total - kept)
        let languages = plan.capturedLocales.count
        let captures = total == 1 ? String(localized: "1 capture") : String(localized: "\(total) captures")
        let place = languages == 1 ? String(localized: "in 1 language") : String(localized: "in \(languages) languages")
        var text = "\(captures) \(place) · " + String(localized: "about \(captureMinutes(for: toCapture)) min on this Mac, then about \(designMinutes(for: kind)) min of design")
        if kept > 0 { text += " · " + String(localized: "\(kept) kept from the last run") }
        return text
    }
}
