//
//  AutopilotRun+StageTitles.swift
//  AppLocalizer
//

import Foundation

/// What Choose and Watch are called in a run: with header concepts the
/// header is chosen at Choose and its loop watched at Watch, so their
/// titles say so. At Plan, the design project Start will use decides.
extension AutopilotRun {
    /// The header and search come as concepts (at Plan: will, with `design`).
    func choosesHeader(design: DesignProjectKind) -> Bool {
        stage == .plan ? Self.proposesConcepts(plan: plan, design: design) : usesConcepts
    }

    /// Watch shows the header loop: at Watch, a loop not approved yet;
    /// before, a run that will make one.
    func watchesHeaderLoop(design: DesignProjectKind) -> Bool {
        if stage == .watchPreview { return loopReview.map { $0.approvedAt == nil } ?? false }
        return choosesHeader(design: design) && plan.alsoMakes.makesMotion
    }

    /// Watch shows the App Preview.
    var watchesAppPreview: Bool {
        stage == .watchPreview ? previewReview != nil : !plan.previewDisplays.isEmpty
    }

    /// "Choose direction and header", "Watch the header loop"; the stage's
    /// own title otherwise.
    func title(of step: AutopilotStage, design: DesignProjectKind) -> String {
        switch step {
        case .choose:
            guard choosesHeader(design: design) else { return step.title }
            return plan.makesScreenshots || !plan.previewDisplays.isEmpty
                ? String(localized: "Choose direction and header")
                : String(localized: "Choose a header")
        case .watchPreview:
            return watchTitle(design: design)
        default:
            return step.title
        }
    }

    /// "Watch and approve", "Watch the header loop", "Watch the App
    /// Preview".
    func watchTitle(design: DesignProjectKind) -> String {
        switch (watchesAppPreview, watchesHeaderLoop(design: design)) {
        case (true, true): String(localized: "Watch and approve")
        case (false, true): String(localized: "Watch the header loop")
        default: String(localized: "Watch the App Preview")
        }
    }

    var watchTitle: String { watchTitle(design: designKind) }

    /// "Approve Both", "Approve Header Loop", "Approve App Preview".
    var approveTitle: String {
        switch (watchesAppPreview, watchesHeaderLoop(design: designKind)) {
        case (true, true): String(localized: "Approve Both")
        case (false, true): String(localized: "Approve Header Loop")
        default: String(localized: "Approve App Preview")
        }
    }
}
