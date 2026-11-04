//
//  ArtworkLoopPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// A header or search loop playing in the viewer as AppLocalizer will
/// render it: every frame drawn at the size it shows, 20 seconds on
/// repeat, with Play or Pause and where it is.
struct ArtworkLoopPlayer: View {
    let layout: ArtworkLayout
    let captures: [Int: CGImage]
    var icon: CGImage?
    let width: CGFloat
    @State private var isPlaying = true
    /// Where it was paused, in seconds into the loop.
    @State private var pausedAt: Double = 0
    /// When the loop's current run started.
    @State private var startedAt = Date.now

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isPlaying)) { context in
            let seconds = position(at: context.date)
            ArtworkView(
                layout: layout, captures: captures, icon: icon, phase: seconds / ArtworkScene.loopSeconds,
                scale: width / max(layout.size.width, 1)
            )
            .overlay(alignment: .bottomLeading) { controls(seconds: seconds) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("artwork.loop")
    }

    /// Seconds into the loop: running, or where it was paused.
    func position(at date: Date) -> Double {
        guard isPlaying else { return pausedAt }
        return Self.position(elapsed: date.timeIntervalSince(startedAt) + pausedAt)
    }

    /// `elapsed` seconds wrapped into the 20-second loop.
    static func position(elapsed: Double) -> Double {
        let length = ArtworkScene.loopSeconds
        let wrapped = elapsed.truncatingRemainder(dividingBy: length)
        return wrapped < 0 ? wrapped + length : wrapped
    }

    private func controls(seconds: Double) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Button {
                toggle(at: seconds)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 14)
            }
            .buttonStyle(.plain)
            .help(Text(isPlaying ? "Pause" : "Play"))
            .accessibilityLabel(Text(isPlaying ? "Pause the loop" : "Play the loop"))
            .accessibilityIdentifier("artwork.loop.play")
            Text(verbatim: "\(AutopilotRun.timeTitle(seconds.rounded(.down))) / \(AutopilotRun.timeTitle(ArtworkScene.loopSeconds))")
                .monospacedDigit()
                .accessibilityIdentifier("artwork.loop.time")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, 4)
        .background(.black.opacity(0.55), in: Capsule())
        .environment(\.layoutDirection, .leftToRight)
        .padding(Spacing.small)
    }

    private func toggle(at seconds: Double) {
        if isPlaying {
            pausedAt = seconds
        } else {
            startedAt = .now
        }
        isPlaying.toggle()
    }
}
