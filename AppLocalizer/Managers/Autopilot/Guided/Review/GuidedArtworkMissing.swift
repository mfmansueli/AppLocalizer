//
//  GuidedArtworkMissing.swift
//  AppLocalizer
//

import Foundation

/// Review & push's header part when the run's header or search artwork
/// couldn't be made: what went wrong, and that Make Again makes it again
/// from the person's choices. Approving instead pushes the rest without it,
/// so a header that keeps failing never holds back the screenshots.
struct GuidedArtworkMissing: Equatable {
    /// "Header artwork couldn’t be made".
    let title: String
    /// Why, then what Make Again and Approve do.
    let detail: String

    /// Nil while the artwork is in the set, or the run isn't ready.
    @MainActor
    init?(run: AutopilotRun, extras: ScreenshotExtras?) {
        guard AutopilotCenter.artworkMissing(run, extras: extras) else { return nil }
        let size = run.plan.alsoMakes.artworkSize
        title = String(localized: "\(size.artworkTitle) couldn’t be made")
        let reason = run.extrasProgress?.artworkProblem
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
            ?? String(localized: "Nothing of it was saved with the set.")
        detail = reason + " " + String(localized: """
        Make Again makes it again from your choices, without designing anything again. \
        Approving pushes the rest without it.
        """)
    }
}
