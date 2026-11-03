//
//  AppPreviewVideoSurface.swift
//  AppLocalizer
//

import AVKit
import SwiftUI

/// The App Preview's picture, without the system's controls: the stage
/// draws its own (play, time, sound, the scenes).
struct AppPreviewVideoSurface: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context _: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        view.player = player
        return view
    }

    func updateNSView(_ view: AVPlayerView, context _: Context) {
        if view.player !== player { view.player = player }
    }
}
