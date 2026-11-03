//
//  ArtworkContrast.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// WCAG contrast between colors, and the colors that meet on the artwork:
/// the background behind a line of text, and the App Store page the image
/// sits on, white in Light Mode and black in Dark Mode.
enum ArtworkContrast {
    /// Large text reads at 3:1 (WCAG AA); headlines here are large, but
    /// the search card is small, so below this is a warning.
    static let minimumTextRatio = 3.0
    /// Edges closer to the page than this melt into it.
    static let minimumEdgeRatio = 1.2

    static let lightPage = TemplateColor.white
    static let darkPage = TemplateColor.black

    /// Relative luminance, 0–1, of an opaque sRGB color.
    static func luminance(_ color: TemplateColor) -> Double {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// 1:1 to 21:1.
    static func ratio(_ first: TemplateColor, _ second: TemplateColor) -> Double {
        let (one, other) = (luminance(first), luminance(second))
        return (max(one, other) + 0.05) / (min(one, other) + 0.05)
    }

    /// `color` drawn over `behind`, by its alpha.
    static func over(_ color: TemplateColor, _ behind: TemplateColor) -> TemplateColor {
        let alpha = min(max(color.alpha, 0), 1)
        return TemplateColor(
            red: color.red * alpha + behind.red * (1 - alpha), green: color.green * alpha + behind.green * (1 - alpha),
            blue: color.blue * alpha + behind.blue * (1 - alpha)
        )
    }

    /// The background's color at `point` of an artwork of `size`: a
    /// gradient's at that point along its line.
    static func color(of background: LayoutBackground, at point: CGPoint, in size: CGSize) -> TemplateColor {
        switch background {
        case let .solid(color):
            return color
        case let .panorama(panorama):
            return panorama.stops.first ?? .black
        case let .linear(angle, stops):
            guard stops.count > 1 else { return stops.first ?? .black }
            let (start, end) = ScreenshotPainter.gradientPoints(angle: angle, in: CGRect(origin: .zero, size: size))
            let line = CGVector(dx: end.x - start.x, dy: end.y - start.y)
            let length = line.dx * line.dx + line.dy * line.dy
            let along = length > 0 ? ((point.x - start.x) * line.dx + (point.y - start.y) * line.dy) / length : 0
            let position = min(max(Double(along), 0), 1) * Double(stops.count - 1)
            let index = min(Int(position), stops.count - 2)
            let fraction = position - Double(index)
            let (from, next) = (stops[index], stops[index + 1])
            return TemplateColor(
                red: from.red + (next.red - from.red) * fraction, green: from.green + (next.green - from.green) * fraction,
                blue: from.blue + (next.blue - from.blue) * fraction, alpha: from.alpha + (next.alpha - from.alpha) * fraction
            )
        }
    }

    /// How far apart two colors are, 0 (same) to √3, in sRGB.
    static func distance(_ first: TemplateColor, _ second: TemplateColor) -> Double {
        let red = first.red - second.red
        let green = first.green - second.green
        let blue = first.blue - second.blue
        return (red * red + green * green + blue * blue).squareRoot()
    }
}
