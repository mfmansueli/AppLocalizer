//
//  TemplateRightToLeft.swift
//  AppLocalizer
//

import Foundation

/// `rtl`: with `mirror` on, Arabic and Hebrew flip the layout (device
/// offsets, start-aligned caption boxes, the panorama). Captures are
/// never mirrored: they're the real interface, which mirrors itself.
struct TemplateRightToLeft: Codable, Hashable, Sendable {
    var mirror: Bool
}
