//
//  ExtrasArtworkVariant.swift
//  AppLocalizer
//

import Foundation

/// The second header or search image for a Product Page Optimization
/// test, rendered and checked in every language like the first.
struct ExtrasArtworkVariant: Codable, Hashable, Sendable {
    var role: ArtworkTextRole
    var kind: AutopilotArtworkKind
    var controlIdea: String
    var idea: String
    /// The one idea the design source says it changed.
    var change: String
    var template: ScreenshotTemplate
    /// Its Claude Design page, when it was sent as one.
    var design: AutopilotArtworkDesign?
    var files: [ExtrasArtworkFile]
    var client: String
    var madeAt: Date
}
