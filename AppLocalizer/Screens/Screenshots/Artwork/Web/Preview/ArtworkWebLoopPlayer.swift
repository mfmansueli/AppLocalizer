//
//  ArtworkWebLoopPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// A Claude Design page's loop playing in the viewer, live from its own
/// CSS, keeping the `clock`'s time: it seeks, plays and pauses with it.
/// Its controls are under it (`ArtworkLoopControls`).
struct ArtworkWebLoopPlayer: View {
    let request: ArtworkWebRequest
    let width: CGFloat
    let clock: ArtworkLoopClock

    var body: some View {
        let ratio = CGFloat(request.pixelSize.height) / CGFloat(max(request.pixelSize.width, 1))
        ArtworkWebPreview(request: request, playback: clock.playback, willLoad: clock.waitForPage, didLoad: clock.pageReady)
            .frame(width: width, height: (width * ratio).rounded())
            .onAppear { clock.restart(waitsForPage: true) }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("artwork.loop")
    }
}
