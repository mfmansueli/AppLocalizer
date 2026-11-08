//
//  TemplateArt.swift
//  AppLocalizer
//

import Foundation

/// The props a decoration of `type: art` draws: multi-color vector stand-ins
/// drawn by the template (never cut out of a reference or a capture), and
/// hand-drawn marks in one color that take the decoration's `color`.
enum TemplateArt: String, Codable, Hashable, Sendable, CaseIterable {
    case controller
    case chess
    case dice
    /// A flat figure to replace with your own artwork; Arcade spans it
    /// across two slots.
    case person
    case underline
    case asterisk
    case arrow
    case corner
    case pointer
    case star

    /// The props that show a subject (a game's controller, chess pieces, a
    /// die, a figure), drawn for a gallery template's sample app; the rest
    /// are marks that suit any app. Bruma's Arcade direction, a dating app,
    /// kept the controller, the chess pieces and the gamer.
    static let subjects: [TemplateArt] = [.controller, .chess, .dice, .person]

    var title: String {
        switch self {
        case .controller: String(localized: "Game controller")
        case .chess: String(localized: "Chess pieces")
        case .dice: String(localized: "Die")
        case .person: String(localized: "Figure")
        case .underline: String(localized: "Underline")
        case .asterisk: String(localized: "Asterisk")
        case .arrow: String(localized: "Curved arrow")
        case .corner: String(localized: "Corner curve")
        case .pointer: String(localized: "Pointer")
        case .star: String(localized: "Star")
        }
    }

    /// Marks in one color take the decoration's color; the multi-color
    /// props keep their own.
    var isTintable: Bool {
        switch self {
        case .controller, .chess, .dice, .person: false
        case .underline, .asterisk, .arrow, .corner, .pointer, .star: true
        }
    }
}
