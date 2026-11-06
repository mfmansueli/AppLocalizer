//
//  ArtworkLayout.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Everything one header or search image draws, resolved from a
/// direction's template for a language: computed by `ArtworkLayoutEngine`,
/// drawn by `ArtworkView`. Geometry is in artwork pixels.
struct ArtworkLayout: Hashable, Sendable {
    var kind: AutopilotArtworkKind
    var locale: String
    var isMirrored: Bool
    /// What the checks measure against; a panorama look's gradient.
    var background: LayoutBackground
    /// A panorama look's picture, drawn over `background` across the
    /// whole image: its slots are the artwork's height, at about a
    /// portrait iPhone screenshot's shape. MB Admin's Panorama header was
    /// a bare gradient, unlike its screenshots.
    var panorama: LayoutPanorama?
    /// The center every device shows (`ArtworkSafeArea`): the phones and
    /// the text stay inside it.
    var safeArea: CGRect
    /// Where the headline may go: beside the phones, never under them.
    var headlineBox: CGRect
    var lines: [LayoutTextLine]
    /// How the headline fits; sizes in pixels.
    var headline: CaptionFit
    var phones: [ArtworkPhone]
    var appLabel: ArtworkAppLabel?
    var fonts: ScreenshotFontCatalog
    /// The light and, for a scene, the landscape over the background.
    var scene: ArtworkScene?

    var pixelSize: PixelSize { kind.pixelSize }

    /// One of the panorama's slots: an equal share of the width.
    var panoramaSlotSize: CGSize? {
        panorama.map { CGSize(width: size.width / CGFloat(max(1, $0.slotCount)), height: size.height) }
    }

    var size: CGSize { pixelSize.cgSize }

    /// The headline is set in full inside its box, at a size that can
    /// still be read.
    var headlineFits: Bool { headline.isEmpty || headline.fits }

    /// The focal point: every phone as turned.
    var focalFrame: CGRect? {
        phones.map(\.bounds).reduce(nil) { union, bounds in union?.union(bounds) ?? bounds }
    }

    /// The part of the phones the image shows: a phone may run off an
    /// edge on purpose.
    var visibleFocalFrame: CGRect? {
        focalFrame.map { $0.intersection(CGRect(origin: .zero, size: size)) }.flatMap { $0.isNull || $0.isEmpty ? nil : $0 }
    }

    /// The text drawn on the artwork itself: the headline's lines, then
    /// the app's name.
    var textLines: [LayoutTextLine] {
        lines + (appLabel.map { [$0.name] } ?? [])
    }
}
