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

    /// The App Preview's recordings: about 2 minutes in one language, about
    /// 0.8 of a minute a language in every language.
    static func recordingMinutes(for plan: AutopilotPlan) -> Int {
        guard !plan.previewDisplays.isEmpty else { return 0 }
        return max(2, Int((Double(plan.recordedLocales.count) * 0.8).rounded()))
    }

    /// A minute for the artwork, two for the App Preview's captions, end
    /// card and poster.
    static func extrasDesignMinutes(for plan: AutopilotPlan) -> Int {
        (plan.alsoMakes.makesArtwork ? 1 : 0) + (plan.alsoMakes.makesAppPreview ? 2 : 0)
    }

    /// "120 captures in 12 languages · about 15 min on this Mac, then about
    /// 3 min of design"; with extras, "…in 12 languages, plus header and
    /// search artwork and an App Preview in every language · …".
    static func summary(for plan: AutopilotPlan, design kind: DesignProjectKind, kept: Int = 0) -> String {
        guard plan.makesScreenshots else { return withoutScreenshots(plan, design: kind, kept: kept) }
        let total = plan.targets.count
        let toCapture = max(0, total - kept)
        let languages = plan.capturedLocales.count
        let captures = total == 1 ? String(localized: "1 capture") : String(localized: "\(total) captures")
        let place = languages == 1 ? String(localized: "in 1 language") : String(localized: "in \(languages) languages")
        let extras = plan.extrasTitle.map { ", " + String(localized: "plus \($0)") } ?? ""
        let onMac = captureMinutes(for: toCapture) + recordingMinutes(for: plan)
        let design = designMinutes(for: kind) + extrasDesignMinutes(for: plan)
        var text = "\(captures) \(place)\(extras) · " + String(localized: "about \(onMac) min on this Mac, then about \(design) min of design")
        if kept > 0 { text += " · " + String(localized: "\(kept) kept from the last run") }
        return text
    }

    /// "Header and search artwork in 12 languages · nothing to capture on
    /// this Mac; about 1 min of design"; "An App Preview in every language ·
    /// about 4 min on this Mac, then about 3 min of design".
    private static func withoutScreenshots(_ plan: AutopilotPlan, design kind: DesignProjectKind, kept: Int) -> String {
        let what = plan.extrasTitle ?? ""
        let languages = plan.localeCodes.count
        let place = languages == 1 ? String(localized: "in 1 language") : String(localized: "in \(languages) languages")
        let toCapture = max(0, plan.targets.count - kept)
        let onMac = (toCapture > 0 ? captureMinutes(for: toCapture) : 0) + recordingMinutes(for: plan)
        let design = designMinutes(for: kind) + extrasDesignMinutes(for: plan)
        // An App Preview alone already says its languages.
        let head = what.prefix(1).uppercased() + what.dropFirst() + (plan.alsoMakes.makesArtwork ? " " + place : "")
        guard onMac > 0 else { return head + " · " + String(localized: "nothing to capture on this Mac; about \(design) min of design") }
        return head + " · " + String(localized: "about \(onMac) min on this Mac, then about \(design) min of design")
    }
}
