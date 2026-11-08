//
//  DecorationArtPart.swift
//  AppLocalizer
//

import SwiftUI

/// One part of a prop: an outline in the prop's view box, filled and/or
/// stroked, at its own opacity.
struct DecorationArtPart: Sendable {
    var path: Path
    var fill: Paint?
    var stroke: Paint?
    /// In view box units.
    var strokeWidth: CGFloat
    var opacity: Double

    /// A part from its SVG path data.
    init(_ data: String, fill: Paint? = nil, stroke: Paint? = nil, strokeWidth: CGFloat = 0, opacity: Double = 1) {
        path = SVGPathParser.path(data)
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.opacity = opacity
    }

    /// A part's own color, or the decoration's (`tint`).
    enum Paint: Sendable, Equatable {
        case tint
        case color(String)

        func color(tint: TemplateColor) -> TemplateColor {
            switch self {
            case .tint: tint
            case let .color(text): TemplateColor(text) ?? tint
            }
        }
    }
}
