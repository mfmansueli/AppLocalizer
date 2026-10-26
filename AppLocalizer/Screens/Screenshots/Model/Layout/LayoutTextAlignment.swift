//
//  LayoutTextAlignment.swift
//  AppLocalizer
//

import Foundation

/// Where a caption line sits in its box, in canvas terms: `start`
/// alignment is left in English and right in Arabic.
enum LayoutTextAlignment: String, Hashable, Sendable {
    case left
    case center
    case right
}
