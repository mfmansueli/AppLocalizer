//
//  TemplateRefusal.swift
//  AppLocalizer
//

import Foundation

/// Why one operation (or the template it would make) was refused, worded
/// so an assistant can fix its proposal and send it again.
struct TemplateRefusal: Error, Hashable, Sendable, Codable {
    var path: String
    var kind: Kind
    var reason: String

    enum Kind: String, Hashable, Sendable, Codable {
        /// Not a template field, or one AppLocalizer sets itself.
        case unknownPath
        /// Not `replace`.
        case unsupportedOperation
        /// The wrong type for the field, e.g. text for a number.
        case wrongType
        /// Outside the field's range or choices.
        case outOfRange
        /// A font that isn't installed.
        case unknownFont
        /// A fallback font that can't draw its script.
        case fontCantDrawScript
        /// Fields that contradict each other, e.g. `min` above `size`.
        case inconsistent
        /// A slot that doesn't exist.
        case unknownSlot
        /// Based on an older version than the current one; it has to be
        /// rebased first.
        case stale
    }
}
