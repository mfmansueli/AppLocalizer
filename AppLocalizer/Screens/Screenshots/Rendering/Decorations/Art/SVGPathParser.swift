//
//  SVGPathParser.swift
//  AppLocalizer
//

import SwiftUI

/// Turns SVG path data (`d`) into a `Path`, the way the design writes its
/// shapes and props: every command (M, L, H, V, C, S, Q, T, A and Z), in
/// absolute and relative form, with commas or spaces, repeated arguments
/// and numbers written against their command ("h6", "a3.3"). Arcs become
/// cubic Béziers of at most 90° each. Data it can't read ends the path
/// there.
enum SVGPathParser {
    static func path(_ data: String) -> Path {
        var parser = Parser(tokens: tokenize(data))
        return parser.run()
    }

    private enum Token: Equatable {
        case command(Character)
        case number(CGFloat)
    }

    private static func tokenize(_ data: String) -> [Token] {
        var tokens: [Token] = []
        var number = ""
        func flush() {
            if let value = Double(number) { tokens.append(.number(CGFloat(value))) }
            number = ""
        }
        for character in data {
            switch character {
            case "0"..."9":
                number.append(character)
            case ".":
                // A second point starts the next number: "0.5.5" is 0.5 0.5.
                if number.contains("."), !number.lowercased().contains("e") { flush() }
                number.append(character)
            case "-", "+":
                if let last = number.last, last == "e" || last == "E" {
                    number.append(character)
                } else {
                    flush()
                    number.append(character)
                }
            case "e", "E":
                number.append(character)
            case _ where character.isLetter:
                flush()
                tokens.append(.command(character))
            default:
                flush()
            }
        }
        flush()
        return tokens
    }

    private struct Parser {
        let tokens: [Token]
        var index = 0
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero
        /// The last cubic's second control point, for S.
        var lastCubic: CGPoint?
        /// The last quadratic's control point, for T.
        var lastQuad: CGPoint?

        init(tokens: [Token]) {
            self.tokens = tokens
        }

        mutating func run() -> Path {
            var command: Character?
            while index < tokens.count {
                if case let .command(next) = tokens[index] {
                    command = next
                    index += 1
                    if next == "Z" || next == "z" {
                        closePath()
                        continue
                    }
                }
                guard let active = command, perform(active) else { break }
                // After a moveto, repeated pairs are linetos.
                if active == "M" { command = "L" } else if active == "m" { command = "l" }
            }
            return path
        }

        private mutating func closePath() {
            path.closeSubpath()
            current = start
            lastCubic = nil
            lastQuad = nil
        }

        private mutating func numbers(_ count: Int) -> [CGFloat]? {
            guard index + count <= tokens.count else { return nil }
            var values: [CGFloat] = []
            for offset in 0..<count {
                guard case let .number(value) = tokens[index + offset] else { return nil }
                values.append(value)
            }
            index += count
            return values
        }

