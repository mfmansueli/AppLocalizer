//
//  LayoutDevice.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The generic device frame around the capture, in canvas pixels. It's
/// drawn from shapes, not Apple's bezels: a rounded body in the template's
/// finish, a thin rim, the screen and, on iPhone, the Dynamic Island. On
/// Mac the body is a MacBook's lid, with its base under it.
struct LayoutDevice: Hashable, Sendable {
    var frame: CGRect
    var cornerRadius: CGFloat
    var bezel: CGFloat
    var color: TemplateColor
    /// The island, in canvas pixels; nil on iPad.
    var island: CGRect?
    var shadowOffset: CGFloat
    var shadowRadius: CGFloat
    /// The device's angle; nil when it stands flat.
    var tilt: LayoutTilt?
    /// A MacBook's base under the lid (`frame`), wider than it; nil on
    /// every other device.
    var base: CGRect?
    /// The folded iPhone Duo's hinge; nil on every other device, and on
    /// the unfolded Duo.
    var spine: LayoutSpine?

    var isLaptop: Bool { base != nil }
}
