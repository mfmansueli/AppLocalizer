//
//  GuidedShotImage.swift
//  AppLocalizer
//

import SwiftUI

/// A screenshot of the live or the new set at the size the guided sheet
/// draws it, rendered (or loaded) at twice that width on its own, so the
/// Screenshots page's renders go on undisturbed.
struct GuidedShotImage: View {
    let studio: ScreenshotStudioModel
    let shot: StudioShot
    let width: CGFloat
    @State private var image: CGImage?

    var body: some View {
        StudioShotImage(image: image ?? studio.image(for: shot), width: width, aspect: shot.aspect)
            .task(id: TaskKey(shot: shot, width: width)) { image = await load() }
            .accessibilityLabel(Text(shot.label))
    }

    private struct TaskKey: Hashable {
        var shot: StudioShot
        var width: CGFloat
    }

    private func load() async -> CGImage? {
        let pixels = Int((width * 2).rounded())
        switch shot.image {
        case let .render(job): return await studio.renderQueue.largeImage(for: job, pixelWidth: pixels)
        case let .live(live): return await studio.renderQueue.largeLiveImage(live, pixelWidth: pixels)
        case .none: return nil
        }
    }
}
