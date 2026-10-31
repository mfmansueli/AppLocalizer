//
//  DesignSourceSummary.swift
//  AppLocalizer
//

import Foundation

/// What was found in a design project, so the person can see it's the
/// right one: colors, type, logo and voice.
struct DesignSourceSummary: Codable, Hashable, Sendable {
    /// "Northpier Brand · design system".
    var title: String
    var colors: [DesignSwatch] = []
    /// "New York Bold for headlines · SF Pro Text for the rest".
    var typefaces: String?
    /// "Moon mark, light and dark".
    var logo: String?
    /// "Calm, short sentences, no exclamation marks".
    var voice: String?
    /// When the source last changed, if it says.
    var updated: Date?
    /// Who read it: "Claude Code", or AppLocalizer for a folder.
    var readBy: String?
}