        private func point(_ x: CGFloat, _ y: CGFloat, relative: Bool) -> CGPoint {
            relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        /// One command's arguments; false when they're missing.
        private mutating func perform(_ command: Character) -> Bool {
            let relative = command.isLowercase
            guard let name = command.uppercased().first, let count = Self.argumentCounts[name], let values = numbers(count) else { return false }
            switch name {
            case "M": move(to: point(values[0], values[1], relative: relative))
            case "L": line(to: point(values[0], values[1], relative: relative))
            case "H": line(to: CGPoint(x: relative ? current.x + values[0] : values[0], y: current.y))
            case "V": line(to: CGPoint(x: current.x, y: relative ? current.y + values[0] : values[0]))
            case "C":
                cubic(
                    point(values[0], values[1], relative: relative), point(values[2], values[3], relative: relative),
                    to: point(values[4], values[5], relative: relative)
                )
            case "S":
                cubic(reflected(lastCubic), point(values[0], values[1], relative: relative), to: point(values[2], values[3], relative: relative))
            case "Q": quad(point(values[0], values[1], relative: relative), to: point(values[2], values[3], relative: relative))
            case "T": quad(reflected(lastQuad), to: point(values[0], values[1], relative: relative))
            default:
                let radii = CGSize(width: values[0], height: values[1])
                arc(radii: radii, rotation: values[2], large: values[3] != 0, sweep: values[4] != 0, to: point(values[5], values[6], relative: relative))
            }
            return true
        }

        /// How many numbers each command takes.
        private static let argumentCounts: [Character: Int] = ["M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7]

        /// The last control point mirrored about the current point, for S
        /// and T; the current point when there's none.
        private func reflected(_ control: CGPoint?) -> CGPoint {
            control.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
        }

        private mutating func move(to point: CGPoint) {
            current = point
            start = point
            path.move(to: point)
            lastCubic = nil
            lastQuad = nil
        }

        private mutating func line(to end: CGPoint) {
            path.addLine(to: end)
            current = end
            lastCubic = nil
            lastQuad = nil
        }

        private mutating func cubic(_ first: CGPoint, _ second: CGPoint, to end: CGPoint) {
            path.addCurve(to: end, control1: first, control2: second)
            current = end
            lastCubic = second
            lastQuad = nil
        }

        private mutating func quad(_ control: CGPoint, to end: CGPoint) {
            path.addQuadCurve(to: end, control: control)
            current = end
            lastQuad = control
            lastCubic = nil
        }

        /// SVG's endpoint arc (implementation notes F.6.5–F.6.6), as cubics.
        private mutating func arc(radii: CGSize, rotation: CGFloat, large: Bool, sweep: Bool, to end: CGPoint) {
            let from = current
            guard radii.width != 0, radii.height != 0, from != end else {
                line(to: end)
                return
            }
            let ellipse = ArcEllipse(from: from, to: end, radii: radii, rotation: rotation, large: large, sweep: sweep)
            let segments = max(1, Int((abs(ellipse.sweepAngle) / (.pi / 2)).rounded(.up)))
            let step = ellipse.sweepAngle / CGFloat(segments)
            let handle = 4 / 3 * tan(step / 4)
            var angle = ellipse.startAngle
            for segment in 0..<segments {
                let next = angle + step
                let segmentStart = ellipse.point(at: angle)
                let segmentEnd = segment == segments - 1 ? end : ellipse.point(at: next)
                let startTangent = ellipse.tangent(at: angle)
                let endTangent = ellipse.tangent(at: next)
                path.addCurve(
                    to: segmentEnd,
                    control1: CGPoint(x: segmentStart.x + handle * startTangent.dx, y: segmentStart.y + handle * startTangent.dy),
                    control2: CGPoint(x: segmentEnd.x - handle * endTangent.dx, y: segmentEnd.y - handle * endTangent.dy)
                )
                angle = next
            }
            current = end
            lastCubic = nil
            lastQuad = nil
        }
    }

    /// An arc's ellipse in center form: its radii (scaled up when too
    /// small to reach the end point), rotation, center, and the angles it
    /// starts at and sweeps through.
    private struct ArcEllipse {
        var radiusX: CGFloat
        var radiusY: CGFloat
        var cosine: CGFloat
        var sine: CGFloat
        var center = CGPoint.zero
        var startAngle: CGFloat = 0
        var sweepAngle: CGFloat = 0

        init(from: CGPoint, to end: CGPoint, radii: CGSize, rotation: CGFloat, large: Bool, sweep: Bool) {
            radiusX = abs(radii.width)
            radiusY = abs(radii.height)
            let angle = rotation * .pi / 180
            cosine = cos(angle)
            sine = sin(angle)
            let halfX = (from.x - end.x) / 2
            let halfY = (from.y - end.y) / 2
            let primeX = cosine * halfX + sine * halfY
            let primeY = -sine * halfX + cosine * halfY
            let lambda = (primeX * primeX) / (radiusX * radiusX) + (primeY * primeY) / (radiusY * radiusY)
            if lambda > 1 {
                radiusX *= sqrt(lambda)
                radiusY *= sqrt(lambda)
            }
            let squaredX = radiusX * radiusX
            let squaredY = radiusY * radiusY
            let numerator = squaredX * squaredY - squaredX * primeY * primeY - squaredY * primeX * primeX
            let denominator = squaredX * primeY * primeY + squaredY * primeX * primeX
            var factor = denominator == 0 ? 0 : sqrt(max(0, numerator / denominator))
            if large == sweep { factor = -factor }
            let centerX = factor * radiusX * primeY / radiusY
            let centerY = -factor * radiusY * primeX / radiusX
            center = CGPoint(
                x: cosine * centerX - sine * centerY + (from.x + end.x) / 2,
                y: sine * centerX + cosine * centerY + (from.y + end.y) / 2
            )
            startAngle = atan2((primeY - centerY) / radiusY, (primeX - centerX) / radiusX)
            sweepAngle = atan2((-primeY - centerY) / radiusY, (-primeX - centerX) / radiusX) - startAngle
            if sweep, sweepAngle < 0 { sweepAngle += 2 * .pi }
            if !sweep, sweepAngle > 0 { sweepAngle -= 2 * .pi }
        }

        func point(at angle: CGFloat) -> CGPoint {
            let localX = radiusX * cos(angle)
            let localY = radiusY * sin(angle)
            return CGPoint(x: center.x + cosine * localX - sine * localY, y: center.y + sine * localX + cosine * localY)
        }

        /// The derivative of `point(at:)`.
        func tangent(at angle: CGFloat) -> CGVector {
            let localX = -radiusX * sin(angle)
            let localY = radiusY * cos(angle)
            return CGVector(dx: cosine * localX - sine * localY, dy: sine * localX + cosine * localY)
        }
    }
}
