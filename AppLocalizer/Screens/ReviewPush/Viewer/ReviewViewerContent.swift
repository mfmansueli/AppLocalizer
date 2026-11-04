//
//  ReviewViewerContent.swift
//  AppLocalizer
//

import Foundation

/// What Review & Push's viewer draws: a slot's live screenshot or the one
/// a push sends there, a header or search image (a motion one plays on
/// repeat), or an App Preview, which plays with its controls.
enum ReviewViewerContent: Hashable {
    case screenshot(ScreenshotPlanItem)
    case artwork(ExtrasReviewItem)
    /// `musicTitle` is the music it was mixed with, when known.
    case appPreview(ExtrasReviewItem, file: ExtrasPreviewFile, musicTitle: String?)

    var isAppPreview: Bool {
        if case .appPreview = self { return true }
        return false
    }

    /// A motion header or search image: it plays on repeat.
    var isMotion: Bool {
        if case let .artwork(item) = self { return item.isMotion }
        return false
    }

    /// It plays in place: Space plays or pauses it.
    var plays: Bool { isAppPreview || isMotion }

    /// Height ÷ width of what `side` shows (only a screenshot has two).
    func aspect(_ side: ReviewViewerSide) -> Double {
        switch self {
        case let .screenshot(item):
            if side == .live, let size = item.old?.pixelSize, size.width > 0 { return Self.aspect(size) }
            return Double(ScreenshotThumbnail.aspect(of: item))
        case let .artwork(item): return Self.aspect(item.pixelSize)
        case let .appPreview(_, file, _): return Self.aspect(file.pixelSize)
        }
    }

    /// Its size in pixels on `side`; nil when it isn't known.
    func pixelSize(_ side: ReviewViewerSide) -> PixelSize? {
        switch self {
        case let .screenshot(item):
            side == .live ? item.old?.pixelSize : item.content.renderJob?.layout.canvas.pixelSize ?? item.content.backupImage?.pixelSize
        case let .artwork(item): item.pixelSize
        case let .appPreview(_, file, _): file.pixelSize
        }
    }

    static func aspect(_ size: PixelSize) -> Double {
        size.width > 0 ? Double(size.height) / Double(size.width) : 2.17
    }
}
