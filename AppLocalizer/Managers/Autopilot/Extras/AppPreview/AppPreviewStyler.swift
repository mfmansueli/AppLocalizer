//
//  AppPreviewStyler.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Draws what surrounds the recording in the App Preview, in the
/// screenshots' template: its background, a caption band with the screen's
/// headline (on the band color when the template sets its captions on a
/// band, at the bottom when the template puts captions below), and a
/// rounded, shadowed screen where the recording plays. Also the end card:
/// the app's name over the first screen's headline. Every image is opaque
/// and exactly the App Preview's size.
struct AppPreviewStyler {
    let template: ScreenshotTemplate
    let locale: StoreLocale
    let spec: AppPreviewSpec
    let recordingSize: PixelSize
    let fonts: ScreenshotFontCatalog
    /// Where the recording plays, in pixels from the top-left corner.
    let appRect: CGRect
    let appCornerRadius: CGFloat
    /// The caption band, in pixels from the top-left corner.
    let captionRect: CGRect
    /// The captions' size against the template's (the cut's "Bigger
    /// captions"); the band grows with it.
    let captionScale: CGFloat

    /// The screen color behind the recording.
    static let screenColor = TemplateColor(red: 0.11, green: 0.11, blue: 0.11)

    init(
        template: ScreenshotTemplate, locale: StoreLocale, spec: AppPreviewSpec, recordingSize: PixelSize, fonts: ScreenshotFontCatalog = .standard,
        captionScale: Double = 1
    ) {
        self.template = template
        self.locale = locale
        self.spec = spec
        self.recordingSize = recordingSize
        self.fonts = fonts
        let scale = CGFloat(min(max(captionScale, AppPreviewCut.captionScaleRange.lowerBound), AppPreviewCut.captionScaleRange.upperBound))
        self.captionScale = scale
        let canvas = spec.pixelSize.cgSize
        let band = (canvas.height * (spec.isLandscape ? 0.16 : 0.18) * max(1, scale)).rounded()
        let caption = template.caption
        let atTop = !(caption.placement == .below || (caption.placement == .band && caption.band.pos == .bottom))
        captionRect = CGRect(x: 0, y: atTop ? 0 : canvas.height - band, width: canvas.width, height: band)
        let marginX = canvas.width * (spec.isLandscape ? 0.04 : 0.06)
        let marginY = canvas.height * (spec.isLandscape ? 0.05 : 0.035)
        let area = CGRect(x: marginX, y: atTop ? band : marginY, width: canvas.width - 2 * marginX, height: canvas.height - band - marginY)
        let rect = Self.aspectFit(recordingSize.cgSize, in: area).integral
        appRect = rect
        appCornerRadius = (min(rect.width, rect.height) * (spec.displayType == .iPad ? 0.035 : 0.12)).rounded()
    }

    var canvas: CGSize { spec.pixelSize.cgSize }

    /// The headline's size in pixels before it shrinks to fit.
    var captionSize: CGFloat {
        let lineHeight = max(0.8, template.caption.headline.lineHeight)
        return min(canvas.width * 0.065 * captionScale, captionRect.height * 0.72 / (2 * lineHeight)).rounded()
    }

    /// How a screen's headline fits its band: at most two lines across 84 %
    /// of the width.
    func captionFit(for headline: String) -> CaptionFit {
        captionBlock(headline).fit
    }

    /// The frame for one screen's moment.
    func frame(headline: String) throws -> CGImage {
        let context = try Self.makeContext(spec.pixelSize)
        drawBackground(in: context)
        if template.caption.placement == .band, let color = TemplateColor(template.caption.band.color) {
            context.setFillColor(AppPreviewTextSetter.cgColor(color))
            context.fill(flipped(captionRect))
        }
        let block = captionBlock(headline)
        if !block.fit.isEmpty {
            setter.draw(block, top: captionRect.midY - block.height / 2, in: context, canvas: canvas)
        }
        drawScreen(in: context)
        guard let image = context.makeImage() else { throw AppPreviewError.drawingFailed }
        return image
    }

