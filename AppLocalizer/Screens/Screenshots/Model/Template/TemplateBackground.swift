//
//  TemplateBackground.swift
//  AppLocalizer
//

import Foundation

/// `bg`: a solid color, a linear gradient (two stops and an angle), an
/// uploaded image, or a panorama that spans every slot (slot i shows
/// the window from i × canvas width).
struct TemplateBackground: Codable, Hashable, Sendable {
    var kind: Kind
    /// Degrees, CSS-style (0 points up, 90 right); linear only.
    var angle: Double?
    /// Hex colors, e.g. `#7A80FF`.
    var stops: [String]
    /// An uploaded asset's id; `image` only.
    var image: String?

    enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
        case solid
        case linear
        case image
        case panorama
    }
}
