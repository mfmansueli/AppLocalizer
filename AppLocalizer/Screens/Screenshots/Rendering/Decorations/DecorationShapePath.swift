//
//  DecorationShapePath.swift
//  AppLocalizer
//

import SwiftUI

/// The outlines decorations are drawn from, as the design writes them: SVG
/// paths in a 100 × 100 box, stretched to the decoration's frame (no aspect
/// ratio kept) and free to run past it.
enum DecorationShapePath {
    /// The outline of `shape` in a 100 × 100 box.
    static func path(for shape: TemplateDecoration.Shape) -> Path {
        switch shape {
        case .circle: Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100))
        default: parse(source(for: shape))
        }
    }

    /// The badge's starburst: 36 points alternating between radius 50 and 41.
    static let burst: Path = {
        var path = Path()
        for index in 0..<36 {
            let angle = Double(index) / 36 * .pi * 2 - .pi / 2
            let radius: Double = index.isMultiple(of: 2) ? 50 : 41
            let point = CGPoint(x: 50 + radius * cos(angle), y: 50 + radius * sin(angle))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }()

    /// `path` from its 100 × 100 box into `frame`.
    static func fitted(_ path: Path, in frame: CGRect) -> Path {
        let scale = CGAffineTransform(scaleX: frame.width / 100, y: frame.height / 100)
        return path.applying(scale.concatenating(CGAffineTransform(translationX: frame.minX, y: frame.minY)))
    }

    private static func source(for shape: TemplateDecoration.Shape) -> String {
        switch shape {
        case .sparkle, .blob, .swoosh, .wave, .arc, .petal: organicSource(for: shape)
        case .palm, .thumb, .fingers: handSource(for: shape)
        case .circle: ""
        case .chevrons: "M0 20 L22 20 L52 50 L22 80 L0 80 L30 50 Z M44 20 L66 20 L96 50 L66 80 L44 80 L74 50 Z"
        case .rule: "M0 42 C25 36 60 50 100 40 L100 58 C60 66 25 52 0 60 Z"
        case .moon: "M62 4 C34 8 14 30 14 56 C14 82 36 100 62 100 C78 100 92 92 100 80 C92 84 84 86 76 86 C52 86 34 68 34 46 C34 28 46 12 62 4 Z"
        }
    }

    /// Sparkles, blobs, swooshes, waves, arcs and petals.
    private static func organicSource(for shape: TemplateDecoration.Shape) -> String {
        switch shape {
        case .sparkle: "M50 0 C53 36 64 47 100 50 C64 53 53 64 50 100 C47 64 36 53 0 50 C36 47 47 36 50 0 Z"
        case .blob: "M22 8 C46 -6 86 4 96 34 C106 64 82 96 50 96 C20 96 -4 76 4 46 C8 28 6 17 22 8 Z"
        case .swoosh: "M0 64 C22 30 42 92 64 58 C78 36 88 16 100 6 L100 30 C90 38 82 54 72 72 C50 112 24 64 0 92 Z"
        case .wave: "M0 46 C20 28 40 64 62 44 C78 30 90 34 100 26 L100 100 L0 100 Z"
        case .arc: "M0 0 L100 0 L100 18 C56 18 18 56 18 100 L0 100 Z"
        case .petal:
            "M50 50 C34 30 30 4 50 4 C70 4 66 30 50 50 C70 34 96 30 96 50 C96 70 70 66 50 50 C66 70 70 96 50 96 "
                + "C30 96 34 70 50 50 C30 66 4 70 4 50 C4 30 30 34 50 50 Z"
        default: ""
        }
    }

    /// The hand holding the device: palm, thumb and fingers.
    private static func handSource(for shape: TemplateDecoration.Shape) -> String {
        switch shape {
        case .palm: "M18 100 C14 78 22 54 40 40 C54 30 70 22 84 24 C94 26 100 34 100 44 L100 100 Z"
        case .thumb: "M30 0 C42 0 48 10 46 24 L40 78 C38 92 30 100 18 100 C6 100 0 90 2 78 L12 22 C14 8 20 0 30 0 Z"
        case .fingers:
            "M14 0 L76 4 C90 5 96 14 94 24 C92 32 84 36 74 35 L12 31 C4 30 0 24 0 16 C0 6 6 0 14 0 Z "
                + "M14 36 L80 40 C94 41 100 50 98 60 C96 68 88 72 78 71 L12 67 C4 66 0 60 0 52 C0 42 6 36 14 36 Z "
                + "M16 72 L74 76 C86 77 92 86 90 94 C88 100 80 103 72 102 L14 98 C6 97 2 92 2 86 C2 77 8 72 16 72 Z"
        default: ""
        }
    }

    /// A path from SVG path data.
    static func parse(_ text: String) -> Path {
        SVGPathParser.path(text)
    }
}