    /// The last card: the app's name, with the first screen's headline under
    /// it.
    func endCard(appName: String, headline: String) throws -> CGImage {
        let context = try Self.makeContext(spec.pixelSize)
        drawBackground(in: context)
        let caption = template.caption
        let width = canvas.width * 0.84
        let nameSize = min(canvas.width * 0.09, canvas.height * 0.11).rounded()
        let name = setter.set(appName, like: caption.headline, size: nameSize, maxLines: 2, width: width, ink: caption.ink)
        let lineSize = min(canvas.width * 0.045, canvas.height * 0.055).rounded()
        let line = setter.set(headline, like: caption.subhead, size: lineSize, maxLines: 3, width: width, ink: caption.subInk)
        let gap = line.fit.isEmpty ? 0 : nameSize * 0.5
        let lineHeight = line.fit.isEmpty ? 0 : line.height
        let top = (canvas.height - name.height - gap - lineHeight) / 2
        setter.draw(name, top: top, in: context, canvas: canvas)
        if !line.fit.isEmpty {
            setter.draw(line, top: top + name.height + gap, in: context, canvas: canvas)
        }
        guard let image = context.makeImage() else { throw AppPreviewError.drawingFailed }
        return image
    }

    /// A rect from the top-left corner in Core Graphics' bottom-left
    /// coordinates.
    func flipped(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: canvas.height - rect.maxY, width: rect.width, height: rect.height)
    }

    /// `size` scaled to fit inside `area`, centered.
    static func aspectFit(_ size: CGSize, in area: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return area }
        let scale = min(area.width / size.width, area.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: area.midX - fitted.width / 2, y: area.midY - fitted.height / 2, width: fitted.width, height: fitted.height)
    }

    /// An opaque-ready BGRA bitmap context, the layout the video writer
    /// takes.
    static func makeContext(_ size: PixelSize) throws -> CGContext {
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: size.width, height: size.height, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info
              )
        else { throw AppPreviewError.drawingFailed }
        return context
    }

    // MARK: - Drawing

    private var setter: AppPreviewTextSetter {
        AppPreviewTextSetter(template: template, locale: locale, fonts: fonts)
    }

    private func captionBlock(_ headline: String) -> AppPreviewTextSetter.SetBlock {
        let caption = template.caption
        return setter.set(headline, like: caption.headline, size: captionSize, maxLines: 2, width: canvas.width * 0.84, ink: caption.ink)
    }

    /// Solid, gradient or panorama colors; an uploaded image's first color
    /// stands in for it.
    private func drawBackground(in context: CGContext) {
        let background = template.background
        let colors = background.stops.compactMap(TemplateColor.init)
        let rect = CGRect(origin: .zero, size: canvas)
        guard colors.count > 1, background.kind == .linear || background.kind == .panorama,
              let gradient = CGGradient(
                  colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                  colors: colors.map(AppPreviewTextSetter.cgColor) as CFArray,
                  locations: colors.indices.map { CGFloat($0) / CGFloat(colors.count - 1) }
              )
        else {
            context.setFillColor(AppPreviewTextSetter.cgColor(colors.first ?? TemplateColor(red: 0.06, green: 0.06, blue: 0.08)))
            context.fill(rect)
            return
        }
        let mirrored = locale.isRTL && template.rightToLeft.mirror
        let angle = background.kind == .panorama ? (mirrored ? 270 : 90) : background.angle ?? 180
        let (start, end) = ScreenshotPainter.gradientPoints(angle: angle, in: rect)
        context.drawLinearGradient(
            gradient, start: CGPoint(x: start.x, y: canvas.height - start.y), end: CGPoint(x: end.x, y: canvas.height - end.y),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    /// The rounded screen the recording plays in, with a soft shadow.
    private func drawScreen(in context: CGContext) {
        let rect = flipped(appRect)
        let radius = min(appCornerRadius, rect.width / 2, rect.height / 2)
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -canvas.height * 0.01), blur: canvas.height * 0.025, color: CGColor(gray: 0, alpha: 0.3)
        )
        context.setFillColor(AppPreviewTextSetter.cgColor(Self.screenColor))
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }
}
