//
//  AutopilotDirectionExtras.swift
//  AppLocalizer
//

import SwiftUI

/// What a direction brings beside the screenshots, in its look: the
/// header and search artwork (or the one 16:9 image) and the App Preview's
/// poster, in the primary language with the picks.
struct AutopilotDirectionExtras: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let direction: AutopilotDirection
    var height: CGFloat = 64

    var body: some View {
        let plan = run.plan
        let primary = plan.primaryLocale
        HStack(alignment: .bottom, spacing: Spacing.small) {
            ForEach(plan.artworkKinds, id: \.self) { kind in
                let slots = AutopilotArtworkMaker.slots(for: kind, plan: plan)
                let ratio = CGFloat(kind.pixelSize.width) / CGFloat(kind.pixelSize.height)
                ArtworkThumbnail(
                    studio: studio, kind: kind, template: direction.artworkLook, locale: primary,
                    headline: studio.artworkHeadline(ArtworkTextRole.role(for: kind), locale: primary),
                    slots: slots, captures: studio.pickedCaptures(slots, run: run), width: (height * ratio).rounded(),
                    shows: plan.alsoMakes.artworkShows, isMotion: plan.alsoMakes.makesMotion
                )
            }
            if !plan.previewDisplays.isEmpty, let first = plan.screens.first {
                AppPreviewPosterView(
                    template: direction.previewLook,
                    headline: studio.extrasHeadline(slot: 0, locale: primary, plan: plan),
                    capture: studio.image(for: run.pickedCapture(for: first.id), width: 240),
                    length: ExtrasPreviewFile.lengthTitle(Double(AutopilotExtras.previewSeconds)),
                    width: (height * 886 / 1920).rounded()
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.direction.extras")
    }
}
