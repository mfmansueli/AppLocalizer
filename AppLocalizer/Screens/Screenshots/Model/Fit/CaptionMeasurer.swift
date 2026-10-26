//
//  CaptionMeasurer.swift
//  AppLocalizer
//

import CoreText
import Foundation

/// Measures caption text with one Core Text font at one size, with the
/// template's tracking, the way the renderer draws it.
struct CaptionMeasurer {
    let font: CTFont
    /// Letter spacing in pixels.
    let tracking: CGFloat

    init(font: CTFont, tracking: CGFloat = 0) {
        self.font = font
        self.tracking = tracking
    }

    /// The typographic width of `text` on one line, in pixels.
    func width(of text: String) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        var attributes: [NSAttributedString.Key: Any] = [.init(kCTFontAttributeName as String): font]
        if tracking != 0 { attributes[.init(kCTKernAttributeName as String)] = tracking }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }
}
