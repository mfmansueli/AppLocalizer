//
//  LayoutPanorama.swift
//  AppLocalizer
//

import Foundation

/// A panorama background: one picture `slotCount` canvases wide, of which
/// this slot shows the window from `slot × canvas width`. Mirrored in
/// right-to-left locales, keeping the slot order, so it still continues
/// as people swipe.
struct LayoutPanorama: Hashable, Sendable {
    var stops: [TemplateColor]
    var slotCount: Int
    var slot: Int
    var isMirrored: Bool
}
