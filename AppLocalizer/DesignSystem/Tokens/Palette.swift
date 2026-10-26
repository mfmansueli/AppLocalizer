//
//  Palette.swift
//  AppLocalizer
//

import SwiftUI

/// Every color the UI uses, by role. Until the design handoff lands these
/// map to macOS's semantic colors (so light/dark and Increase Contrast come
/// for free); swap the values here, never at the call site.
enum Palette {
    // MARK: - Accent

    static let accent = Color.accentColor

    // MARK: - Status

    static let positive = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    // MARK: - Surfaces

    /// Fill behind app-icon placeholders and empty tiles.
    static let tile = Color.secondary.opacity(0.14)
    /// Dashed outline of drop zones.
    static let dropOutline = Color.secondary.opacity(0.45)
}
