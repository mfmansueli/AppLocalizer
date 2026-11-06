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

    /// The screens an assistant usually picks for a device when the plan
    /// leaves it to them.
    static let typicalScreens = 6

    /// Reading the project, writing each screen's steps as a UI test and
    /// building it, before the first capture of a run whose screens the
    /// assistant picks: MB Admin's first capture came 18 minutes in.
    static let choosingScreensMinutes = 15

    /// The captures a plan expects: its own, or, while the assistant still
    /// picks the screens, a typical set on each device in each language
    /// captured. MB Admin's first run (no screens yet) said "about 2 min"
    /// and "Records the App Preview", as if it captured nothing.
    static func expectedCaptures(for plan: AutopilotPlan) -> Int {
        guard plan.awaitsScreens else { return plan.targets.count }
        return typicalScreens * plan.displayTypes.count * plan.capturedLocales.count
    }

    /// Capturing what `plan` expects, `kept` reused: with the time to pick
    /// the screens when the assistant still has to.
    static func captureMinutes(for plan: AutopilotPlan, kept: Int = 0) -> Int {
        let toCapture = max(0, expectedCaptures(for: plan) - kept)
        guard toCapture > 0 else { return 0 }
        return captureMinutes(for: toCapture) + (plan.awaitsScreens ? choosingScreensMinutes : 0)
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
        let total = expectedCaptures(for: plan)
        let languages = plan.capturedLocales.count
        let captures = if plan.awaitsScreens {
            String(localized: "About \(total) captures")
        } else {
            total == 1 ? String(localized: "1 capture") : String(localized: "\(total) captures")
        }
        let place = languages == 1 ? String(localized: "in 1 language") : String(localized: "in \(languages) languages")
        let extras = plan.extrasTitle.map { ", " + String(localized: "plus \($0)") } ?? ""
        let onMac = max(1, captureMinutes(for: plan, kept: kept)) + recordingMinutes(for: plan)
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
