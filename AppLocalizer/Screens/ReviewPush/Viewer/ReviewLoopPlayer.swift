//
//  ReviewLoopPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// A motion header or search image in Review & Push's viewer: its poster
/// until it plays, then the loop on repeat and muted, the way the App
/// Store plays it. Click it or Play to play or pause; pinch to zoom.
struct ReviewLoopPlayer: View {
    let model: AppPreviewPlayerModel
    let url: URL
    /// The still the push sends with it, read at the size it's drawn.
    let poster: CGImage?
    let width: CGFloat
    /// Height ÷ width.
    let aspect: Double

    var body: some View {
        VStack(spacing: Spacing.small) {
            ZoomableContainer(identifier: ReviewViewerContentView.zoomIdentifier, doubleClickZooms: false) {
                Button {
                    model.toggle()
                } label: {
                    video
                }
                .buttonStyle(.plain)
                .help(Text(model.isPlaying ? "Pause" : "Play"))
                .accessibilityLabel(Text(model.isPlaying ? "Pause the loop" : "Play the loop"))
                .accessibilityIdentifier("review.viewer.loop")
            }
            .frame(width: width, height: height)
            HStack(spacing: Spacing.small) {
                Button(model.isPlaying ? "Pause" : "Play") { model.toggle() }
                    .controlSize(.small)
                    .frame(minWidth: 64)
                    .disabled(!model.canPlay)
                    .accessibilityIdentifier("review.viewer.loop.play")
                Text(model.timeTitle)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("review.viewer.loop.time")
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
            }
            .frame(height: ReviewViewerContentView.loopControlsHeight - Spacing.small)
        }
        .task(id: url) {
            model.loops = true
            model.isMuted = true
            model.load(url, seconds: Double(AutopilotArtworkMotion.loopSeconds))
        }
    }

    private var height: CGFloat { (width * aspect).rounded() }

    /// The poster until it first plays, and while there's no movie.
    private var showsPoster: Bool {
        !model.canPlay || (!model.isPlaying && model.seconds == 0)
    }

    private var video: some View {
        ZStack {
            AppPreviewVideoSurface(player: model.player)
                .allowsHitTesting(false)
            if showsPoster {
                if let poster {
                    Image(decorative: poster, scale: 1)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Palette.fill2
                }
            }
        }
        .frame(width: width, height: height)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .contentShape(Rectangle())
    }

    /// "Plays muted on repeat on the App Store", or why it can't play.
    private var note: String {
        model.canPlay ? String(localized: "Plays muted on repeat on the App Store") : String(localized: "The loop isn’t on this Mac")
    }
}
