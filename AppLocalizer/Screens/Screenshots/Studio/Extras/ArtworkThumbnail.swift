//
//  ArtworkThumbnail.swift
//  AppLocalizer
//

import SwiftUI

/// A header or search image drawn small: rendered once its captures are
/// loaded, at twice its width in pixels, with its ratio kept meanwhile.
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
    @State private var rendered: CGImage?

    private static let captureWidth = 480

    var body: some View {
        let images = captures.compactMapValues { studio.screenshots.captureImages.image(for: $0, width: Self.captureWidth) }
        let ratio = CGFloat(kind.pixelSize.height) / CGFloat(kind.pixelSize.width)
        Group {
            if let rendered {
                Image(decorative: rendered, scale: 2).resizable()
            } else {
                RoundedRectangle(cornerRadius: 4).fill(Palette.fill2)
            }
        }
        .frame(width: width, height: (width * ratio).rounded())
        .clipShape(RoundedRectangle(cornerRadius: max(3, width * 0.022), style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            if isMotion, width >= 160 { loopChip }
        }
        .task(id: RenderKey(
            template: template, locale: locale, headline: headline, loaded: Set(images.keys), width: width, shows: shows, isMotion: isMotion
        )) {
            studio.screenshots.captureImages.request(Array(captures.values), width: Self.captureWidth)
            guard let store = StoreLocaleCatalog.locale(code: locale) else { return }
            let layout = ArtworkLayoutEngine(catalog: studio.screenshots.services.fonts).layout(
                template, kind: kind, locale: store, headline: headline, slots: slots,
                captureSizes: images.mapValues { PixelSize(width: $0.width, height: $0.height) }, appName: studio.app.name,
                shows: shows, isMotion: isMotion
            )
            let icon = await ArtworkIcon.image(of: studio.app)
            rendered = ArtworkRenderer.image(layout: layout, captures: images, icon: icon, pixelWidth: Int(width * 2))
        }
        .accessibilityElement()
        .accessibilityLabel(Text("\(kind.title) artwork, \(StoreLocaleCatalog.locale(code: locale)?.name ?? locale)"))
        .accessibilityIdentifier("artwork.\(kind.rawValue).\(locale)")
    }

    private struct RenderKey: Hashable {
        var template: ScreenshotTemplate
        var locale: String
        var headline: String
        var loaded: Set<Int>
        var width: CGFloat
        var shows: AutopilotArtworkShow
        var isMotion: Bool
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
