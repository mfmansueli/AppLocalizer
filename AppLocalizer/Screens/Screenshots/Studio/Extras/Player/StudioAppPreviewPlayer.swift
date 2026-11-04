//
//  StudioAppPreviewPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// An App Preview from the set, playing in the studio's player: its movie
/// in the app's Extras folder, the music it was mixed with, and its poster
/// while the movie isn't on this Mac. Made again, the saved set's new file
/// for the same device and language takes its place.
struct StudioAppPreviewPlayer: View {
    @Bindable var studio: ScreenshotStudioModel
    let shown: ExtrasPreviewFile
    let width: CGFloat
    /// Pinch to zoom the video (the full-size viewer); nil doesn't zoom.
    let zoomIdentifier: String?

    init(studio: ScreenshotStudioModel, file: ExtrasPreviewFile, width: CGFloat, zoomIdentifier: String? = nil) {
        self.studio = studio
        shown = file
        self.width = width
        self.zoomIdentifier = zoomIdentifier
    }

    private var file: ExtrasPreviewFile {
        studio.runPreviews.first { $0.id == shown.id } ?? shown
    }

    private static let captureWidth = 480

    var body: some View {
        AppPreviewPlayer(
            model: studio.previewPlayer, file: file, url: studio.previewURL(file),
            musicTitle: (studio.screenshots.document?.extras?.previewMusic ?? studio.previewMusic).title,
            poster: poster, width: width, zoomIdentifier: zoomIdentifier
        )
        .task(id: capture) {
            if let capture { studio.screenshots.captureImages.request([capture], width: Self.captureWidth) }
        }
    }

    /// The slot of the screen the App Preview opens on.
    private var firstSlot: Int {
        guard let id = file.scenes?.first?.screenID, let slot = studio.run?.plan.slot(of: id) else { return 0 }
        return slot
    }

    private var capture: ScreenshotCapture? {
        studio.setCaptures([firstSlot], locale: file.locale)[firstSlot]
    }

    private var poster: AppPreviewPosterView? {
        guard let document = studio.screenshots.document, let template = document.extras?.previewTemplate ?? document.template else { return nil }
        return AppPreviewPosterView(
            template: template, headline: studio.extrasHeadline(slot: firstSlot, locale: file.locale, plan: studio.run?.plan),
            capture: capture.flatMap { studio.screenshots.captureImages.image(for: $0, width: Self.captureWidth) },
            length: file.lengthTitle, width: width
        )
    }
}
