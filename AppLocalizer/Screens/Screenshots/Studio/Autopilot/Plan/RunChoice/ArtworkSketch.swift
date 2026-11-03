//
//  ArtworkSketch.swift
//  AppLocalizer
//

import SwiftUI

/// A small sketch of the header or search artwork beside the plan's
/// choices: where the name and line go, and a phone, a floating screen or
/// a scene, as the search artwork shows.
struct ArtworkSketch: View {
    let kind: AutopilotArtworkKind
    let shows: AutopilotArtworkShow
    let width: CGFloat

    var body: some View {
        let size = kind.pixelSize
        let height = (width * CGFloat(size.height) / CGFloat(size.width)).rounded()
        Canvas { context, canvas in
            draw(in: &context, size: canvas)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [Color(red: 0.17, green: 0.15, blue: 0.41), Color(red: 0.36, green: 0.33, blue: 0.91)]),
            startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)
        ))
        let unit = size.width / 100
        let light = GraphicsContext.Shading.color(.white.opacity(0.9))
        let soft = GraphicsContext.Shading.color(.white.opacity(0.55))
        switch kind {
        case .header:
            centeredName(in: &context, center: size.height * 0.36, unit: unit, size: size, light: light, soft: soft)
        case .wide:
            centeredName(in: &context, center: size.height * 0.16, unit: unit, size: size, light: light, soft: soft)
            switch shows {
            case .phone:
                device(in: &context, rect: CGRect(x: size.width / 2 - 10.5 * unit, y: size.height * 0.5, width: 21 * unit, height: 45 * unit), radius: 3 * unit)
            case .ui:
                device(in: &context, rect: CGRect(x: size.width / 2 - 15 * unit, y: size.height * 0.56, width: 30 * unit, height: 40 * unit), radius: 2 * unit)
            case .scene:
                scene(in: &context, size: size, unit: unit)
            }
        case .search:
            let top = (shows == .scene ? 14 : 9) * unit
            context.fill(Path(roundedRect: CGRect(x: 7 * unit, y: top, width: 34 * unit, height: 6.6 * unit), cornerRadius: unit), with: light)
            context.fill(Path(roundedRect: CGRect(x: 7 * unit, y: top + 9 * unit, width: 26 * unit, height: 6.6 * unit), cornerRadius: unit), with: light)
            switch shows {
            case .phone:
                rotated(in: &context, degrees: -6, rect: CGRect(x: 57 * unit, y: 13 * unit, width: 30 * unit, height: 62 * unit), radius: 4 * unit)
            case .ui:
                rotated(in: &context, degrees: -4, rect: CGRect(x: 55 * unit, y: 11 * unit, width: 36 * unit, height: 56 * unit), radius: 2 * unit)
            case .scene:
                scene(in: &context, size: size, unit: unit)
            }
            let label = CGRect(x: 7 * unit, y: size.height - 12 * unit, width: 22 * unit, height: 6 * unit)
            context.fill(Path(roundedRect: label, cornerRadius: 3 * unit), with: soft)
        }
    }

    /// The icon, the name and the line under it, centered.
    private func centeredName(
        in context: inout GraphicsContext, center: CGFloat, unit: CGFloat, size: CGSize,
        light: GraphicsContext.Shading, soft: GraphicsContext.Shading
    ) {
        let icon = 6 * unit
        let middle = size.width / 2
        let iconRect = CGRect(x: middle - icon / 2, y: center - icon - unit, width: icon, height: icon)
        context.fill(Path(roundedRect: iconRect, cornerRadius: unit * 1.4), with: light)
        let name = CGRect(x: middle - 14 * unit, y: center + unit, width: 28 * unit, height: 3 * unit)
        context.fill(Path(roundedRect: name, cornerRadius: unit), with: light)
        let line = CGRect(x: middle - 10 * unit, y: center + 5 * unit, width: 20 * unit, height: 2 * unit)
        context.fill(Path(roundedRect: line, cornerRadius: unit), with: soft)
    }

    private func device(in context: inout GraphicsContext, rect: CGRect, radius: CGFloat) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(Color(white: 0.96)))
    }

    private func rotated(in context: inout GraphicsContext, degrees: Double, rect: CGRect, radius: CGFloat) {
        var copy = context
        copy.translateBy(x: rect.midX, y: rect.midY)
        copy.rotate(by: .degrees(degrees))
        let centered = CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
        copy.fill(Path(roundedRect: centered, cornerRadius: radius), with: .color(Color(white: 0.96)))
    }

    /// Hills and the moon.
    private func scene(in context: inout GraphicsContext, size: CGSize, unit: CGFloat) {
        let moon = CGRect(x: size.width * 0.7, y: size.height * 0.22, width: 9 * unit, height: 9 * unit)
        context.fill(Path(ellipseIn: moon), with: .color(Color(red: 1, green: 0.85, blue: 0.77)))
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: size.height))
        hills.addLine(to: CGPoint(x: 0, y: size.height * 0.78))
        hills.addQuadCurve(to: CGPoint(x: size.width * 0.55, y: size.height * 0.74), control: CGPoint(x: size.width * 0.25, y: size.height * 0.6))
        hills.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.7), control: CGPoint(x: size.width * 0.8, y: size.height * 0.84))
        hills.addLine(to: CGPoint(x: size.width, y: size.height))
        hills.closeSubpath()
        context.fill(hills, with: .color(Color(red: 0.11, green: 0.11, blue: 0.21).opacity(0.85)))
    }
}
