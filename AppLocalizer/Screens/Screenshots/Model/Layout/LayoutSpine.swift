//
//  LayoutSpine.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The folded iPhone Duo's hinge, down the left side of the phone, in
/// canvas pixels. Apple's cover-display mask (the iPhone Duo simulator's)
/// is square on that side and round only on the side it opens from, so
/// the body and the screen are drawn that way, with the spine standing
/// out past the body. Always on the left: the capture is never mirrored.
struct LayoutSpine: Hashable, Sendable {
    /// How wide the hinge is.
    var width: CGFloat
    /// How far it stands out past the body's left edge.
    var overhang: CGFloat
    /// The body's corner radius on the hinge side.
    var bodyCornerRadius: CGFloat
    /// The screen's corner radius on the hinge side.
    var screenCornerRadius: CGFloat
}
