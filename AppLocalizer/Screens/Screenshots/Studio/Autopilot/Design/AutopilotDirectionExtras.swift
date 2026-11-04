//
//  AutopilotDirectionExtras.swift
//  AppLocalizer
//

import SwiftUI

/// What a direction brings beside the screenshots, in its look: the
/// header and search artwork (or the one 16:9 image) and the App Preview's
/// poster, in the primary language with the picks. A click opens them full
/// size: a loop plays, and the poster opens the App Preview's recording.
/// In a run without screenshots they're all the direction shows, so they
/// get bigger and the header can take a line of its own (`Fit`).
struct AutopilotDirectionExtras: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let direction: AutopilotDirection
    var fit = Fit(height: 64)

    /// The App Preview poster's width ÷ height (886 × 1920).
    static let posterRatio: CGFloat = 886 / 1920

    /// How tall the images are: all on one line, or the first (the header,
    /// or the one 16:9 image) on a line of its own at `height` and the rest
    /// under it at `secondHeight`.
    struct Fit: Equatable {
        var height: CGFloat
        var secondHeight: CGFloat?

        var stacks: Bool { secondHeight != nil }
    }

    var body: some View {
        let count = run.plan.artworkKinds.count + (hasPreview ? 1 : 0)
        Group {
            if let second = fit.secondHeight, count > 1 {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    line(0..<1, height: fit.height)
                    line(1..<count, height: second)
                }
            } else {
                line(0..<count, height: fit.height)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.direction.extras")
    }

    private var hasPreview: Bool { !run.plan.previewDisplays.isEmpty && !run.plan.screens.isEmpty }

    private func line(_ indices: Range<Int>, height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: Spacing.small) {
            ForEach(indices, id: \.self) { index in
                item(index, height: height)
            }
        }
    }

    /// The artwork at `index` in the plan's kinds, then the poster.
    @ViewBuilder
    private func item(_ index: Int, height: CGFloat) -> some View {
        let plan = run.plan
        let primary = plan.primaryLocale
        let kinds = plan.artworkKinds
        if kinds.indices.contains(index) {
            let kind = kinds[index]
            let page = direction.artworkDesign?.page(for: kind)
            let slots = page.map(AutopilotArtworkPages.slots) ?? AutopilotArtworkMaker.slots(for: kind, plan: plan)
            opening(index, label: StudioArtworkDetails.title(kind)) {
                ArtworkThumbnail(
                    studio: studio, kind: kind, template: direction.artworkLook, locale: primary,
                    headline: studio.artworkHeadline(ArtworkTextRole.role(for: kind), locale: primary),
                    slots: slots, captures: studio.pickedCaptures(slots, run: run), width: (height * Self.ratio(kind)).rounded(.down),
                    shows: plan.alsoMakes.artworkShows, isMotion: plan.alsoMakes.makesMotion, page: page
                )
            }
        } else if let first = plan.screens.first {
            opening(index, label: String(localized: "App Preview")) {
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

    /// The images on one line, as tall as fits `width`; with `stacking`,
    /// the first on a line of its own when that makes both lines at least a
    /// third taller. Never taller than `maximum`.
    static func fit(in width: CGFloat, kinds: [AutopilotArtworkKind], hasPreview: Bool, maximum: CGFloat, stacking: Bool = false) -> Fit {
        let oneLine = fittingHeight(in: width, kinds: kinds, hasPreview: hasPreview, maximum: maximum)
        guard stacking, let first = kinds.first, kinds.count + (hasPreview ? 1 : 0) > 1, oneLine < maximum else { return Fit(height: oneLine) }
        let top = fittingHeight(in: width, kinds: [first], hasPreview: false, maximum: maximum)
        let rest = fittingHeight(in: width, kinds: Array(kinds.dropFirst()), hasPreview: hasPreview, maximum: maximum)
        guard min(top, rest) >= oneLine * 4 / 3 else { return Fit(height: oneLine) }
        return Fit(height: top, secondHeight: rest)
    }
}
