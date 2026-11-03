//
//  ArtworkPhone.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// One phone in the header or search artwork, in artwork pixels: a rounded
/// body in the template's device color around a real capture, turned by a
/// few degrees about its center.
struct ArtworkPhone: Hashable, Sendable {
    /// The slot whose picked capture it shows.
    var slot: Int
    /// The body, bezel included.
    var frame: CGRect
    var screen: CGRect
    var cornerRadius: CGFloat
    var screenCornerRadius: CGFloat
    /// Degrees, clockwise.
    var rotation: Double
    var color: TemplateColor
    var shadowOffset: CGFloat
    var shadowRadius: CGFloat
    /// The app without a device: only the screen, rounded and floating.
    var isBare = false

    /// The body as turned: the box it covers on the artwork.
    var bounds: CGRect {
        Self.bounds(of: frame, rotation: rotation)
    }

    /// The box `rect` covers once turned by `rotation` degrees about its
    /// center.
    static func bounds(of rect: CGRect, rotation: Double) -> CGRect {
        let angle = abs(rotation) * .pi / 180
        let width = rect.width * cos(angle) + rect.height * sin(angle)
        let height = rect.width * sin(angle) + rect.height * cos(angle)
        return CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
    }

    /// Where a capture of `size` is drawn: aspect-fill, top-aligned,
    /// clipped to the screen. Never mirrored: it's the real interface.
    func captureFrame(for size: PixelSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return screen }
        let scale = max(screen.width / CGFloat(size.width), screen.height / CGFloat(size.height))
        let width = CGFloat(size.width) * scale
        return CGRect(x: screen.midX - width / 2, y: screen.minY, width: width, height: CGFloat(size.height) * scale)
    }
}
