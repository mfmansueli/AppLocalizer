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
    /// is hero by default. Two phones (`pair`): the slot's own capture in
    /// front and the slot before it's capture behind, higher up and
    /// partly off the edge (`device.pair` places it); portrait only.
    /// Reviews (`quotes`): no device, three real 5-star App Store reviews
    /// in the slot's language under the headline.
    enum Layout: String, Codable, Hashable, Sendable, CaseIterable {
        case standard
        case hero
        case pair
        case quotes
    }
}
