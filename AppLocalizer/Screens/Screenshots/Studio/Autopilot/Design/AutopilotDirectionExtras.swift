//
//  AutopilotDirectionExtras.swift
//  AppLocalizer
//

import SwiftUI

/// What a direction brings beside the screenshots, in its look: the
/// header and search artwork (or the one 16:9 image) and the App Preview's
/// poster, in the primary language with the picks. A click opens them full
/// size: a loop plays, and the poster opens the App Preview's recording.
struct AutopilotDirectionExtras: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let direction: AutopilotDirection
    var height: CGFloat = 64

    /// The App Preview poster's width ÷ height (886 × 1920).
    static let posterRatio: CGFloat = 886 / 1920

    var body: some View {
        let plan = run.plan
        let primary = plan.primaryLocale
        let kinds = plan.artworkKinds
        HStack(alignment: .bottom, spacing: Spacing.small) {
            ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
                let slots = AutopilotArtworkMaker.slots(for: kind, plan: plan)
                opening(index, label: StudioArtworkDetails.title(kind)) {
                    ArtworkThumbnail(
                        studio: studio, kind: kind, template: direction.artworkLook, locale: primary,
                        headline: studio.artworkHeadline(ArtworkTextRole.role(for: kind), locale: primary),
                        slots: slots, captures: studio.pickedCaptures(slots, run: run), width: (height * Self.ratio(kind)).rounded(.down),
                        shows: plan.alsoMakes.artworkShows, isMotion: plan.alsoMakes.makesMotion
                    )
                }
            }
            if !plan.previewDisplays.isEmpty, let first = plan.screens.first {
                opening(kinds.count, label: String(localized: "App Preview")) {
                    AppPreviewPosterView(
                        template: direction.previewLook,
                        headline: studio.extrasHeadline(slot: 0, locale: primary, plan: plan),
                        capture: studio.image(for: run.pickedCapture(for: first.id), width: 240),
                        length: ExtrasPreviewFile.lengthTitle(Double(AutopilotExtras.previewSeconds)),
                        width: (height * Self.posterRatio).rounded(.down)
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.direction.extras")
    }

    private func opening(_ index: Int, label: String, @ViewBuilder thumbnail: () -> some View) -> some View {
        Button { studio.openDirectionExtras(direction, at: index) } label: { thumbnail() }
            .buttonStyle(.plain)
            .help(Text("Click to view larger"))
            .accessibilityLabel(Text("View \(label) of \(direction.name) larger"))
            .accessibilityIdentifier("autopilot.direction.extra.\(index)")
    }

    static func ratio(_ kind: AutopilotArtworkKind) -> CGFloat {
        CGFloat(kind.pixelSize.width) / CGFloat(kind.pixelSize.height)
    }

    /// The tallest the row can be and still fit `width`, at most `maximum`.
    static func fittingHeight(in width: CGFloat, kinds: [AutopilotArtworkKind], hasPreview: Bool, maximum: CGFloat = 64) -> CGFloat {
        let count = kinds.count + (hasPreview ? 1 : 0)
        guard count > 0 else { return maximum }
        let ratios = kinds.reduce(0) { $0 + ratio($1) } + (hasPreview ? posterRatio : 0)
        let room = width - Spacing.small * CGFloat(count - 1)
        return min(maximum, max(16, (room / ratios).rounded(.down)))
    }
}
