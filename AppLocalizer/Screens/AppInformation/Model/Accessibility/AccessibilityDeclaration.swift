//
//  AccessibilityDeclaration.swift
//  AppLocalizer
//

import Foundation

/// One `accessibilityDeclarations` resource: a family's label as a draft or
/// as published.
struct AccessibilityDeclaration: Identifiable, Hashable, Sendable {
    /// The resource ID.
    let id: String
    var family: DeviceFamily
    var state: AccessibilityDeclarationState
    var answer: AccessibilityAnswer
}
