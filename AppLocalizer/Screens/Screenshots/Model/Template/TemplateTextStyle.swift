//
//  TemplateTextStyle.swift
//  AppLocalizer
//

import Foundation

/// `caption.headline` and `caption.subhead`. Sizes are in u; the
/// caption box is reserved at `maxLines × size × lh`, so the device
/// never moves between locales.
struct TemplateTextStyle: Codable, Hashable, Sendable {
    var font: String
    /// CSS-style weight, 100–900.
    var weight: Int
    var size: Double
    /// The smallest size shrink-to-fit may use; never above `size`.
    var min: Double
    /// Line height as a multiple of the size (`lh` in JSON).
    var lineHeight: Double
    var maxLines: Int
    /// Letter spacing in em, e.g. -0.01.
    var tracking: Double?

    enum CodingKeys: String, CodingKey {
        case font, weight, size, min
        case lineHeight = "lh"
        case maxLines, tracking
    }
}
