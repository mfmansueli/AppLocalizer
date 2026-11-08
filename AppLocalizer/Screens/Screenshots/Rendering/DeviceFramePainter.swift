//
//  DeviceFramePainter.swift
//  AppLocalizer
//

import SwiftUI

/// The device frame drawn as a 3D object (design README, Arcade: "Device
/// frames are 3D"), still in 2D so a sheet of thumbnails stays cheap: a body
/// with thickness (offset copies toward the side its angle shows), side
/// buttons on an iPhone, a metal rim in the frame's finish, a dark lip
/// around the screen, and a soft floor shadow under a device that stands
/// inside the canvas. A MacBook's lid is thinner and stands on its base,
/// which casts the shadow. The glare over the glass is drawn after the
/// capture.
struct DeviceFramePainter {
    let device: LayoutDevice
    let canvasHeight: CGFloat

    /// How many offset copies draw the body's thickness: fewer for a
    /// MacBook's thin lid.
    private var layers: Int { device.isLaptop ? 3 : 7 }

    private var finish: TemplateColor { device.color }

    /// A light finish (silver, white) gets subtler highlights.
    private var isLight: Bool { (finish.red + finish.green + finish.blue) * 255 > 380 }

    private var turn: Double { device.tilt?.turn ?? 0 }
    private var lean: Double { device.tilt?.lean ?? 0 }

    private var isTilted: Bool {
        guard let tilt = device.tilt else { return false }
        return abs(tilt.rotate) + abs(tilt.turn) + abs(tilt.lean) > 0.5
    }

    /// Where the body's back edge sits: toward the side the angle shows.
    private var depth: CGVector {
        let thickness = device.frame.width * (device.isLaptop ? 0.012 : 0.075)
        let radians = Double.pi / 180
        return CGVector(dx: -thickness * 1.3 * sin(turn * radians), dy: thickness * 1.1 * sin(lean * radians))
    }

