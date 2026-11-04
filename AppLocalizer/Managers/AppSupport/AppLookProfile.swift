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
    /// The scene template the assistant recommends, with why.
    var headerTemplate: AutopilotHeaderTemplate?
    var headerReason: String?

    /// The recommendation, when the scan made one.
    var headerRecommendation: AutopilotHeaderRecommendation? {
        headerTemplate.map { AutopilotHeaderRecommendation(template: $0, reason: headerReason ?? "", isFromScan: true) }
    }

    var isEmpty: Bool { self == AppLookProfile() }
}
