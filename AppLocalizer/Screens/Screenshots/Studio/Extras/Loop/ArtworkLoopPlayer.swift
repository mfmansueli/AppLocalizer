//
//  ArtworkLoopPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// A header or search loop playing in the viewer as AppLocalizer will
/// render it: every frame drawn at the size it shows, at the `clock`'s
/// moment, 20 seconds on repeat. Its controls are under it
/// (`ArtworkLoopControls`).
struct ArtworkLoopPlayer: View {
    let layout: ArtworkLayout
    let captures: [Int: CGImage]
    var icon: CGImage?
    let width: CGFloat
    let clock: ArtworkLoopClock

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !clock.isPlaying)) { context in
            ArtworkView(
                layout: layout, captures: captures, icon: icon, phase: clock.position(at: context.date) / ArtworkLoopClock.length,
                scale: width / max(layout.size.width, 1)
            )
        }
        .onAppear { clock.restart() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("artwork.loop")
    }
}
