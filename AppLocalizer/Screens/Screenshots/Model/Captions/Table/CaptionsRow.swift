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

    var id: String { locale.code }

    var needsAttention: Bool { cells.contains(where: \.needsAttention) }
}
