//
//  AutopilotHeaderRecommendation.swift
//  AppLocalizer
//

import Foundation

/// The scene template recommended for the app's header, and why: written
/// by Claude Code from its scan of the project (`report_app_support`'s
/// look), else AppLocalizer's own guess from the App Store categories.
struct AutopilotHeaderRecommendation: Codable, Hashable, Sendable {
    var template: AutopilotHeaderTemplate
    /// "Lumen’s icon is a moon and people write at night; a sky turning
    /// from dusk to night says that without words."
    var reason: String
    /// Claude Code wrote it; false for AppLocalizer's guess.
    var isFromScan: Bool

    /// "Recommended for Lumen: Day to Night. …".
    func text(appName: String) -> String {
        let lead = String(localized: "Recommended for \(appName): \(template.name).")
        let because = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return because.isEmpty ? lead : lead + " " + because
    }

    /// AppLocalizer's guess from `categories`, until Claude Code scans the
    /// project.
    static func guess(categories: [String], client: String) -> AutopilotHeaderRecommendation {
        let template = AutopilotHeaderTemplate.guess(categories: categories)
        let category = categories.first.map { String(localized: "It suits \($0) apps.") } ?? ""
        let reason = [category, String(localized: "\(client) gives its own reason once it has read the project.")]
            .filter { !$0.isEmpty }.joined(separator: " ")
        return AutopilotHeaderRecommendation(template: template, reason: reason, isFromScan: false)
    }
}
