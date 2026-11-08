//
//  GuidedMakeSummary.swift
//  AppLocalizer
//

import Foundation

/// What a plan makes, in the person's words: "You’ll get 180 screenshots,
/// an App Preview in English (U.S.) and moving header and search artwork,
/// in 18 languages." The guided sheet's first step, its subtitle and the
/// plan's time.
enum GuidedMakeSummary {
    /// The sentence under What to make; asks for one thing when there's
    /// nothing.
    static func sentence(_ plan: AutopilotPlan) -> String {
        guard let made = made(plan) else { return String(localized: "Pick at least one thing to make.") }
        return String(localized: "You’ll get \(made).")
    }

    /// "180 screenshots, an App Preview in English (U.S.) and moving header
    /// and search artwork, in 18 languages"; nil when the plan makes
    /// nothing.
    static func made(_ plan: AutopilotPlan) -> String? {
        var parts: [String] = []
        if plan.makesScreenshots {
            parts.append(screenshots(plan.screensPerLanguage * plan.localeCodes.count))
        }
        if !plan.previewDisplays.isEmpty {
            // With one language, the sentence ends in it already: "an App
            // Preview in Portuguese (Brazil), …, in Portuguese (Brazil)".
            if plan.localeCodes.count == 1 {
                parts.append(String(localized: "an App Preview"))
            } else {
                parts.append(plan.alsoMakes.previewLanguages == .all
                    ? String(localized: "an App Preview in every language")
                    : String(localized: "an App Preview in \(primaryName(plan))"))
            }
        }
        if !plan.artworkKinds.isEmpty {
            parts.append(plan.artworkMadeTitle)
        }
        guard !parts.isEmpty else { return nil }
        let count = plan.localeCodes.count
        let languages = count == 1 ? String(localized: "in \(primaryName(plan))") : String(localized: "in \(count) languages")
        // "180 screenshots in 18 languages"; a list takes a comma before it.
        return parts.formatted(.list(type: .and)) + (parts.count == 1 ? " " : ", ") + languages
    }

    /// What Push to App Store… sends: "180 screenshots, 1 App Preview and
    /// moving header and search artwork in 18 languages"; nil when the
    /// plan makes nothing.
    static func pushed(_ plan: AutopilotPlan) -> String? {
        var parts: [String] = []
        let languages = plan.localeCodes.count
        if plan.makesScreenshots {
            parts.append(screenshots(plan.screensPerLanguage * languages))
        }
        if !plan.previewDisplays.isEmpty {
            let count = plan.previewDisplays.count * plan.previewLocales.count
            parts.append(count == 1 ? String(localized: "1 App Preview") : String(localized: "\(count) App Previews"))
        }
        if !plan.artworkKinds.isEmpty {
            parts.append(languages == 1
                ? String(localized: "\(plan.artworkMadeTitle) in \(primaryName(plan))")
                : String(localized: "\(plan.artworkMadeTitle) in \(languages) languages"))
        }
        return parts.isEmpty ? nil : parts.formatted(.list(type: .and))
    }

    /// About how long the whole run takes, in minutes: capturing and
    /// recording, the design, then localizing and checking.
    static func minutes(_ plan: AutopilotPlan, design: DesignProjectKind, kept: Int = 0) -> Int {
        // Nothing to capture (the last run's captures reused) takes no time.
        var minutes = plan.makesScreenshots || !plan.artworkTargets.isEmpty ? AutopilotEstimate.captureMinutes(for: plan, kept: kept) : 0
        minutes += AutopilotEstimate.recordingMinutes(for: plan)
        minutes += AutopilotEstimate.designMinutes(for: design) + AutopilotEstimate.extrasDesignMinutes(for: plan)
        minutes += localizeMinutes(plan)
        return max(1, minutes)
    }

    /// Localizing and checking: the languages checked, then the header and
    /// search artwork and App Previews made.
    static func localizeMinutes(_ plan: AutopilotPlan) -> Int {
        checkMinutes(plan) + AutopilotEstimate.extrasMakingMinutes(for: plan)
    }

    /// Checking every language: about a minute for every four, two at
    /// least.
    static func checkMinutes(_ plan: AutopilotPlan) -> Int {
        max(2, Int((Double(plan.localeCodes.count) / 4).rounded()))
    }

    /// "180 screenshots", "1 screenshot"; just "screenshots" while the
    /// assistant hasn't picked the screens yet, never "0 screenshots".
    static func screenshots(_ count: Int) -> String {
        switch count {
        case 0: String(localized: "screenshots")
        case 1: String(localized: "1 screenshot")
        default: String(localized: "\(count) screenshots")
        }
    }

    static func primaryName(_ plan: AutopilotPlan) -> String {
        StoreLocaleCatalog.locale(code: plan.primaryLocale)?.name ?? plan.primaryLocale
    }
}
