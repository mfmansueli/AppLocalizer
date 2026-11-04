//
//  ArtworkSafeArea+MCP.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The safe area as the design source reads it in `get_design_brief` and
/// `design_variant`: the rectangle in the canvas's pixels, and what covers
/// or crops the rest.
extension ArtworkSafeArea {
    static func mcpJSON(for kind: AutopilotArtworkKind) -> JSONValue {
        let rect = rect(for: kind)
        return [
            "x": .int(Int(rect.minX)), "y": .int(Int(rect.minY)),
            "width": .int(Int(rect.width)), "height": .int(Int(rect.height)),
            "outside": .string(outsideText(for: kind)),
        ]
    }

    /// What happens outside the safe area: "The outer 17% on each side…".
    static func outsideText(for kind: AutopilotArtworkKind) -> String {
        let insets = percentInsets(for: kind)
        switch kind {
        case .header:
            return """
            The outer \(insets.side)% on each side, which iPhone crops (iPad and Mac show it), and the top \(insets.top)%, \
            where the status bar, Back and Share sit over the image. Background only there: no text, logo, face or focal point.
            """
        case .search:
            return """
            Nothing is cropped: the whole image shows, small, beside the app's name and Get, with rounded corners. Keep \
            text and the focal point a little in from the edges and corners.
            """
        case .wide:
            return """
            The outer \(insets.side)% on each side and the top \(insets.top)%, which the header's crop leaves out; search \
            shows it whole. Background only there: no text, logo, face or focal point.
            """
        }
    }

    /// `get_design_brief`'s rule for every canvas.
    static let mcpRule = """
    Each canvas has its safeArea, in its own pixels from the top left: the part every device shows. The app name, the \
    headline and every line of text, the app icon, the phones or screens and the focal point go inside it, with some \
    margin; only the background (color, gradient, texture, the scene) runs to the edges, and it must look finished both \
    cropped and whole. Compose for the safe area, not the canvas: center the focal point in it, not in the canvas. \
    Every language goes in the same space: longer translations (German, Finnish) wrap or shrink, right-to-left ones \
    mirror, so leave room for a line that's about 40% longer. AppLocalizer checks every render in every language and \
    flags any of these that runs outside ("Safe area") before Review & Push.
    """
}
