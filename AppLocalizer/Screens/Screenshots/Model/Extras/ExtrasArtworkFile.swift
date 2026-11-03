//
//  ExtrasArtworkFile.swift
//  AppLocalizer
//

import Foundation

/// One header or search image in one language: its PNG's checksum (the
/// file's name), the headline it carries, whether it fit, and what the
/// checks found (errors block pushing it).
struct ExtrasArtworkFile: Codable, Hashable, Sendable, Identifiable {
    var kind: AutopilotArtworkKind
    var locale: String
    var fileID: String
    var headline: String
    var fits: Bool
    var byteCount: Int
    /// Nil for artwork made before the checks.
    var checks: [ArtworkCheck]?
    /// The 20-second motion loop the PNG is the poster of; nil for a still.
    var loop: ExtrasArtworkLoop?

    var id: String { "\(kind.rawValue)-\(locale)" }
    var pixelSize: PixelSize { kind.pixelSize }
    var fileName: String { "\(kind.rawValue)-\(locale).png" }

    var errors: [ArtworkCheck] { (checks ?? []).filter(\.isError) }
    var warnings: [ArtworkCheck] { (checks ?? []).filter { !$0.isError } }
}
