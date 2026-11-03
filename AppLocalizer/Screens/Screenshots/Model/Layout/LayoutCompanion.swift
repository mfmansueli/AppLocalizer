//
//  LayoutCompanion.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A second screen in the same screenshot: iPhone Duo's cover display,
/// folded, beside the unfolded inner display (both, side by side). It has
/// its own device frame (nil when the template hides devices: it floats
/// then) and its own capture.
struct LayoutCompanion: Hashable, Sendable {
    var device: LayoutDevice?
    var screen: CGRect
    var screenCornerRadius: CGFloat
}
