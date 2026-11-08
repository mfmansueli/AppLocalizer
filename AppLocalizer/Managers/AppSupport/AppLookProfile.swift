//
//  AppLookProfile.swift
//  AppLocalizer
//

import Foundation

/// What the assistant read of the app's look in its Xcode project
/// (`report_app_support`'s look): its theme, its icon in words, who it's
/// for and when they use it, and the scene template it recommends for the
/// header. The header and search prompts are filled from it; AppLocalizer
/// can't open the project itself.
struct AppLookProfile: Codable, Hashable, Sendable {
    /// The accent color, hex.
    var accentColor: String?
    /// The theme's other colors, hex.
    var themeColors: [String] = []
    /// "SF Pro, New York".
    var fonts: [String] = []
    /// The app supports dark mode; nil when unknown.
    var supportsDarkMode: Bool?
    /// "Private journal: one prompt a day, weekly view, search across
    /// years": what the app does and its key features, from the scan.
    var whatItDoes: String?
    /// "A white crescent on indigo, flat."
    var iconDescription: String?
    /// "People who journal in the evening."
    var audience: String?
    /// "At night, before bed, alone."
    var usageMoment: String?
    /// "Quiet, warm and discreet: a mist that shields you until you
    /// choose to be seen": the brand's character, from its design docs.
    var personality: String?
    /// "drifting mist bands", "a low ember sun": the images and shapes the
    /// app's own design is built from.
    var motifs: [String]?
    /// "rainbow gradients", "loud neon": what the brand's design docs rule
    /// out. Designers treat these as clichés to leave out.
    var avoid: [String]?
    /// "DESIGN_PROJECT.md, Bruma/DesignSystem/Tokens/Palette.swift": where
    /// the assistant read the look.
    var designSource: String?
    /// The scene template the assistant recommends, with why.
    var headerTemplate: AutopilotHeaderTemplate?
    var headerReason: String?

    /// The recommendation, when the scan made one.
    var headerRecommendation: AutopilotHeaderRecommendation? {
        headerTemplate.map { AutopilotHeaderRecommendation(template: $0, reason: headerReason ?? "", isFromScan: true) }
    }

    var isEmpty: Bool { self == AppLookProfile() }

    /// The brand's own character is known: its personality, motifs or what
    /// it avoids, beyond colors and fonts. A look without it came from an
    /// older scan, and the run asks for the project to be read again.
    var hasDesignLanguage: Bool {
        personality != nil || !(motifs ?? []).isEmpty || !(avoid ?? []).isEmpty
    }

    /// What a run's designers need is known: what the app does, who it's
    /// for, and its design language.
    var isComplete: Bool {
        whatItDoes != nil && audience != nil && hasDesignLanguage
    }
}
