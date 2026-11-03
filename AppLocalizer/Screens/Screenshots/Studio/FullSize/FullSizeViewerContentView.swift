//
//  FullSizeViewerContentView.swift
//  AppLocalizer
//

import SwiftUI

/// One item drawn as large as the viewer allows: screenshots rendered
/// again at that size, the artwork drawn at it, the App Preview playing.
struct FullSizeViewerContentView: View {
    @Bindable var studio: ScreenshotStudioModel
    let item: StudioViewerItem
    /// The room it has.
    let size: CGSize
    @State private var large: CGImage?

    /// The App Preview's controls under it.
    private static let controlsHeight: CGFloat = 96

    var body: some View {
        content
            .accessibilityElement(children: item.content.plays ? .contain : .ignore)
            .accessibilityLabel(Text(item.title))
            .accessibilityIdentifier("studio.viewer.item.\(item.id)")
    }

    @ViewBuilder
    private var content: some View {
        switch item.content {
        case let .shot(shot):
            StudioShotImage(
                image: large ?? studio.image(for: shot), width: width, aspect: shot.aspect,
                cornerFraction: shot.pixelSize.width < 600 ? 0.24 : 0.05
            )
            .shadow(color: .black.opacity(0.55), radius: 35, y: 24)
            .task(id: shot) { large = await largeImage(of: shot) }
        case let .layout(layout, capture):
            AutopilotLayoutImage(layout: layout, capture: studio.image(for: capture, width: pixelWidth(layout.canvas.pixelSize)), width: width)
                .shadow(color: .black.opacity(0.55), radius: 35, y: 24)
        case let .capture(capture):
            StudioShotImage(
                image: studio.image(for: capture, width: capture.pixelSize.width), width: width,
                aspect: item.content.aspect, cornerFraction: capture.pixelSize.width < 600 ? 0.24 : 0.05
            )
            .shadow(color: .black.opacity(0.5), radius: 25, y: 20)
        case let .duoPair(inner, cover):
            duoPair(inner: inner, cover: cover)
        case .recording:
            if let run = studio.run {
                AutopilotRecordingPlayer(studio: studio, run: run, width: recordingWidth)
                    .environment(\.colorScheme, .dark)
            }
        case let .artwork(artwork):
            ArtworkThumbnail(
                studio: studio, kind: artwork.kind, template: artwork.template, locale: artwork.locale,
                headline: artwork.headline, slots: artwork.slots, captures: artwork.captures, width: width.rounded(),
                shows: artwork.shows, isMotion: artwork.isMotion
            )
            .overlay {
                if artwork.kind == .header, studio.viewerShowsGuide { ArtworkHeaderGuide() }
            }
            .shadow(color: .black.opacity(0.55), radius: 35, y: 24)
        case let .appPreview(file):
            StudioAppPreviewPlayer(studio: studio, file: file, width: width.rounded())
        }
    }

    /// The inner display and the cover display at the same height, with
    /// what each is under it.
    private func duoPair(inner: AutopilotCapture, cover: AutopilotCapture) -> some View {
        let labels: CGFloat = 28
        let gap: CGFloat = 22
        let innerAspect = StudioViewerContent.aspect(inner.pixelSize)
        let coverAspect = StudioViewerContent.aspect(cover.pixelSize)
        let height = max(80, min(size.height - labels, (size.width - gap) / (1 / innerAspect + 1 / coverAspect)))
        return HStack(alignment: .bottom, spacing: gap) {
            duoDisplay(inner, width: height / innerAspect, label: String(localized: "Inner display · unfolded"))
            duoDisplay(cover, width: height / coverAspect, label: String(localized: "Cover display · folded"))
        }
    }

    private func duoDisplay(_ capture: AutopilotCapture, width: CGFloat, label: String) -> some View {
        VStack(spacing: Spacing.small) {
            StudioShotImage(
                image: studio.image(for: capture, width: min(capture.pixelSize.width, Int(width * 2))), width: width.rounded(),
                aspect: StudioViewerContent.aspect(capture.pixelSize), cornerFraction: 0.05
            )
            .padding(5)
            .background(Color(white: 0.11), in: RoundedRectangle(cornerRadius: width * 0.05 + 5, style: .continuous))
            .shadow(color: .black.opacity(0.55), radius: 35, y: 24)
            Text(label)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    /// The raw recording as large as it plays well, with its controls.
    private var recordingWidth: CGFloat {
        let aspect = CGFloat(max(item.content.aspect, 0.1))
        let cap: CGFloat = aspect < 1 ? 760 : 262
        return max(160, min(cap, size.width - 14, (size.height - Self.controlsHeight - 14) / aspect))
    }

    /// As wide as the room allows at its proportions; the App Preview
    /// keeps room for its controls and stays at a size it plays well at.
    private var width: CGFloat {
        let aspect = CGFloat(max(item.content.aspect, 0.1))
        if item.content.isAppPreview {
            return max(160, min(380, size.width, (size.height - Self.controlsHeight) / aspect))
        }
        return max(80, min(size.width, size.height / aspect))
    }

    /// Twice the points, at most the image's own pixels.
    private func pixelWidth(_ pixels: PixelSize?) -> Int {
        let wanted = Int((width * 2).rounded())
        guard let pixels, pixels.width > 0 else { return wanted }
        return min(wanted, pixels.width)
    }

    private func largeImage(of shot: StudioShot) async -> CGImage? {
        let pixels = pixelWidth(shot.pixelSize)
        switch shot.image {
        case let .render(job): return await studio.renderQueue.largeImage(for: job, pixelWidth: pixels)
        case let .live(live): return await studio.screenshots.services.liveImage(live, pixelWidth: pixels)
        case .none: return nil
        }
    }
}
