//
//  CaptionsRow.swift
//  AppLocalizer
//

import Foundation

/// One locale's captions across the slots.
struct CaptionsRow: Hashable, Sendable, Identifiable {
    var locale: StoreLocale
    var isPrimary: Bool
    var cells: [CaptionsCell]
    /// Search results and Header, when the set has that artwork.
    var artworkCells: [ArtworkTextCell] = []

    var id: String { locale.code }

    var needsAttention: Bool { cells.contains(where: \.needsAttention) || artworkCells.contains(where: \.needsAttention) }
}
