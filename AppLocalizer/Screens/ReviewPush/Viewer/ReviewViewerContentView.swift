//
//  ReviewViewerContentView.swift
//  AppLocalizer
//

import SwiftUI

/// One item in Review & Push's viewer, as large as the room allows: a
/// screenshot rendered again (or read) at that size, the thumbnail
/// meanwhile; a header or search image read at it; an App Preview playing
/// with its controls; a motion image playing on repeat. Pinch to zoom.
struct ReviewViewerContentView: View {
    let viewModel: ReviewPushViewModel
    let item: ReviewViewerItem
    let side: ReviewViewerSide
    let previewPlayer: AppPreviewPlayerModel
    let loopPlayer: AppPreviewPlayerModel
    /// The room it has.
    let size: CGSize

    @State private var large: CGImage?

    /// The App Preview's controls under it.
    private static let previewControlsHeight: CGFloat = 96
    /// A motion image's Play and note under it.
    static let loopControlsHeight: CGFloat = 40
    static let zoomIdentifier = "review.viewer.zoom"

    var body: some View {
        if zoomsItself {
            // The zoom is the item: an element around it would take its identifier.
            content
        } else {
            content
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text(item.title))
                .accessibilityIdentifier("review.viewer.item.\(item.id)")
        }
    }

    /// A still: the zoom holds nothing but it.
    private var zoomsItself: Bool {
        switch item.content {
        case .screenshot: true
        case let .artwork(extra): extra.loopFileURL == nil
        case .appPreview: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.content {
        case let .screenshot(shot):
            ZoomableContainer(identifier: Self.zoomIdentifier, label: item.title) {
                if side == .live, shot.old == nil {
                    nothingLive
                } else {
                    StudioShotImage(image: large ?? thumbnail(of: shot), width: width, aspect: aspect, cornerFraction: 0.05)
                        .shadow(color: .black.opacity(0.55), radius: 35, y: 24)
                }
            }
            .task { large = await largeImage(of: shot) }
        case let .artwork(extra):
            if let loop = extra.loopFileURL {
                ReviewLoopPlayer(model: loopPlayer, url: loop, poster: large, width: width, aspect: aspect)
                    .task { large = await artworkImage(extra) }
            } else {
                ZoomableContainer(identifier: Self.zoomIdentifier, label: item.title) {
                    StudioShotImage(image: large, width: width, aspect: aspect, cornerFraction: 0.01)
                        .shadow(color: .black.opacity(0.55), radius: 35, y: 24)
                }
                .task { large = await artworkImage(extra) }
            }
        case let .appPreview(extra, file, musicTitle):
            AppPreviewPlayer(
                model: previewPlayer, file: file, url: extra.fileURL, musicTitle: musicTitle, poster: nil, width: width.rounded(),
                zoomIdentifier: Self.zoomIdentifier
            )
        }
    }

    /// The live side of a slot with nothing live: what shows there instead.
    private var nothingLive: some View {
        RoundedRectangle(cornerRadius: max(4, width * 0.05), style: .continuous)
            .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            .overlay {
                Text(item.subtitle(.live))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(Spacing.medium)
            }
            .frame(width: width, height: (width * aspect).rounded())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("review.viewer.nothingLive")
    }

    private var aspect: Double { max(item.content.aspect(side), 0.1) }

    /// As wide as the room allows at its proportions, keeping room for a
    /// movie's controls; an App Preview stays at a size it plays well at.
    private var width: CGFloat {
        switch item.content {
        case .appPreview:
            max(160, min(380, size.width, (size.height - Self.previewControlsHeight) / aspect))
        case let .artwork(extra) where extra.isMotion:
            max(80, min(size.width, (size.height - Self.loopControlsHeight) / aspect))
        default:
            max(80, min(size.width, size.height / aspect))
        }
    }

    /// Twice the points, at most the image's own pixels.
    private var pixelWidth: Int {
        let wanted = Int((width * 2).rounded())
        guard let pixels = item.content.pixelSize(side), pixels.width > 0 else { return wanted }
        return min(wanted, pixels.width)
    }

    /// The review list's thumbnail, while the large one loads.
    private func thumbnail(of shot: ScreenshotPlanItem) -> CGImage? {
        side == .live ? viewModel.screenshots.oldImage(for: shot) : viewModel.screenshots.newImage(for: shot)
    }

    private func largeImage(of shot: ScreenshotPlanItem) async -> CGImage? {
        side == .live
            ? await viewModel.screenshots.largeOldImage(for: shot, pixelWidth: pixelWidth)
            : await viewModel.screenshots.largeNewImage(for: shot, pixelWidth: pixelWidth)
    }

    /// The PNG (a motion image's poster) at the size it's drawn.
    private func artworkImage(_ extra: ExtrasReviewItem) async -> CGImage? {
        await ExtrasFileThumbnail.thumbnail(extra.fileURL, maxPixels: ScreenshotPushController.longSide(of: extra.pixelSize, width: pixelWidth))
    }
}
