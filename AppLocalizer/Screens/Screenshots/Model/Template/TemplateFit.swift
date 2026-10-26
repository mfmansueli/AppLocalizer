//
//  TemplateFit.swift
//  AppLocalizer
//

import Foundation

/// `fit`: whether captions shrink (2 u at a time, down to their `min`)
/// and whether words wider than the box are hyphenated.
struct TemplateFit: Codable, Hashable, Sendable {
    var shrink: Bool
    var hyphenate: Bool
}
