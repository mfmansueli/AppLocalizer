//
//  AccessibilityDeclarationState.swift
//  AppLocalizer
//

import Foundation

/// A declaration's state in App Store Connect. Publishing a draft makes it
/// published and the older published one replaced.
enum AccessibilityDeclarationState: String, Hashable, Sendable {
    case draft = "DRAFT"
    case published = "PUBLISHED"
    case replaced = "REPLACED"
}
