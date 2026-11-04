//
//  CaptionsViewModel+ArtworkTexts.swift
//  AppLocalizer
//

import Foundation

/// Captions' Search results and Header columns: each language's own text
/// for the header and search artwork, measured on the direction's look;
/// then a column per phrase Claude Design wrote on those pages, written in
/// the primary language and translated like the captions.
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

    /// The Claude Design pages the phrases come from: the made artwork's,
    /// else the chosen direction's once Localize read them.
    var artworkPhraseDesign: AutopilotArtworkDesign? {
        guard artworkSize != nil else { return nil }
        if let made = screenshots.document?.extras?.artworkDesign, !made.allPhrases().isEmpty { return made }
        return screenshots.studio.run?.chosenDirection?.artworkDesign
    }

    /// The pages' phrases in the primary language, a column each.
    var artworkPhrases: [String] {
        artworkPhraseDesign?.allPhrases() ?? []
    }

    func artworkCells(for locale: StoreLocale, isPrimary: Bool) -> [ArtworkTextCell] {
        let texts = screenshots.document?.artworkTexts ?? ArtworkTextBook()
        let placements = artworkRoles.map { role in
            let text = texts.text(role, locale: locale.code)
            return ArtworkTextCell(
                key: ArtworkTextKey(locale: locale.code, role: role), text: text,
                fit: text.flatMap { artworkFit(role: role, locale: locale, headline: $0.headline) }, isPrimary: isPrimary
            )
        }
        let design = artworkPhraseDesign
        let phrases = artworkPhrases.enumerated().map { index, source in
            let text = phraseText(source, locale: locale.code, isPrimary: isPrimary, in: texts)
            let kind = design?.kind(writing: source) ?? .search
            return ArtworkTextCell(
                key: ArtworkTextKey(locale: locale.code, role: ArtworkTextRole.role(for: kind), phrase: source), text: text,
                fit: text.flatMap { phraseFit(source, locale: locale, words: $0.headline) }, isPrimary: isPrimary, phraseIndex: index
            )
        }
        return placements + phrases
    }

    /// A phrase in a language: its words there; in the primary language
    /// the page's own, as the design source wrote them, unless changed.
    func phraseText(_ source: String, locale: String, isPrimary: Bool, in texts: ArtworkTextBook) -> ScreenshotCaption? {
        if let own = texts.phrase(source, locale: locale) { return own }
        guard isPrimary else { return nil }
        let direction = screenshots.studio.run?.chosenDirection
        let provenance: CaptionProvenance = direction.map {
            .assistant(client: $0.client ?? $0.sourceTitle, date: $0.receivedAt)
        } ?? .written
        return ScreenshotCaption(headline: source, subhead: nil, provenance: provenance)
    }

    /// The phrase with `words` on its page in `locale`, as WebKit fits it
    /// in its box; nil until it's measured.
    func phraseFit(_ source: String, locale: StoreLocale, words: String) -> CaptionFit? {
        guard let design = artworkPhraseDesign, let kind = design.kind(writing: source),
              let html = artworkPage(for: kind) ?? design.page(for: kind)
        else { return nil }
        let role = ArtworkTextRole.role(for: kind)
        let headline = screenshots.document?.artworkTexts?.headline(role, locale: locale.code) ?? ""
        let phrases = [source: words]
        let key = "text|" + Self.artworkPageFitKey(html: html, kind: kind, locale: locale.code, headline: headline, phrases: phrases)
        return measuredFit(key: key, request: pageRequest(html, kind: kind, locale: locale, headline: headline, phrases: phrases)) { measure in
            measure.elements(.text).first { ArtworkTextBook.phraseKey($0.source ?? "") == source }
        }
    }

    /// The Claude Design page the texts go on for `kind`: the artwork's
    /// own, else the chosen direction's.
    func artworkPage(for kind: AutopilotArtworkKind) -> String? {
        screenshots.document?.extras?.artworkDesign?.page(for: kind) ?? screenshots.studio.run?.chosenDirection?.artworkDesign?.page(for: kind)
    }

    /// The headline laid out on its artwork; nil without a look. On a
    /// Claude Design page it's WebKit's fit, nil until it's measured.
    func artworkFit(role: ArtworkTextRole, locale: StoreLocale, headline: String) -> CaptionFit? {
        guard let size = artworkSize else { return nil }
        if let html = artworkPage(for: role.kind(for: size)) {
            return pageFit(html, kind: role.kind(for: size), locale: locale, headline: headline)
        }
        guard let look = artworkLook else { return nil }
        let engine = ArtworkLayoutEngine(catalog: screenshots.services.fonts)
        let shows = screenshots.document?.extras?.artworkShows ?? screenshots.studio.run?.plan.alsoMakes.artworkShows ?? .phone
        let fit = engine.layout(look, kind: role.kind(for: size), locale: locale, headline: headline, slots: [0], shows: shows).headline
        return Self.meterFit(fit)
    }

    static func artworkPageFitKey(
        html: String, kind: AutopilotArtworkKind, locale: String, headline: String, phrases: [String: String] = [:]
    ) -> String {
        let words = phrases.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "|")
        return "\(kind.rawValue)|\(locale)|\(html.hashValue)|\(headline)|\(words.hashValue)"
    }

    /// The page's fit for `headline`, with the language's phrases on it,
    /// measured once in the background.
    private func pageFit(_ html: String, kind: AutopilotArtworkKind, locale: StoreLocale, headline: String) -> CaptionFit? {
        let phrases = screenshots.studio.artworkPhrases(in: locale.code)
        let key = Self.artworkPageFitKey(html: html, kind: kind, locale: locale.code, headline: headline, phrases: phrases)
        return measuredFit(key: key, request: pageRequest(html, kind: kind, locale: locale, headline: headline, phrases: phrases)) {
            $0.elements(.headline).first
        }
    }

    private func pageRequest(
        _ html: String, kind: AutopilotArtworkKind, locale: StoreLocale, headline: String, phrases: [String: String]
    ) -> ArtworkWebRequest {
        ArtworkWebRequest(
            html: html, kind: kind, locale: locale.code, isRightToLeft: locale.isRTL || ScreenshotScript(locale: locale).isRightToLeft,
            headline: headline, appName: screenshots.studio.appName(in: locale.code),
            primaryLocale: screenshots.studio.artworkPrimaryLocale, phrases: phrases
        )
    }

    /// The fit `element` reads off `request`'s page, measured once in the
    /// background under `key`.
    private func measuredFit(
        key: String, request: ArtworkWebRequest, element: @escaping @MainActor (ArtworkWebMeasure) -> ArtworkWebMeasure.Element?
    ) -> CaptionFit? {
        if let fit = artworkPageFits[key] { return fit }
        guard !artworkPagesMeasuring.contains(key) else { return nil }
        artworkPagesMeasuring.insert(key)
        Task { [weak self] in
            let measure = try? await ArtworkWebRenderer.shared.measure(request)
            // One that can't be measured stays unmeasured: no meter, no retry loop.
            guard let self, let measure, let found = element(measure) else { return }
            artworkPagesMeasuring.remove(key)
            artworkPageFits[key] = Self.meterFit(found.captionFit)
        }
        return nil
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
