//
//  ArtworkCheckFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
@testable import AppLocalizer

/// Templates, layouts and renders for the header and search artwork tests.
@MainActor
enum ArtworkCheckFixtures {
    static let fonts = ScreenshotsTestFixtures.fonts
    static let engine = ArtworkLayoutEngine(catalog: fonts)
    /// A phone-shaped capture's size.
    static let captureSize = PixelSize(width: 1320, height: 2868)

    /// White text on a mid blue, which reads and has edges in Light and
    /// Dark Mode.
    static func template(background: String = "#3A5BD9", ink: String = "#FFFFFF", font: String? = nil) -> ScreenshotTemplate {
        var template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        template.background = TemplateBackground(kind: .solid, angle: nil, stops: [background], image: nil)
        template.caption.ink = ink
        if let font { template.caption.headline.font = font }
        return template
    }

    static func layout(
        _ kind: AutopilotArtworkKind, headline: String, locale: StoreLocale = .englishUS, template: ScreenshotTemplate = template(),
        appName: String? = "Lumen", shows: AutopilotArtworkShow = .phone, isMotion: Bool = false
    ) -> ArtworkLayout {
        let slots = kind == .search ? [2] : [0, 1]
        return engine.layout(
            template, kind: kind, locale: locale, headline: headline, slots: slots,
            captureSizes: Dictionary(uniqueKeysWithValues: slots.map { ($0, captureSize) }), appName: appName,
            shows: shows, isMotion: isMotion
        )
    }

    /// A light grey capture with dark bars where text would be.
    static func capture() -> CGImage? {
        image(width: captureSize.width / 4, height: captureSize.height / 4) { context, size in
            context.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1))
            context.fill(CGRect(origin: .zero, size: size))
            context.setFillColor(CGColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1))
            for row in 0..<8 { context.fill(CGRect(x: 20, y: 60 + row * 70, width: 200, height: 24)) }
        }
    }

    /// The render, as `ArtworkRenderer` makes it.
    static func render(_ layout: ArtworkLayout) -> CGImage? {
        let captures = Dictionary(uniqueKeysWithValues: layout.phones.compactMap { phone in capture().map { (phone.slot, $0) } })
        return ArtworkRenderer.image(layout: layout, captures: captures)
    }

    static func input(
        _ layout: ArtworkLayout, line: String, locale: StoreLocale = .englishUS, image: CGImage? = nil, template: ScreenshotTemplate = template(),
        screenshotTemplate: ScreenshotTemplate? = nil
    ) -> ArtworkCheckInput {
        ArtworkCheckInput(
            kind: layout.kind, locale: locale, image: image, layout: layout, line: line, template: template, screenshotTemplate: screenshotTemplate
        )
    }

    /// A bitmap drawn by `draw`, from the bottom left like Core Graphics.
    static func image(
        width: Int, height: Int, alpha: Bool = false, draw: (CGContext, CGSize) -> Void
    ) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                  bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue
              )
        else { return nil }
        draw(context, CGSize(width: width, height: height))
        return context.makeImage()
    }

    /// One color all over.
    static func solid(_ color: CGColor, width: Int = 384, height: Int = 165, alpha: Bool = false) -> CGImage? {
        image(width: width, height: height, alpha: alpha) { context, size in
            context.setFillColor(color)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
#endif
