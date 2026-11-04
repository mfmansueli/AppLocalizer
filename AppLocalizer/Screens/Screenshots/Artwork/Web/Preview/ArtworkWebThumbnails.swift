//
//  ArtworkWebThumbnails.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Claude Design pages drawn small, kept while the app runs, so going back
/// to a stage shows its header and search at once instead of rendering
/// them again. The oldest go first past `limit`.
@MainActor
final class ArtworkWebThumbnails {
    static let shared = ArtworkWebThumbnails()

    /// What one thumbnail was drawn from.
    struct Key: Hashable {
        var html: String
        var locale: String
        var headline: String
        var appName: String
        var captures: [Int: ScreenshotCapture]
        var pixelWidth: Int
        /// The page's phrases in this language.
        var phrases: [String: String] = [:]
    }

    let limit: Int
    private var images: [Key: CGImage] = [:]
    private var order: [Key] = []

    init(limit: Int = 48) {
        self.limit = max(1, limit)
    }

    func image(for key: Key) -> CGImage? {
        images[key]
    }

    func store(_ image: CGImage, for key: Key) {
        if images.updateValue(image, forKey: key) == nil { order.append(key) }
        while order.count > limit { images[order.removeFirst()] = nil }
    }

    var count: Int { images.count }
}
