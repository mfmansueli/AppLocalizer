//
//  GuidedJobImage.swift
//  AppLocalizer
//

import SwiftUI

/// One render the Look step lays out itself (a gallery template with the
/// app's captions and captures), rendered at twice the width it shows at.
struct GuidedJobImage: View {
    let studio: ScreenshotStudioModel
    let job: RenderJob
    let width: CGFloat
    var label: String = ""
    /// As in `StudioShotImage`: Apple Watch's screen is much rounder.
    var cornerFraction: CGFloat = 0.05
    @State private var image: CGImage?

    var body: some View {
        StudioShotImage(image: image, width: width, aspect: aspect, cornerFraction: cornerFraction)
            .task(id: TaskKey(key: job.key, width: width)) {
                image = await studio.renderQueue.largeImage(for: job, pixelWidth: Int((width * 2).rounded()))
            }
            .accessibilityLabel(Text(label))
    }

    private struct TaskKey: Hashable {
        var key: RenderKey
        var width: CGFloat
    }

    private var aspect: Double {
        let size = job.layout.canvas.pixelSize
        return Double(size.height) / Double(max(size.width, 1))
    }
}
