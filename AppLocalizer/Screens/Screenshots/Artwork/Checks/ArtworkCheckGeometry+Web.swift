//
//  ArtworkCheckGeometry+Web.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ArtworkCheckGeometry {
    /// A Claude Design page as rendered: its text where the page set it,
    /// read against what's behind it (the page drawn without the text), its
    /// captures as the focal point, and its own colors.
    init(web render: ArtworkWebRender, kind: AutopilotArtworkKind) {
        let measure = render.measure
        let size = kind.pixelSize.cgSize
        let behind = render.behindText.flatMap(ArtworkPixels.init)
        let sampler = Sampler(pixels: behind, canvasWidth: size.width)
        func text(_ element: ArtworkWebMeasure.Element, name: String) -> Text {
            let ink = TemplateColor(element.color ?? "")
            let ground = sampler.median(in: element.frame)
            let contrast: Double? = if let ink, ink.alpha > 0.05, let ground {
                ArtworkContrast.ratio(ArtworkContrast.over(ink, ground), ground)
            } else { nil }
            return Text(name: name, text: element.text ?? "", frame: element.frame, contrast: contrast)
        }
        let shown = measure.elements.filter(\.isVisible)
        let headline = shown.filter { $0.kind == .headline && $0.hasText }.map { text($0, name: String(localized: "the headline")) }
        let name = shown.first { $0.kind == .appName && $0.hasText }.map { text($0, name: String(localized: "the app’s name")) }
        let texts = measure.texts.map { text($0, name: String(localized: "the text ‘\(Self.snippet($0.text ?? ""))’")) }
        let icon = shown.first { $0.kind == .icon }?.frame
        let label = [icon, name?.frame].compactMap(\.self).reduce(nil) { union, frame in union?.union(frame) ?? frame }
        let captures = shown.filter { $0.kind == .capture }.map(\.frame)
        let canvas = CGRect(origin: .zero, size: size)
        let focal = captures.reduce(nil) { (union: CGRect?, frame: CGRect) in union?.union(frame) ?? frame }
            .map { $0.intersection(canvas) }.flatMap { $0.isNull || $0.isEmpty ? nil : $0 }
        let font = measure.headline?.font.map(ArtworkWebFonts.templateName)
        self.init(
            size: size, safeArea: ArtworkSafeArea.rect(for: kind), headline: headline, appName: name, labelFrame: label,
            interfaceFrames: captures, visibleFocalFrame: focal, colors: sampler.palette, headlineFont: font,
            moving: render.moving.map(Self.title), texts: texts
        )
    }

    /// The start of a page's text, for a check to name it.
    static func snippet(_ text: String) -> String {
        text.count > 40 ? String(text.prefix(39)) + "…" : text
    }

    /// "the headline", "the app’s icon".
    static func title(_ marker: ArtworkWebMarker) -> String {
        switch marker {
        case .headline: String(localized: "the headline")
        case .appName: String(localized: "the app’s name")
        case .icon: String(localized: "the app’s icon")
        case .capture: String(localized: "the capture")
        case .text: String(localized: "the page’s text")
        }
    }

    /// Reads colors from the page drawn without its text.
    private struct Sampler {
        let pixels: ArtworkPixels?
        let canvasWidth: CGFloat

        private var scale: CGFloat { CGFloat(pixels?.width ?? 1) / max(1, canvasWidth) }

        /// The middle color of a 5 × 3 grid over `frame`, by luminance.
        func median(in frame: CGRect) -> TemplateColor? {
            guard let pixels, frame.width > 0, frame.height > 0 else { return nil }
            var colors: [TemplateColor] = []
            for row in 0..<3 {
                for column in 0..<5 {
                    let x = frame.minX + frame.width * (CGFloat(column) + 0.5) / 5
                    let y = frame.minY + frame.height * (CGFloat(row) + 0.5) / 3
                    colors.append(pixels.color(x: Int(x * scale), y: Int(y * scale)))
                }
            }
            let sorted = colors.map { ArtworkContrast.over($0, .black) }.sorted { ArtworkContrast.luminance($0) < ArtworkContrast.luminance($1) }
            return sorted[sorted.count / 2]
        }

        /// A few distinct colors from a 6 × 4 grid over the whole image.
        var palette: [TemplateColor] {
            guard let pixels else { return [] }
            var found: [TemplateColor] = []
            for row in 0..<4 {
                for column in 0..<6 {
                    let color = ArtworkContrast.over(
                        pixels.color(x: pixels.width * (column * 2 + 1) / 12, y: pixels.height * (row * 2 + 1) / 8), .black
                    )
                    if !found.contains(where: { ArtworkContrast.distance($0, color) < 0.06 }) { found.append(color) }
                }
            }
            return found
        }
    }
}
