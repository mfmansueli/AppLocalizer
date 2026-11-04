//
//  ArtworkWebPreview.swift
//  AppLocalizer
//

import SwiftUI

/// SwiftUI's side of `ArtworkWebPreviewView`: a page playing live,
/// following `playback`; `willLoad` and `didLoad` bracket each load of its
/// page, so a clock can wait for it.
struct ArtworkWebPreview: NSViewRepresentable {
    let request: ArtworkWebRequest
    var playback = ArtworkLoopClock.Playback(isPlaying: true, seconds: 0, change: 0)
    var willLoad: () -> Void = {}
    var didLoad: () -> Void = {}

    func makeNSView(context _: Context) -> ArtworkWebPreviewView {
        let view = ArtworkWebPreviewView(frame: .zero)
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ view: ArtworkWebPreviewView, context _: Context) {
        view.willLoad = willLoad
        view.didLoad = didLoad
        view.show(request, playback: playback)
    }

    static func dismantleNSView(_ view: ArtworkWebPreviewView, coordinator _: ()) {
        view.close()
    }
}
