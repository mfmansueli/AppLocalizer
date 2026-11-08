//
//  GuidedDefaults.swift
//  AppLocalizer
//

import Foundation

/// What a guided plan starts with and keeps: two stops (choose the look,
/// then review), the captures picked by the assistant, and the last run's
/// captures reused when only artwork is made.
enum GuidedDefaults {
    /// A new guided plan: Choose and Watch stop (Watch is part of the
    /// review), Pick doesn't.
    static func apply(to plan: inout AutopilotPlan) {
        plan.stopsToPick = false
        plan.stopsToChoose = true
        plan.stopsToWatchPreview = true
        plan.assistantDesignsArtwork = true
        plan.assistantDesignsLooks = true
    }

    /// Captures: reused when the run makes only artwork and there are
    /// captures to reuse; otherwise captured again.
    static func applyCaptureChoice(to plan: inout AutopilotPlan, canReuse: Bool) {
        let onlyArtwork = !plan.makesScreenshots && plan.previewDisplays.isEmpty && !plan.artworkKinds.isEmpty
        plan.runChoice.reusesCaptures = canReuse && onlyArtwork
    }

    /// What to make's three cards: screenshots, the App Preview and the
    /// header and search, on or off. An App Preview without screenshots
    /// is made for the iPhone and iPad the app runs on.
    static func setMakes(_ part: GuidedReviewPart, _ isOn: Bool, in plan: inout AutopilotPlan, devices: [ScreenshotDisplayType], canReuse: Bool) {
        switch part {
        case .screenshots:
            plan.runChoice.makesScreenshots = isOn
        case .artwork:
            plan.alsoMakes.makesArtwork = isOn
        case .appPreview:
            plan.alsoMakes.makesAppPreview = isOn
        }
        if plan.alsoMakes.makesAppPreview, plan.previewDisplays.isEmpty {
            plan.runChoice.previewDisplays = AutopilotExtras.previewDisplays.filter(devices.contains)
        }
        // Following the screenshots' devices again once they're made.
        if plan.makesScreenshots, part == .screenshots { plan.runChoice.previewDisplays = nil }
        applyCaptureChoice(to: &plan, canReuse: canReuse)
    }

    /// Whether `plan` makes `part`.
    static func makes(_ part: GuidedReviewPart, _ plan: AutopilotPlan) -> Bool {
        switch part {
        case .screenshots: plan.makesScreenshots
        case .artwork: plan.alsoMakes.makesArtwork
        case .appPreview: plan.alsoMakes.makesAppPreview
        }
    }
}
