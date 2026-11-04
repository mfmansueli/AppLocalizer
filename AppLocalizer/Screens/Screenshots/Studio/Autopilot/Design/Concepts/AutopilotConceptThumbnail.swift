//
//  AutopilotConceptThumbnail.swift
//  AppLocalizer
//

import SwiftUI

/// A concept's page on one canvas, rendered in the primary language with
/// the picks; a gray box while it's still being designed.
struct AutopilotConceptThumbnail: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let concept: AutopilotArtworkConcept?
    let kind: AutopilotArtworkKind
    let width: CGFloat
    /// Plays the loop's pages (Watch the header loop) instead of the still.
    var plays = false

    var body: some View {
        let plan = run.plan
        let primary = plan.primaryLocale
        let design = plays ? concept?.madeDesign : concept?.stillDesign
        let height = (width / AutopilotDirectionExtras.ratio(kind)).rounded()
        if let page = design?.page(for: kind) {
            let slots = AutopilotArtworkPages.slots(in: page)
            ArtworkThumbnail(
                studio: studio, kind: kind, template: studio.conceptLook, locale: primary,
                headline: studio.artworkHeadline(ArtworkTextRole.role(for: kind), locale: primary),
                slots: slots, captures: studio.pickedCaptures(slots, run: run), width: width,
                shows: plan.alsoMakes.artworkShows, isMotion: plays, plays: plays, page: page
            )
        } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Palette.fill2)
                .frame(width: width, height: height)
                .accessibilityHidden(true)
        }
    }
}
