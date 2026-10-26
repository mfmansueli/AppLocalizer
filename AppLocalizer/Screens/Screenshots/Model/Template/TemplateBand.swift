//
//  TemplateBand.swift
//  AppLocalizer
//

import Foundation

/// `caption.band`: the bar a band placement draws the caption on.
struct TemplateBand: Codable, Hashable, Sendable {
    var color: String
    /// Hero slots always put it at the top.
    var pos: Position

    enum Position: String, Codable, Hashable, Sendable, CaseIterable {
        case top
        case bottom
    }
}
