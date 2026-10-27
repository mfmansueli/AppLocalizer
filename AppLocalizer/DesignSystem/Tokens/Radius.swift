//
//  Radius.swift
//  AppLocalizer
//

import CoreGraphics

/// Corner radii from the design handoff. Buttons, segmented controls and
/// pills are capsules; windows use the system's radius.
enum Radius {
    static let flag: CGFloat = 3
    static let badge: CGFloat = 5
    /// Text fields and keyword tokens.
    static let field: CGFloat = 7
    /// Banners and menus.
    static let banner: CGFloat = 10
    static let card: CGFloat = 12
    static let popover: CGFloat = 14
    static let sheet: CGFloat = 18
}
