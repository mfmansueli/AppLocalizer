//
//  StarterPreview.swift
//  AppLocalizer
//

import Foundation

/// A starter template card: its first three slots rendered with the
/// primary locale's captions and captures.
struct StarterPreview: Identifiable, Hashable, Sendable {
    var starter: TemplateStarter
    var jobs: [RenderJob]

    var id: TemplateStarter { starter }

    /// Rendered at twice the card's 66 pt thumbnails.
    static let pixelWidth = 132
}
