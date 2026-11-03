//
//  StudioViewerContent.swift
//  AppLocalizer
//

import Foundation

/// What the full-size viewer draws: a screenshot from the preview, one
/// drawn from a direction's layout, a capture, the header or search
/// artwork, or an App Preview, which plays in place.
enum StudioViewerContent: Hashable {
    /// A screenshot on the product page or in search results, rendered or
    /// live.
    case shot(StudioShot)
    /// A direction's screenshot, drawn from its layout with its capture.
    case layout(ScreenshotLayout, capture: AutopilotCapture?)
    /// A capture as it is: Apple Watch's.
    case capture(AutopilotCapture)
    case artwork(StudioArtworkItem)
    case appPreview(ExtrasPreviewFile)
    /// A raw App Preview recording, playing in place.
    case recording(AutopilotRecording)
    /// iPhone Duo's inner and cover display captures of a screen, side by
    /// side.
    case duoPair(inner: AutopilotCapture, cover: AutopilotCapture)

    /// Height ÷ width.
    var aspect: Double {
        switch self {
        case let .shot(shot): shot.aspect
        case let .layout(layout, _): layout.canvas.width > 0 ? layout.canvas.height / layout.canvas.width : 2.17
        case let .capture(capture): Self.aspect(capture.pixelSize)
        case let .artwork(item): Self.aspect(item.kind.pixelSize)
        case let .appPreview(file): Self.aspect(file.pixelSize)
        case let .recording(recording): Self.aspect(recording.pixelSize)
        case let .duoPair(inner, cover): Self.pairAspect(inner: inner.pixelSize, cover: cover.pixelSize)
        }
    }

    /// Its size in pixels.
    var pixelSize: PixelSize? {
        switch self {
        case let .shot(shot): shot.pixelSize
        case let .layout(layout, _): layout.canvas.pixelSize
        case let .capture(capture): capture.pixelSize
        case let .artwork(item): item.kind.pixelSize
        case let .appPreview(file): file.pixelSize
        case let .recording(recording): recording.pixelSize
        case .duoPair: nil
        }
    }

    var isAppPreview: Bool {
        if case .appPreview = self { return true }
        return false
    }

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }

    /// It plays in place: Space plays or pauses it.
    var plays: Bool { isAppPreview || isRecording }

    /// Both displays at the same height, side by side.
    static func pairAspect(inner: PixelSize, cover: PixelSize) -> Double {
        let widths = 1 / aspect(inner) + 1 / aspect(cover)
        return widths > 0 ? 1 / widths : 0.5
    }

    static func aspect(_ size: PixelSize) -> Double {
        size.width > 0 ? Double(size.height) / Double(size.width) : 2.17
    }
}
