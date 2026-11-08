//
//  TemplateDevice.swift
//  AppLocalizer
//

import Foundation

/// `device`: the frame around the capture when the caption sits above or
/// below it.
struct TemplateDevice: Codable, Hashable, Sendable {
    var show: Bool
    /// Fraction of the canvas width, 0.6–0.9. In landscape it shrinks to
    /// fit the height left under the caption.
    var width: Double
    /// The frame's finish, a hex color.
    var color: String
    /// Horizontal offset as a fraction of the canvas width, alternating
    /// per slot and mirrored in right-to-left locales.
    var offset: Double
    /// How far the frame may run past the bottom edge, as a fraction of
    /// the canvas height.
    var bleed: Double
    /// Rotate, turn and lean back; flat when left out.
    var tilt: TemplateTilt?
    /// Extra shift right (`dx`), as a fraction of the canvas width, on top
    /// of `offset`. Mirrored in right-to-left locales.
    var shiftRight: Double?
    /// Extra shift down (`dy`), as a fraction of the canvas height.
    var shiftDown: Double?
    /// Pins the frame's top edge at this fraction of the canvas height
    /// instead of following the caption box, with the caption above it.
    /// A language that needs more room pushes it down just enough: it
    /// never overlaps the caption.
    var top: Double?
    /// What an empty screen (no capture yet) shows (`empty`). Every
    /// template draws a switched-off black screen now, so `black` is also
    /// what leaving it out means; templates that say so still read.
    var emptyScreen: EmptyScreen?
    /// The phone behind on a Two phones slot (`slots[i].layout: pair`).
    var pair: TemplateDevicePair?

    enum CodingKeys: String, CodingKey {
        case show, width, color, offset, bleed, tilt
        case shiftRight = "dx"
        case shiftDown = "dy"
        case top
        case emptyScreen = "empty"
        case pair
    }

    enum EmptyScreen: String, Codable, Hashable, Sendable, CaseIterable {
        case black
    }

    /// The screen color where there's no capture yet: black, set or not.
    var emptyScreenColor: TemplateColor {
        switch emptyScreen {
        case .black, nil: .black
        }
    }
}
