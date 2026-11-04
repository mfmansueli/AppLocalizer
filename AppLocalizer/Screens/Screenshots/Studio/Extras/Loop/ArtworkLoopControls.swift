//
//  ArtworkLoopControls.swift
//  AppLocalizer
//

import SwiftUI

/// A header or search loop's controls in the viewer, under it: back and
/// forward 5 seconds, Play or Pause, where it is, and the bar to click or
/// drag through its 20 seconds.
struct ArtworkLoopControls: View {
    let clock: ArtworkLoopClock

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !clock.isPlaying)) { context in
            PlayerControls(
                identifier: "artwork.loop", isPlaying: clock.isPlaying, seconds: clock.position(at: context.date),
                duration: ArtworkLoopClock.length, timeTitle: clock.timeTitle(at: context.date),
                playLabel: Text("Play the loop"), pauseLabel: Text("Pause the loop"),
                toggle: clock.toggle, seek: clock.seek(to:), scrubbing: clock.scrub
            ) {
                Text("Plays muted on repeat on the App Store")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
            }
        }
    }
}
