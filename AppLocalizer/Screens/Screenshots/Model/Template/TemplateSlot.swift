//
//  TemplateSlot.swift
//  AppLocalizer
//

import Foundation

/// `slots[i]`: one screenshot position. `over` maps dotted template
/// paths to values for this slot only; removing a key returns it to the
/// template's value.
struct TemplateSlot: Codable, Hashable, Sendable {
    var layout: Layout
    var over: [String: JSONValue]

    init(layout: Layout = .standard, over: [String: JSONValue] = [:]) {
        self.layout = layout
        self.over = over
    }

    /// Hero: headline ×1.06, room for a subhead, device ×0.96. Slot 1
    /// is hero by default.
    enum Layout: String, Codable, Hashable, Sendable, CaseIterable {
        case standard
        case hero
    }
}
