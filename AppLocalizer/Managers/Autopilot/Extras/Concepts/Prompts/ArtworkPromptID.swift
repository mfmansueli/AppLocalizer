//
//  ArtworkPromptID.swift
//  AppLocalizer
//

import Foundation

/// The header and search prompts AppLocalizer sends the design AI, and the
/// blocks they share. Each is a resource file (`Resources/ArtworkPrompts`)
/// whose text is the prompt exactly, its `{{placeholders}}` filled at run
/// time. Kept provider-agnostic, so another design AI can take them.
enum ArtworkPromptID: String, CaseIterable, Hashable, Sendable {
    /// Shared: what the person asked, and the app.
    case appContext = "app-context"
    /// Shared: three great App Store headers, described.
    case referenceHeaders = "reference-headers"
    /// 1A: three concepts of the design AI's own.
    case conceptsFree = "artwork-concepts-free"
    /// 1B: one concept per picked scene template.
    case conceptsTemplates = "artwork-concepts-templates"
    /// 2: one concept's pages, a still per place.
    case pages = "artwork-pages"
    /// 3: a concept's pages, animated into a loop: each concept's at Design
    /// with Motion loop (v4), the chosen one's in runs from before.
    case motion = "artwork-motion"
    /// 4: the person's note, appended to 2 or 3.
    case change = "artwork-change"

    /// The prompts' version, logged with every use. v5 adds the brand's
    /// design language from the project scan (personality, motifs, what it
    /// avoids) and why artwork stays 4+.
    static let version = "v5"

    /// A block other prompts include as `{{block:<id>}}`.
    var isBlock: Bool { self == .appContext || self == .referenceHeaders }
}
