//
//  CaptionsViewModel+ArtworkTexts.swift
//  AppLocalizer
//

import Foundation

/// Captions' Search results and Header columns: each language's own text
/// for the header and search artwork, measured on the direction's look.
extension CaptionsViewModel {
    /// The artwork's size: the one made, else the run's plan; nil when the
    /// set has no header or search artwork.
    var artworkSize: AutopilotArtworkSize? {
        let document = screenshots.document
        if let size = document?.extras?.artworkSize { return size }
        if let plan = screenshots.studio.run?.plan, plan.alsoMakes.makesArtwork { return plan.alsoMakes.artworkSize }
        return document?.artworkTexts.map { _ in .headerAndSearch }
    }

    /// The columns after the slots: Search results, then Header (one 16:9
    /// image has only the search headline).
    var artworkRoles: [ArtworkTextRole] {
        artworkSize.map(ArtworkTextRole.roles(for:)) ?? []
    }

    /// The look the texts are measured on: the artwork's own, else the
    /// chosen direction's, else the set's template.
    var artworkLook: ScreenshotTemplate? {
        screenshots.document?.extras?.artworkTemplate ?? screenshots.studio.run?.chosenDirection?.artworkLook ?? screenshots.document?.template
    }

    func artworkCells(for locale: StoreLocale, isPrimary: Bool) -> [ArtworkTextCell] {
        let texts = screenshots.document?.artworkTexts ?? ArtworkTextBook()
        return artworkRoles.map { role in
            let text = texts.text(role, locale: locale.code)
            return ArtworkTextCell(
                key: ArtworkTextKey(locale: locale.code, role: role), text: text,
                fit: text.flatMap { artworkFit(role: role, locale: locale, headline: $0.headline) }, isPrimary: isPrimary
            )
        }
    }

    /// The headline laid out on its artwork; nil without a look.
    func artworkFit(role: ArtworkTextRole, locale: StoreLocale, headline: String) -> CaptionFit? {
        guard let look = artworkLook, let size = artworkSize else { return nil }
        let engine = ArtworkLayoutEngine(catalog: screenshots.services.fonts)
        let shows = screenshots.document?.extras?.artworkShows ?? screenshots.studio.run?.plan.alsoMakes.artworkShows ?? .phone
        let fit = engine.layout(look, kind: role.kind(for: size), locale: locale, headline: headline, slots: [0], shows: shows).headline
        return Self.meterFit(fit)
    }

    /// The fit with a fill for the meter: how far it shrank, or how many
    /// of its lines it uses.
    static func meterFit(_ fit: CaptionFit) -> CaptionFit {
        guard fit.fill == 0, !fit.isEmpty else { return fit }
        var fit = fit
        let shrink = fit.size > 0 ? fit.fullSize / fit.size : 1
        let lines = Double(fit.lines.count) / Double(max(1, fit.maxLines))
        fit.fill = fit.fits ? (fit.isShrunk ? shrink : min(1, lines)) : max(shrink, lines) * 1.1
        return fit
    }
}
