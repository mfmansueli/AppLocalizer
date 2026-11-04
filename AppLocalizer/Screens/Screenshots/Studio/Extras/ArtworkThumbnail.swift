//
//  ArtworkThumbnail.swift
//  AppLocalizer
//

import SwiftUI

/// A header or search image drawn small: rendered once its captures are
/// loaded, at twice its width in pixels, with its ratio kept meanwhile. In
/// the viewer a loop plays instead (`plays`), at the studio's
/// `artworkLoop` clock, whose controls the viewer shows under it. With a
/// Claude Design `page` it's that page, rendered by WebKit, and its loop
/// plays live.
struct ArtworkThumbnail: View {
    @Bindable var studio: ScreenshotStudioModel
    let kind: AutopilotArtworkKind
    let template: ScreenshotTemplate
    let locale: String
    let headline: String
    /// The slots the phones show, front first, with their captures.
    let slots: [Int]
    let captures: [Int: ScreenshotCapture]
    let width: CGFloat
    var shows: AutopilotArtworkShow = .phone
    /// A motion loop's poster: its light, and "0:20 loop" on it.
    var isMotion = false
    /// A loop plays (the viewer) instead of showing its poster.
    var plays = false
    /// The direction's own page for this canvas, from Claude Design.
    var page: String?
    @State private var rendered: CGImage?
    /// The page a playing loop shows live.
    @State private var live: ArtworkWebRequest?
    /// What a playing loop draws each frame.
    @State private var loop: Loop?

    private struct Loop {
        var layout: ArtworkLayout
        var captures: [Int: CGImage]
        var icon: CGImage?
    }

    private static let captureWidth = 480

    var body: some View {
        let images = captures.compactMapValues { studio.screenshots.captureImages.image(for: $0, width: Self.captureWidth) }
        let ratio = CGFloat(kind.pixelSize.height) / CGFloat(kind.pixelSize.width)
        Group {
            if plays, isMotion, page != nil, let live {
                ArtworkWebLoopPlayer(request: live, width: width, clock: studio.artworkLoop)
            } else if plays, isMotion, page == nil, let loop {
                ArtworkLoopPlayer(layout: loop.layout, captures: loop.captures, icon: loop.icon, width: width, clock: studio.artworkLoop)
            } else if let rendered {
                Image(decorative: rendered, scale: 2).resizable()
            } else {
                RoundedRectangle(cornerRadius: 4).fill(Palette.fill2)
            }
        }
        .frame(width: width, height: (width * ratio).rounded())
        .clipShape(RoundedRectangle(cornerRadius: max(3, width * 0.022), style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            if isMotion, !plays, width >= 160 { loopChip }
        }
        .task(id: RenderKey(
            template: template, locale: locale, headline: headline, appName: studio.appName(in: locale), loaded: Set(images.keys), width: width,
            shows: shows, isMotion: isMotion, page: page, phrases: page == nil ? [:] : studio.artworkPhrases(in: locale)
        )) {
            studio.screenshots.captureImages.request(Array(captures.values), width: Self.captureWidth)
            guard let store = StoreLocaleCatalog.locale(code: locale) else { return }
            if let page {
                await render(page, locale: store, images: images)
                return
            }
            let layout = ArtworkLayoutEngine(catalog: studio.screenshots.services.fonts).layout(
                template, kind: kind, locale: store, headline: headline, slots: slots,
                captureSizes: images.mapValues { PixelSize(width: $0.width, height: $0.height) }, appName: studio.appName(in: locale),
                shows: shows, isMotion: isMotion
            )
            let icon = await ArtworkIcon.image(of: studio.app)
            rendered = ArtworkRenderer.image(layout: layout, captures: images, icon: icon, pixelWidth: Int(width * 2))
            if plays, isMotion { loop = Loop(layout: layout, captures: images, icon: icon) }
        }
        .accessibilityElement(children: plays && isMotion ? .contain : .ignore)
        .accessibilityLabel(Text("\(kind.title) artwork, \(StoreLocaleCatalog.locale(code: locale)?.name ?? locale)"))
        .accessibilityIdentifier("artwork.\(kind.rawValue).\(locale)")
    }

    private struct RenderKey: Hashable {
        var template: ScreenshotTemplate
        var locale: String
        var headline: String
        /// The name in this language's App Store page, once it's read.
        var appName: String
        var loaded: Set<Int>
        var width: CGFloat
        var shows: AutopilotArtworkShow
        var isMotion: Bool
        var page: String?
        /// The page's phrases in this language, as the set has them.
        var phrases: [String: String]
    }

    /// The page in `locale` with the captures loaded so far: the cached
    /// image when there is one, else WebKit's render; in the viewer a loop
    /// plays live instead.
    private func render(_ html: String, locale: StoreLocale, images: [Int: CGImage]) async {
        let pixelWidth = Int(width * 2)
        let phrases = studio.artworkPhrases(in: locale.code)
        let key = ArtworkWebThumbnails.Key(
            html: html, locale: locale.code, headline: headline, appName: studio.appName(in: locale.code),
            captures: captures.filter { images[$0.key] != nil }, pixelWidth: pixelWidth, phrases: phrases
        )
        let playsLive = plays && isMotion
        if !playsLive, let cached = ArtworkWebThumbnails.shared.image(for: key) {
            rendered = cached
            return
        }
        let request = await ArtworkWebRequest(
            html: html, kind: kind, locale: locale.code, isRightToLeft: locale.isRTL || ScreenshotScript(locale: locale).isRightToLeft,
            headline: headline, appName: studio.appName(in: locale.code), captures: images.compactMapValues(ScreenshotPNG.data),
            icon: ArtworkIcon.image(of: studio.app).flatMap(ScreenshotPNG.data), pixelWidth: pixelWidth,
            primaryLocale: studio.artworkPrimaryLocale, phrases: phrases
        )
        if playsLive {
            live = request
            return
        }
        guard let image = try? await ArtworkWebRenderer.shared.render(request).image, !Task.isCancelled else { return }
        ArtworkWebThumbnails.shared.store(image, for: key)
        rendered = image
    }

    /// "0:20 loop", in the bottom corner.
    private var loopChip: some View {
        let isHeader = kind == .header
        let height = max(9, (width * (isHeader ? 0.026 : 0.036)).rounded())
        let font = max(7, (width * (isHeader ? 0.014 : 0.02)).rounded())
        let inset = max(3, (width * (kind == .search ? 0.035 : 0.016)).rounded())
        return HStack(spacing: max(2, width * 0.006)) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("\(AutopilotRun.timeTitle(Double(AutopilotArtworkMotion.loopSeconds))) loop")
                .monospacedDigit()
        }
        .font(.system(size: font, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, max(3, width * (isHeader ? 0.009 : 0.013)))
        .frame(height: height)
        .background(.black.opacity(0.5), in: Capsule())
        .environment(\.layoutDirection, .leftToRight)
        .padding(inset)
        .accessibilityIdentifier("studio.artwork.loopChip")
    }
}
