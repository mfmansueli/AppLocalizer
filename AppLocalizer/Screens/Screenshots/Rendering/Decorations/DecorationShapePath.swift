//
//  DecorationShapePath.swift
//  AppLocalizer
//

import SwiftUI

/// The outlines decorations are drawn from, as the design writes them: SVG
/// paths in a 100 × 100 box, stretched to the decoration's frame (no aspect
/// ratio kept) and free to run past it. Only absolute M, L, C and Z occur.
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
        case .sparkle: "M50 0 C53 36 64 47 100 50 C64 53 53 64 50 100 C47 64 36 53 0 50 C36 47 47 36 50 0 Z"
        case .blob: "M22 8 C46 -6 86 4 96 34 C106 64 82 96 50 96 C20 96 -4 76 4 46 C8 28 6 17 22 8 Z"
        case .swoosh: "M0 64 C22 30 42 92 64 58 C78 36 88 16 100 6 L100 30 C90 38 82 54 72 72 C50 112 24 64 0 92 Z"
        case .wave: "M0 46 C20 28 40 64 62 44 C78 30 90 34 100 26 L100 100 L0 100 Z"
        case .arc: "M0 0 L100 0 L100 18 C56 18 18 56 18 100 L0 100 Z"
        case .petal:
            "M50 50 C34 30 30 4 50 4 C70 4 66 30 50 50 C70 34 96 30 96 50 C96 70 70 66 50 50 C66 70 70 96 50 96 "
                + "C30 96 34 70 50 50 C30 66 4 70 4 50 C4 30 30 34 50 50 Z"
        case .circle: ""
        case .chevrons: "M0 20 L22 20 L52 50 L22 80 L0 80 L30 50 Z M44 20 L66 20 L96 50 L66 80 L44 80 L74 50 Z"
        }
    }

    /// A path from absolute M, L, C and Z commands.
    static func parse(_ text: String) -> Path {
        var path = Path()
        var command: Character = "M"
        var numbers: [CGFloat] = []
        func flush() {
            switch command {
            case "M" where numbers.count >= 2: path.move(to: CGPoint(x: numbers[0], y: numbers[1]))
            case "L" where numbers.count >= 2: path.addLine(to: CGPoint(x: numbers[0], y: numbers[1]))
            case "C" where numbers.count >= 6:
                path.addCurve(
                    to: CGPoint(x: numbers[4], y: numbers[5]), control1: CGPoint(x: numbers[0], y: numbers[1]),
                    control2: CGPoint(x: numbers[2], y: numbers[3])
                )
            default: break
            }
            numbers = []
        }
        for token in text.split(separator: " ") {
            var rest = Substring(token)
            if let first = rest.first, first.isLetter {
                flush()
                command = first
                if command == "Z" { path.closeSubpath() }
                rest = rest.dropFirst()
            }
            if let number = Double(rest) { numbers.append(CGFloat(number)) }
            let needed = command == "C" ? 6 : 2
            if numbers.count == needed { flush() }
        }
        flush()
        return path
    }
}
