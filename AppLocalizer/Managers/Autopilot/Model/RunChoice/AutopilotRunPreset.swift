//
//  AutopilotRunPreset.swift
//  AppLocalizer
//

import Foundation

/// "What this run makes"'s presets. Each sets the rows; any other mix of
/// rows is Custom.
enum AutopilotRunPreset: String, CaseIterable, Hashable, Sendable {
    case everything
    case screenshots
    case headerAndSearch
    case appPreview
    case custom

    var title: String {
        switch self {
        case .everything: String(localized: "Everything")
        case .screenshots: String(localized: "Screenshots")
        case .headerAndSearch: String(localized: "Header and search")
        case .appPreview: String(localized: "App Preview")
        case .custom: String(localized: "Custom")
        }
    }

    /// The preset `plan` matches; Custom when none does.
    static func matching(_ plan: AutopilotPlan, devices: [ScreenshotDisplayType]) -> Self {
        let extras = plan.alsoMakes
        let shots = plan.makesScreenshots
        let previewDevices = Set(plan.previewDisplays)
        let everyPreviewDevice = Set(AutopilotExtras.previewDisplays.filter(devices.contains))
        switch (shots, extras.makesArtwork, extras.makesAppPreview) {
        case (true, true, true) where Set(devices).isSubset(of: Set(plan.displayTypes)) && previewDevices == everyPreviewDevice:
            return .everything
        case (true, false, false): return .screenshots
        case (false, true, false): return .headerAndSearch
        case (false, false, true): return .appPreview
        default: return .custom
        }
    }

    /// Sets `plan`'s rows; `devices` are the ones the app runs on. Custom
    /// changes nothing.
    func apply(to plan: inout AutopilotPlan, devices: [ScreenshotDisplayType], canReuse: Bool) {
        switch self {
        case .everything:
            plan.runChoice.makesScreenshots = true
            for display in devices { plan.setPlans(display, true) }
            plan.runChoice.previewDisplays = nil
            plan.alsoMakes.makesArtwork = true
            plan.alsoMakes.makesAppPreview = true
        case .screenshots:
            plan.runChoice.makesScreenshots = true
            plan.alsoMakes.makesArtwork = false
            plan.alsoMakes.makesAppPreview = false
        case .headerAndSearch:
            plan.runChoice.makesScreenshots = false
            if canReuse { plan.runChoice.reusesCaptures = true }
            plan.alsoMakes.makesArtwork = true
            plan.alsoMakes.makesAppPreview = false
        case .appPreview:
            plan.runChoice.makesScreenshots = false
            plan.alsoMakes.makesArtwork = false
            plan.alsoMakes.makesAppPreview = true
            if plan.previewDisplays.isEmpty { plan.runChoice.previewDisplays = AutopilotExtras.previewDisplays.filter(devices.contains) }
        case .custom:
            break
        }
    }
}
