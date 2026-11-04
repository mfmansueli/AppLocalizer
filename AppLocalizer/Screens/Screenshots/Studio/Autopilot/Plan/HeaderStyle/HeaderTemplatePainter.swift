//
//  HeaderTemplatePainter.swift
//  AppLocalizer
//

import SwiftUI

/// Draws a scene template at `phase` of its loop (0–1): what the plan's
/// tile shows of it, simply, in two colors and white.
struct HeaderTemplatePainter {
    let template: AutopilotHeaderTemplate
    let light: Color
    let dark: Color
    let phase: Double

    /// 0 at day, 1 at night, back to 0: the light the loop moves through.
    private var night: Double { (1 - cos(phase * 2 * .pi)) / 2 }

    func draw(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let unit = size.width / 100
        context.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [dark.mix(with: .black, by: 0.2 + 0.4 * night), light.mix(with: .white, by: 0.25 * (1 - night))]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
        ))
        switch template {
        case .night: drawNight(in: &context, size: size, unit: unit)
        case .land: drawLand(in: &context, size: size, unit: unit)
        case .window: drawWindow(in: &context, size: size, unit: unit)
        case .horizon: drawHorizon(in: &context, size: size, unit: unit)
        case .hero: drawHero(in: &context, size: size, unit: unit)
        case .pattern: drawPattern(in: &context, size: size, unit: unit)
        }
        // Where the name goes: centered, its middle at about 55%.
        let name = CGRect(x: size.width * 0.35, y: size.height * 0.55 - 2.6 * unit, width: size.width * 0.3, height: 5.2 * unit)
        context.fill(Path(roundedRect: name, cornerRadius: 1.2 * unit), with: .color(.white.opacity(0.92)))
    }

    private func drawNight(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        // Stars come out at night.
        for index in 0..<14 {
            let x = CGFloat((index * 37) % 100) * unit
            let y = CGFloat((index * 13) % 30 + 4) * size.height / 100
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.8 * unit, height: 0.8 * unit)), with: .color(.white.opacity(0.8 * night)))
        }
        // The sun or moon arcs across the sky, clear of the name.
        let angle = phase * .pi
        let center = CGPoint(x: size.width * (0.12 + 0.76 * phase), y: size.height * (0.42 - 0.26 * sin(angle)))
        let body = CGRect(x: center.x - 4 * unit, y: center.y - 4 * unit, width: 8 * unit, height: 8 * unit)
        context.fill(Path(ellipseIn: body), with: .color(Color(red: 1, green: 0.95, blue: 0.82)))
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: size.height))
        hills.addLine(to: CGPoint(x: 0, y: size.height * 0.82))
        hills.addCurve(
            to: CGPoint(x: size.width, y: size.height * 0.8),
            control1: CGPoint(x: size.width * 0.3, y: size.height * 0.7), control2: CGPoint(x: size.width * 0.7, y: size.height * 0.9)
        )
        hills.addLine(to: CGPoint(x: size.width, y: size.height))
        context.fill(hills, with: .color(dark.mix(with: .black, by: 0.5)))
    }

    private func drawLand(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        for layer in 0..<4 {
            let depth = CGFloat(layer)
            let drift = CGFloat(sin(phase * 2 * .pi)) * (1 + depth) * 1.5 * unit
            let top = size.height * (0.6 + 0.09 * depth)
            var path = Path()
            path.move(to: CGPoint(x: -10 * unit, y: size.height))
            path.addLine(to: CGPoint(x: -10 * unit + drift, y: top))
            for step in 0...6 {
                let x = -10 * unit + drift + CGFloat(step) * 20 * unit
                path.addQuadCurve(
                    to: CGPoint(x: x + 20 * unit, y: top), control: CGPoint(x: x + 10 * unit, y: top - (6 - depth) * unit)
                )
            }
            path.addLine(to: CGPoint(x: size.width + 20 * unit, y: size.height))
            context.fill(path, with: .color(dark.mix(with: .black, by: 0.15 + 0.15 * depth).opacity(0.9)))
        }
    }

    private func drawWindow(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        let frame = CGRect(x: size.width * 0.3, y: size.height * 0.12, width: size.width * 0.4, height: size.height * 0.8)
        // The outside: a moon beyond the glass at night.
        let moon = CGRect(x: frame.maxX - 10 * unit, y: frame.minY + 3 * unit, width: 5 * unit, height: 5 * unit)
        context.fill(Path(ellipseIn: moon), with: .color(Color(red: 1, green: 0.95, blue: 0.82).opacity(0.3 + 0.7 * night)))
        // The room around the window.
        var room = Path(CGRect(origin: .zero, size: size))
        room.addPath(Path(roundedRect: frame, cornerRadius: 3 * unit))
        context.fill(room, with: .color(dark.mix(with: .black, by: 0.45)), style: FillStyle(eoFill: true))
        context.stroke(Path(roundedRect: frame, cornerRadius: 3 * unit), with: .color(light.mix(with: .white, by: 0.3)), lineWidth: 1.4 * unit)
        context.stroke(
            Path { $0.move(to: CGPoint(x: frame.midX, y: frame.minY)); $0.addLine(to: CGPoint(x: frame.midX, y: frame.minY + frame.height * 0.3)) },
            with: .color(light.mix(with: .white, by: 0.3)), lineWidth: 0.8 * unit
        )
    }

    private func drawHorizon(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        let line = size.height * 0.68
        context.fill(Path(CGRect(x: 0, y: line, width: size.width, height: size.height - line)), with: .color(dark.mix(with: .black, by: 0.35)))
        for index in 0..<5 {
            let y = line + CGFloat(index + 1) * 2.4 * unit
            let shift = CGFloat(sin(phase * 2 * .pi + Double(index))) * 3 * unit
            context.fill(
                Path(roundedRect: CGRect(x: size.width * 0.62 + shift, y: y, width: 9 * unit, height: 0.5 * unit), cornerRadius: 0.25 * unit),
                with: .color(.white.opacity(0.35))
            )
        }
        // Something passing: leaves on the right, comes back on the left.
        let x = (CGFloat(phase) * 1.3 - 0.15) * size.width
        var boat = Path()
        boat.move(to: CGPoint(x: x - 3 * unit, y: line - 0.2 * unit))
        boat.addLine(to: CGPoint(x: x + 3 * unit, y: line - 0.2 * unit))
        boat.addLine(to: CGPoint(x: x + 2 * unit, y: line + 1.2 * unit))
        boat.addLine(to: CGPoint(x: x - 2 * unit, y: line + 1.2 * unit))
        boat.closeSubpath()
        boat.addPath(Path(CGRect(x: x - 0.2 * unit, y: line - 4 * unit, width: 0.4 * unit, height: 3.8 * unit)))
        context.fill(boat, with: .color(.white.opacity(0.85)))
    }

    private func drawHero(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        let disc = CGRect(x: size.width * 0.5 - 22 * unit, y: size.height * 0.5 - 22 * unit, width: 44 * unit, height: 44 * unit)
        var crescent = Path(ellipseIn: disc)
        crescent.addPath(Path(ellipseIn: disc.offsetBy(dx: 10 * unit, dy: -5 * unit)))
        context.fill(crescent, with: .color(light.opacity(0.35)), style: FillStyle(eoFill: true))
        // A soft light sweeps across it.
        let sweep = CGFloat(phase) * size.width * 1.4 - size.width * 0.2
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [.clear, .white.opacity(0.18), .clear]),
            startPoint: CGPoint(x: sweep - 12 * unit, y: 0), endPoint: CGPoint(x: sweep + 12 * unit, y: size.height)
        ))
    }

    private func drawPattern(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        let shapes: [(CGFloat, CGFloat, CGFloat)] = [(12, 20, 14), (30, 70, 9), (72, 18, 11), (86, 62, 16), (55, 85, 7), (8, 75, 6), (64, 40, 5)]
        for (index, shape) in shapes.enumerated() {
            let drift = CGFloat(sin(phase * 2 * .pi + Double(index))) * 2 * unit
            let rect = CGRect(x: shape.0 * unit + drift, y: shape.1 * size.height / 100 - shape.2 * unit / 2, width: shape.2 * unit, height: shape.2 * unit)
            let color = index.isMultiple(of: 2) ? light.mix(with: .white, by: 0.2) : dark.mix(with: .white, by: 0.15)
            context.fill(Path(roundedRect: rect, cornerRadius: shape.2 * unit * (index.isMultiple(of: 3) ? 0.5 : 0.25)), with: .color(color.opacity(0.55)))
        }
    }
}