    /// The soft shadow on the floor, outside the device's angle; drawn
    /// first. A device running off the bottom has none.
    func drawFloor(in context: inout GraphicsContext) {
        let frame = device.frame
        guard frame.maxY <= canvasHeight * 0.98 else { return }
        let floor = CGRect(
            x: frame.minX + frame.width * 0.1 + turn * frame.width * 0.008, y: frame.minY + frame.height * (device.isLaptop ? 1.02 : 0.94),
            width: frame.width * 0.8, height: frame.width * 0.16
        )
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: frame.width * 0.06))
            layer.fill(Path(ellipseIn: floor), with: .color(.black.opacity(0.18)))
        }
    }

    /// The body, buttons, rim and the lip around the screen, in the
    /// device's angle (already applied to `context`).
    func drawBody(in context: inout GraphicsContext) {
        let frame = device.frame
        let radius = device.cornerRadius
        let shape = Path(roundedRect: frame, cornerRadius: radius, style: .continuous)
        let depth = depth
        let sideAngle = 90 + turn * 2
        for index in stride(from: layers, through: 1, by: -1) {
            let amount = CGFloat(index) / CGFloat(layers)
            let gradient = Gradient(stops: [
                .init(color: mix(toward: .black, 0.2 + amount * 0.35), location: 0),
                .init(color: mix(toward: .white, isLight ? 0.05 : 0.18), location: 0.48),
                .init(color: mix(toward: .black, 0.3 + amount * 0.35), location: 1),
            ])
            let offset = shape.offsetBy(dx: depth.dx * amount, dy: depth.dy * amount)
            let (start, end) = ScreenshotPainter.gradientPoints(angle: sideAngle, in: frame.offsetBy(dx: depth.dx * amount, dy: depth.dy * amount))
            if index == layers, !device.isLaptop {
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: .black.opacity(0.28), radius: device.shadowRadius / 2, x: 0, y: device.shadowOffset))
                    layer.fill(offset, with: .linearGradient(gradient, startPoint: start, endPoint: end))
                }
            } else {
                context.fill(offset, with: .linearGradient(gradient, startPoint: start, endPoint: end))
            }
        }
        drawButtons(in: &context, depth: depth)
        drawRim(shape, in: &context)
        drawBase(in: &context)
    }

    /// A MacBook's base: a bar wider than the lid, rounded underneath, lit
    /// from the top, with the notch for opening it. It casts the shadow.
    private func drawBase(in context: inout GraphicsContext) {
        guard let base = device.base else { return }
        let radius = base.height * 0.9
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius, style: .continuous).path(in: base)
        let gradient = Gradient(stops: [
            .init(color: mix(toward: .white, 0.55), location: 0), .init(color: mix(toward: .white, 0.3), location: 0.22),
            .init(color: mix(toward: .black, 0.05), location: 0.7), .init(color: mix(toward: .black, 0.35), location: 1),
        ])
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.28), radius: device.shadowRadius / 2, x: 0, y: device.shadowOffset))
            layer.fill(shape, with: .linearGradient(gradient, startPoint: CGPoint(x: base.midX, y: base.minY), endPoint: CGPoint(x: base.midX, y: base.maxY)))
        }
        let notch = CGRect(x: base.midX - base.width * 0.075, y: base.minY, width: base.width * 0.15, height: base.height * 0.42)
        let notchRadius = base.height * 0.3
        let notchShape = UnevenRoundedRectangle(bottomLeadingRadius: notchRadius, bottomTrailingRadius: notchRadius, style: .continuous).path(in: notch)
        context.fill(notchShape, with: .color(mix(toward: .black, 0.2)))
    }

    /// Volume and action buttons on the left, the side button on the
    /// right: an iPhone's (it has an island); iPads and folded phones have
    /// none.
    private func drawButtons(in context: inout GraphicsContext, depth: CGVector) {
        guard device.island != nil else { return }
        let frame = device.frame
        let width = max(3, device.bezel * 0.55)
        let color = mix(toward: .white, isLight ? 0.1 : 0.3)
        let buttons: [(side: CGFloat, top: CGFloat, length: CGFloat)] = [(-1, 0.155, 0.04), (-1, 0.215, 0.065), (-1, 0.295, 0.065), (1, 0.235, 0.1)]
        for button in buttons {
            let x = button.side < 0 ? frame.minX - width * 0.55 : frame.maxX - width * 0.45
            let rect = CGRect(x: x, y: frame.minY + frame.height * button.top, width: width, height: frame.height * button.length)
                .offsetBy(dx: depth.dx * 0.5, dy: depth.dy * 0.5)
            context.fill(Path(roundedRect: rect, cornerRadius: width / 2, style: .continuous), with: .color(color))
        }
    }

    /// The metal rim: the finish lit from the top left, a thin bright edge,
    /// and the near-black glass border with its faint lip.
    private func drawRim(_ shape: Path, in context: inout GraphicsContext) {
        let frame = device.frame
        let light = mix(toward: .white, isLight ? 0.25 : 0.42)
        let brightest = mix(toward: .white, isLight ? 0.45 : 0.62)
        let dark = mix(toward: .black, 0.35)
        let dim = mix(toward: .black, 0.12)
        let rim = Gradient(stops: [
            .init(color: brightest, location: 0), .init(color: dark, location: 0.14), .init(color: light, location: 0.38),
            .init(color: dim, location: 0.55), .init(color: brightest, location: 0.78), .init(color: dark, location: 1),
        ])
        let (start, end) = ScreenshotPainter.gradientPoints(angle: 135 + turn, in: frame)
        context.fill(shape, with: .linearGradient(rim, startPoint: start, endPoint: end))
        let rimWidth = max(2, device.bezel * 0.34)
        let edge = max(1, rimWidth * 0.2)
        context.stroke(
            Path(roundedRect: frame.insetBy(dx: edge / 2, dy: edge / 2), cornerRadius: device.cornerRadius, style: .continuous),
            with: .color(.white.opacity(0.22)), lineWidth: edge
        )
        let glass = frame.insetBy(dx: rimWidth, dy: rimWidth)
        let glassRadius = max(0, device.cornerRadius - rimWidth)
        context.fill(Path(roundedRect: glass, cornerRadius: glassRadius, style: .continuous), with: .color(Color(red: 5 / 255, green: 5 / 255, blue: 6 / 255)))
        let lip = max(1, rimWidth * 0.25)
        context.stroke(
            Path(roundedRect: glass.insetBy(dx: lip / 2, dy: lip / 2), cornerRadius: max(0, glassRadius - lip / 2), style: .continuous),
            with: .color(.white.opacity(0.07)), lineWidth: lip
        )
    }

    /// The light across the glass, over the capture: stronger when the
    /// device is at an angle.
    func drawGlare(over screen: Path, rect: CGRect, in context: inout GraphicsContext) {
        let strong = isTilted ? 0.16 : 0.09
        let faint = isTilted ? 0.06 : 0.03
        let glare = Gradient(stops: [
            .init(color: .white.opacity(strong), location: 0), .init(color: .white.opacity(0), location: 0.34),
            .init(color: .white.opacity(0), location: 0.72), .init(color: .white.opacity(faint), location: 1),
        ])
        let (start, end) = ScreenshotPainter.gradientPoints(angle: 118 - turn * 1.5, in: rect)
        context.fill(screen, with: .linearGradient(glare, startPoint: start, endPoint: end))
    }

    /// The finish moved `amount` (0–1) toward black or white.
    private func mix(toward target: TemplateColor, _ amount: Double) -> Color {
        let mixed = TemplateColor(
            red: finish.red + (target.red - finish.red) * amount,
            green: finish.green + (target.green - finish.green) * amount,
            blue: finish.blue + (target.blue - finish.blue) * amount
        )
        return mixed.color
    }
}
