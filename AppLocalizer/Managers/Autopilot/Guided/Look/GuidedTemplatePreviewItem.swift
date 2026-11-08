//
//  GuidedTemplatePreviewItem.swift
//  AppLocalizer
//

import Foundation

/// One screenshot of a previewed template: the screen it shows, the render
/// that draws it with the app's caption and capture, and whose interface
/// that capture is.
struct GuidedTemplatePreviewItem: Hashable, Identifiable {
    var slot: Int
    /// "Today", "Mood check-in".
    var name: String
    var job: RenderJob
    /// The capture is another language's interface (the primary one's):
    /// this language isn't captured on the device yet.
    var showsPrimaryInterface = false
    /// No capture of the device's own: the iPad screen stands in (iPhone
    /// Duo's inner display, Apple Vision Pro's window).
    var borrowsIPad = false

    var id: Int { slot }

    var hasCapture: Bool { job.capture != nil }

    /// "3 · Search".
    var label: String { "\(slot + 1) · \(name)" }

    var pixelSize: PixelSize { job.layout.canvas.pixelSize }

    /// Height ÷ width.
    var aspect: Double {
        let size = pixelSize
        return size.width > 0 ? Double(size.height) / Double(size.width) : 2.17
    }
}
