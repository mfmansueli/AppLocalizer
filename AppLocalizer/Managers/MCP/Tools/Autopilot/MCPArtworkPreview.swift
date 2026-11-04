//
//  MCPArtworkPreview.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A run's Claude Design pages rendered in one language and checked the
/// way the artwork will be made: what render_artwork returns, and what
/// propose_direction and revise_direction send back (or refuse on).
@MainActor
struct MCPArtworkPreview {
    let session: MCPAutopilotSession
    let workspace: MCPWorkspace
    /// The preview image's width.
    var pixelWidth = 960

    /// One page as rendered and checked.
    struct Page {
        var kind: AutopilotArtworkKind
        var locale: StoreLocale
        var headline: String
        var render: ArtworkWebRender
        var checks: [ArtworkCheck]
    }

    /// The set's artwork texts: the placements' and the pages' phrases.
    func book() async -> ArtworkTextBook {
        let document = try? await session.context.services.loadDocument(for: session.app, primaryLocale: session.context.primaryLocale)
        return document?.artworkTexts ?? ArtworkTextBook()
    }

    /// The placement's text in `locale`: the one written, else for search
    /// the app's subtitle there.
    func headline(for kind: AutopilotArtworkKind, locale: StoreLocale, book: ArtworkTextBook? = nil) async -> String {
        let role = ArtworkTextRole.role(for: kind)
        let texts: ArtworkTextBook = if let book { book } else { await self.book() }
        let written = texts.headline(role, locale: locale.code) ?? ""
        guard written.isEmpty, role == .search else { return written }
        let profile = await AutopilotAppProfile.load(app: session.app, locales: [locale.code], in: workspace)
        return profile?.languages.first?.subtitle ?? profile?.subtitle ?? ""
    }

    /// `html` on `kind` in `locale`, with `headline` (else the
    /// placement's text) and the phrases `book` (else the set's) has in
    /// that language, rendered and checked; `screenshots` is the
    /// direction's screenshot look the header should continue (else the
    /// chosen direction's). A run without screenshots keeps the live set,
    /// so the header continues that.
    func render(
        html: String, kind: AutopilotArtworkKind, locale: StoreLocale, headline: String? = nil, screenshots: ScreenshotTemplate? = nil,
        book: ArtworkTextBook? = nil
    ) async throws -> Page {
        let texts: ArtworkTextBook = if let book { book } else { await self.book() }
        let line: String = if let headline { headline } else { await self.headline(for: kind, locale: locale, book: texts) }
        let pages = AutopilotArtworkPages(context: session.context)
        let request = await pages.request(
            html: html, kind: kind, locale: locale, headline: line, run: session.run, icon: pages.icon(), pixelWidth: pixelWidth,
            phrases: texts.phraseTexts(locale: locale.code)
        )
        let render = try await ArtworkWebRenderer.shared.render(request, behindText: true, checksMotion: session.run.plan.alsoMakes.makesMotion)
        let checks = await ArtworkChecker().checks(ArtworkCheckInput(
            kind: kind, locale: locale, image: render.image, geometry: ArtworkCheckGeometry(web: render, kind: kind), line: line,
            screenshotTemplate: screenshotLook(screenshots), page: render.measure, phrasesTranslateLater: true
        ))
        return Page(kind: kind, locale: locale, headline: line, render: render, checks: checks)
    }

    /// The screenshots the header sits above: `proposed` (else the chosen
    /// direction's), or the live set's when the run makes none.
    private func screenshotLook(_ proposed: ScreenshotTemplate?) async -> ScreenshotTemplate? {
        guard session.run.plan.makesScreenshots else {
            return try? await session.context.services.loadDocument(for: session.app, primaryLocale: session.context.primaryLocale).template
        }
        return proposed ?? session.run.chosenDirection?.template
    }

    /// What checking a design came to.
    struct Checked {
        var pages: [Page]
        /// Why it can't be used, nil when it can.
        var refusal: String?
        /// The design with each page's phrases read
        /// (`AutopilotArtworkDesign.phrases`), for Localize to translate.
        var design: AutopilotArtworkDesign
    }

