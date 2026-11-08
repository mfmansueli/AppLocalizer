//
//  GuidedLocalizeCard.swift
//  AppLocalizer
//

import Foundation

/// Localize and check's card under the bar: the captions checked and
/// shortened, then the header and search artwork drawn, then the App
/// Previews made. Bruma's run said "Captions that don’t fit are shortened
/// by Claude Code" for the hour its loops took to draw.
struct GuidedLocalizeCard: Hashable, Sendable {
    var title: String
    var detail: String

    static func make(_ run: AutopilotRun, client: String) -> GuidedLocalizeCard {
        guard let extras = run.extrasProgress, !extras.isFinished else {
            return GuidedLocalizeCard(
                title: String(localized: "Checking every image"),
                detail: String(localized: "Captions that don’t fit are shortened by \(client). Every change is listed in the review.")
            )
        }
        let plan = run.plan
        if !extras.isArtworkDone {
            let detail = plan.alsoMakes.makesMotion
                ? String(localized: """
                Every language’s \(AutopilotArtworkMotion.loopSeconds)-second loop is drawn frame by frame on this Mac and \
                checked, a few minutes each. Every caption is in.
                """)
                : String(localized: "Every language’s image is drawn and checked. Every caption is in.")
            return GuidedLocalizeCard(title: plan.alsoMakes.artworkSize.artworkTitle, detail: detail)
        }
        return GuidedLocalizeCard(
            title: extras.previewsTotal == 1 ? String(localized: "App Preview") : String(localized: "App Previews"),
            detail: String(localized: "Cut from the recordings, captioned, set to the music and checked against Apple’s rules.")
        )
    }
}
