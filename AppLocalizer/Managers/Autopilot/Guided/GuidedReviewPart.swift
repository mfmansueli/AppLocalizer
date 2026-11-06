//
//  GuidedReviewPart.swift
//  AppLocalizer
//

import Foundation

/// A part of what a run makes, as Review & push shows it: one tab each,
/// approved on its own. Push waits until every part the run makes is.
enum GuidedReviewPart: String, Codable, CaseIterable, Hashable, Sendable {
    case screenshots
    case artwork
    case appPreview

    /// The parts `plan` makes, in tab order.
    static func parts(of plan: AutopilotPlan) -> [GuidedReviewPart] {
        var parts: [GuidedReviewPart] = []
        if plan.makesScreenshots { parts.append(.screenshots) }
        if !plan.artworkKinds.isEmpty { parts.append(.artwork) }
        if !plan.previewDisplays.isEmpty { parts.append(.appPreview) }
        return parts
    }

    /// The parts Watch the App Preview holds: at Watch, the header loop
    /// and the App Preview not approved there yet. Approving all of them
    /// here approves the watch step.
    static func watched(in run: AutopilotRun) -> [GuidedReviewPart] {
        guard run.stage == .watchPreview else { return [] }
        var parts: [GuidedReviewPart] = []
        if run.watchesHeaderLoop(design: run.designKind) { parts.append(.artwork) }
        if run.watchesAppPreview { parts.append(.appPreview) }
        return parts
    }

    /// "Screenshots", "Header and search", "App Preview".
    func title(plan: AutopilotPlan) -> String {
        switch self {
        case .screenshots: String(localized: "Screenshots")
        case .artwork: plan.alsoMakes.artworkSize.placeTitle
        case .appPreview: String(localized: "App Preview")
        }
    }

    /// "Approve Screenshots", "Approve Header and Search", "Approve App
    /// Preview".
    func approveTitle(plan: AutopilotPlan) -> String {
        switch self {
        case .screenshots: String(localized: "Approve Screenshots")
        case .artwork:
            switch plan.alsoMakes.artworkSize {
            case .headerOnly: String(localized: "Approve Header")
            case .searchOnly: String(localized: "Approve Search Results")
            case .headerAndSearch, .wide: String(localized: "Approve Header and Search")
            }
        case .appPreview: String(localized: "Approve App Preview")
        }
    }

    var identifier: String { rawValue }
}
