//
//  ArtworkChecker+Composition.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ArtworkChecker {
    /// A search headline answers the search in 3 to 5 words; a header line
    /// is about 3 words, or none.
    func lengthChecks(_ input: ArtworkCheckInput) -> [ArtworkCheck] {
        let line = input.line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return [] }
        let locale = input.locale
        let length = ArtworkTextLength.isUnspaced(locale)
            ? String(localized: "\(ArtworkTextLength.width(of: line)) characters wide")
            : String(localized: "\(ArtworkTextLength.words(in: line)) words, \(line.count) characters")
        var checks: [ArtworkCheck] = []
        if input.roles.contains(.search), ArtworkTextLength.isLongForSearch(line, locale: locale) {
            checks.append(ArtworkCheck(
                kind: .searchHeadlineLength,
                text: String(localized: "\(input.place): ‘\(line)’ is \(length). A search headline reads best in 3 to 5 words, about 32 characters.")
            ))
        }
        if input.roles.contains(.header), ArtworkTextLength.isLongForHeader(line, locale: locale) {
            checks.append(ArtworkCheck(
                kind: .headerTextLength,
                text: String(localized: "\(input.place): ‘\(line)’ is \(length). A header carries one idea: about 3 words, or none.")
            ))
        }
        return checks
    }

    /// The phones and the text stay inside the center safe area, which
    /// every device shows.
    func safeAreaChecks(_ input: ArtworkCheckInput) -> [ArtworkCheck] {
        let geometry = input.geometry
        let safe = geometry.safeArea.insetBy(dx: -2, dy: -2)
        var outside: [String] = []
        if let focal = geometry.visibleFocalFrame, !safe.contains(focal) { outside.append(String(localized: "the phones")) }
        if geometry.headline.contains(where: { !safe.contains($0.frame) }) { outside.append(String(localized: "the headline")) }
        if geometry.texts.contains(where: { !safe.contains($0.frame) }) { outside.append(String(localized: "the page’s text")) }
        if let label = geometry.labelFrame, !safe.contains(label) {
            outside.append(String(localized: "the app’s icon and name"))
        }
        guard !outside.isEmpty else { return [] }
        let parts = outside.formatted(.list(type: .and))
        return [ArtworkCheck(kind: .safeArea, text: String(localized: "\(input.place): \(parts) run outside the center safe area, so some devices cut them off."))]
    }

    /// Text against what's behind it, and the image's edges against the App
    /// Store page in Light and Dark Mode.
    func contrastChecks(_ input: ArtworkCheckInput, pixels: ArtworkPixels?) -> [ArtworkCheck] {
        var checks: [ArtworkCheck] = []
        let texts = input.geometry.headline + (input.geometry.appName.map { [$0] } ?? []) + input.geometry.texts
        var lowest: (ratio: Double, name: String)?
        for text in texts where !text.text.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let ratio = text.contrast else { continue }
            if ratio < ArtworkContrast.minimumTextRatio, ratio < lowest?.ratio ?? .infinity { lowest = (ratio, text.name) }
        }
        if let lowest {
            checks.append(ArtworkCheck(
                kind: .textContrast,
                text: String(localized: "\(input.place): \(lowest.name) is hard to read on what’s behind it (\(Self.ratioTitle(lowest.ratio)); aim for 3:1 or more).")
            ))
        }
        guard let pixels else { return checks }
        let edges = pixels.edgeColors
        for (page, mode) in [(ArtworkContrast.lightPage, String(localized: "Light Mode")), (ArtworkContrast.darkPage, String(localized: "Dark Mode"))] {
            let ratios = edges.map { ArtworkContrast.ratio(ArtworkContrast.over($0, page), page) }.sorted()
            guard !ratios.isEmpty else { continue }
            let median = ratios[ratios.count / 2]
            guard median < ArtworkContrast.minimumEdgeRatio else { continue }
            checks.append(ArtworkCheck(
                kind: .edgeContrast,
                text: String(localized: "\(input.place): in \(mode) its edges melt into the App Store page (\(Self.ratioTitle(median))), so it has no visible edge.")
            ))
        }
        return checks
    }

    /// The header sets the tone for the page: it should share the first
    /// screenshot's colors and, when it has text, its typeface.
    func lookChecks(_ input: ArtworkCheckInput) -> [ArtworkCheck] {
        guard input.roles.contains(.header), input.firstScreenshot != nil || input.screenshotTemplate != nil else { return [] }
        let own = input.geometry.colors
        let theirs = input.firstScreenshot.map { Self.colors(of: $0.background) }
            ?? input.screenshotTemplate?.background.stops.compactMap(TemplateColor.init) ?? []
        var missing: [String] = []
        if !own.isEmpty, !theirs.isEmpty, !own.contains(where: { color in theirs.contains { ArtworkContrast.distance(color, $0) < 0.12 } }) {
            missing.append(String(localized: "colors"))
        }
        if let font = input.geometry.headlineFont,
           let screenshotFont = input.firstScreenshot?.headlineFont.fontName ?? input.screenshotTemplate?.caption.headline.font,
           font.caseInsensitiveCompare(screenshotFont) != .orderedSame
        {
            missing.append(String(localized: "typeface (\(font); the screenshots use \(screenshotFont))"))
        }
        guard !missing.isEmpty else { return [] }
        let parts = missing.formatted(.list(type: .and))
        return [ArtworkCheck(
            kind: .sharedLook,
            text: String(localized: "\(input.place): it doesn’t share the first screenshot’s \(parts), so the page below doesn’t follow from it.")
        )]
    }

    // MARK: - Helpers

    /// A line's ink over its highlight, else over the background at its
    /// middle.
    static func textRatio(_ line: LayoutTextLine, background: LayoutBackground, size: CGSize) -> Double {
        let ground = ArtworkContrast.color(of: background, at: CGPoint(x: line.frame.midX, y: line.frame.midY), in: size)
        let opaqueGround = ArtworkContrast.over(ground, .black)
        let behind = line.highlight.map { ArtworkContrast.over($0.color, opaqueGround) } ?? opaqueGround
        return ArtworkContrast.ratio(ArtworkContrast.over(line.color, behind), behind)
    }

    static func colors(of background: LayoutBackground) -> [TemplateColor] {
        switch background {
        case let .solid(color): [color]
        case let .linear(_, stops): stops
        case let .panorama(panorama): panorama.stops
        }
    }

    /// "1.4:1".
    static func ratioTitle(_ ratio: Double) -> String {
        "\(ratio.formatted(.number.precision(.fractionLength(1)))):1"
    }
}