    /// Each page of `design` in the primary language, and why it can't be
    /// used when it can't: it didn't render, a check found what Apple
    /// doesn't allow or a capture that didn't load, or its words won't
    /// read in every run language (`wordProblems`; with `book`, a
    /// variant's phrases must already be in every language there).
    /// A concept's pages need no headline: their words are the name and
    /// their own phrases (`requiresHeadline` false).
    func check(
        _ design: AutopilotArtworkDesign, screenshots: ScreenshotTemplate? = nil, book: ArtworkTextBook? = nil, requiresHeadline: Bool = true
    ) async -> Checked {
        var pages: [Page] = []
        var problems: [String] = []
        var read = design
        let texts: ArtworkTextBook = if let book { book } else { await self.book() }
        let plan = session.run.plan
        for kind in plan.artworkKinds {
            guard let html = design.page(for: kind) else { continue }
            do {
                let page = try await render(html: html, kind: kind, locale: session.context.primaryLocale, screenshots: screenshots, book: texts)
                pages.append(page)
                read.setPhrases(page.render.measure.phraseSources, for: kind)
                problems += page.checks.filter(\.isError).map(\.text)
                if requiresHeadline, page.render.measure.elements(.headline).isEmpty {
                    problems.append(String(localized: "The \(kind.rawValue) page has no data-al=\"headline\" element for the placement’s text."))
                }
                problems += Self.wordProblems(
                    page.render.measure, kind: kind, locales: plan.localeCodes, primary: plan.primaryLocale, book: book
                )
            } catch {
                problems.append(String(localized: "The \(kind.rawValue) page didn’t render: \(error.localizedDescription)"))
            }
        }
        return Checked(pages: pages, refusal: problems.isEmpty ? nil : problems.joined(separator: " "), design: read)
    }

    /// A page's words that wouldn't read in every one of `locales`: when
    /// the run has more than one language, words written outside every
    /// `data-al`; and, given `book` (a variant, made after Localize
    /// translated the rest), phrases with no words in some language there
    /// or on the page.
    static func wordProblems(
        _ measure: ArtworkWebMeasure, kind: AutopilotArtworkKind, locales: [String], primary: String, book: ArtworkTextBook? = nil
    ) -> [String] {
        var problems: [String] = []
        let stray = measure.strayText ?? []
        if locales.count > 1, !stray.isEmpty {
            let quoted = stray.map { "‘\(ArtworkCheckGeometry.snippet($0))’" }.joined(separator: ", ")
            problems.append(String(localized: """
            The \(kind.rawValue) page writes \(quoted) itself, so it reads the same in every language: put words in \
            data-al="text", written once in \(primary) (AppLocalizer translates them), or data-al="appName" for the app’s name.
            """))
        }
        if let book {
            for missing in measure.phrasesMissing(locales, primary: primary, book: book) {
                let text = ArtworkCheckGeometry.snippet(missing.text)
                problems.append(String(localized: """
                The \(kind.rawValue) page’s phrase ‘\(text)’ has no words yet in \(missing.locales.joined(separator: ", ")): \
                send them with phrases [{phrase, locale, text}].
                """))
            }
        }
        return problems
    }

    /// What a page came out as, for the assistant.
    static func json(_ page: Page) -> JSONValue {
        let measure = page.render.measure
        var json: [String: JSONValue] = [
            "kind": .string(page.kind.rawValue),
            "locale": .string(page.locale.code),
            "headline": .string(page.headline),
            "headlineFits": .bool(measure.headlineFits),
            "elements": .array(measure.elements.map(json)),
            "checks": .array(page.checks.map { .string("\($0.isError ? "Error" : "Advice"): \($0.text)") }),
        ]
        if let stray = measure.strayText, !stray.isEmpty { json["wordsOutsideDataAl"] = .array(stray.map { .string($0) }) }
        if !page.render.moving.isEmpty { json["moves"] = .array(page.render.moving.map { .string($0.rawValue) }) }
        let jumps = measure.motionsThatMayJump(loopSeconds: Double(AutopilotArtworkMotion.loopSeconds))
        if !jumps.isEmpty {
            json["motion"] = .string(String(localized: "\(jumps.count) animation(s) don’t repeat evenly in \(AutopilotArtworkMotion.loopSeconds) s, so the loop may jump."))
        }
        return .object(json)
    }

    /// One `data-al` element as the page laid it out.
    static func json(_ element: ArtworkWebMeasure.Element) -> JSONValue {
        var item: [String: JSONValue] = [
            "marker": .string(element.marker),
            "box": .string("\(Int(element.x)), \(Int(element.y)), \(Int(element.width)) × \(Int(element.height))"),
            "visible": .bool(element.isVisible),
        ]
        if let slot = element.slot { item["slot"] = .int(slot) }
        if let scale = element.fitScale, scale < 1 { item["shrunkTo"] = .string("\(Int((scale * 100).rounded()))%") }
        if element.kind?.isText == true { item["fits"] = .bool(element.fits) }
        if let loaded = element.isLoaded { item["loaded"] = .bool(loaded) }
        if let font = element.font { item["font"] = .string(font) }
        if element.kind == .text {
            item["text"] = .string(element.text ?? "")
            if let source = element.source { item["phrase"] = .string(source) }
            if let languages = element.languages, !languages.isEmpty { item["languages"] = .array(languages.map { .string($0) }) }
        }
        return .object(item)
    }

    /// The page's image for the assistant to see.
    static func image(_ page: Page) -> MCPToolOutcome.ImageContent? {
        ScreenshotPNG.data(page.render.image).map { MCPToolOutcome.ImageContent(data: $0, mimeType: "image/png") }
    }
}
