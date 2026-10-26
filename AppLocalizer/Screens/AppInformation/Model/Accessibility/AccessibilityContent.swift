//
//  AccessibilityContent.swift
//  AppLocalizer
//

import Foundation

/// The Accessibility page's data from App Store Connect: each family's
/// draft and published declaration, which families have a live version
/// (only those can publish), and the app's accessibility URL.
struct AccessibilityContent: Hashable, Sendable {
    /// The families the app runs on, in the cards' order.
    var families: [DeviceFamily]
    /// Families with a live version on their platform, including ones
    /// without a card yet.
    var liveFamilies: Set<DeviceFamily>
    /// Draft and published declarations; replaced ones are left out.
    var declarations: [AccessibilityDeclaration]
    var accessibilityURL: String
    /// The version being prepared, for "until 1.4 is released"; nil when
    /// there's none.
    var upcomingVersion: String?

    func declaration(for family: DeviceFamily, state: AccessibilityDeclarationState) -> AccessibilityDeclaration? {
        declarations.first { $0.family == family && $0.state == state }
    }

    /// The families from versions' platforms plus any with a declaration,
    /// in the cards' order.
    static func families(platforms: [String?], declared: [DeviceFamily]) -> [DeviceFamily] {
        let found = Set(platforms.flatMap { DeviceFamily.families(forPlatform: $0) } + declared)
        return DeviceFamily.allCases.filter(found.contains)
    }
}
