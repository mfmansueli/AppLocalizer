//
//  AutopilotCenter+ArtworkTexts.swift
//  AppLocalizer
//

import Foundation

/// Localize and check's placement texts: once every caption fits, each
/// language's search headline (and any header line) and the pages' own
/// phrases are checked, and the ones missing or too long go to the
/// assistant, like captions, before the artwork is made.
extension AutopilotCenter {
    /// The texts still to write; empty when the plan makes no artwork or
    /// they're all there and fit. The chosen direction's phrases are read
    /// off its pages first (`readPhrases`).
    func artworkTextNeeds(of run: AutopilotRun, in document: ScreenshotsDocument, context: AutopilotContext) async -> [AutopilotArtworkTextNeed] {
        guard run.plan.alsoMakes.makesArtwork, run.chosenDirection != nil || run.chosenConcept != nil else { return [] }
        let (run, document) = await readPhrases(of: run, in: document, context: context)
        guard let look = run.artworkLook(live: document.template) ?? Self.fallbackLook(for: context) else { return [] }
        let checker = AutopilotArtworkTextChecker(
            template: look, texts: document.artworkTexts ?? ArtworkTextBook(),
            size: run.plan.alsoMakes.artworkSize, catalog: context.services.fonts, shows: run.plan.alsoMakes.artworkShows,
            primaryLocale: run.plan.primaryLocale
        )
        guard let design = run.madeArtworkDesign, !design.isEmpty else { return checker.needs(locales: run.plan.localeCodes) }
        let pages = AutopilotArtworkPages(context: context)
        return await checker.needs(locales: run.plan.localeCodes, design: design) { html, kind, locale, headline, phrases in
            // Only the text's fit: the page without its captures or icon.
            let request = await pages.request(
                html: html, kind: kind, locale: locale, headline: headline, run: run, icon: nil, withCaptures: false, phrases: phrases
            )
            return try? await ArtworkWebRenderer.shared.measure(request)
        }
    }

    /// A starter's look, for a run with no direction and no live template.
    static func fallbackLook(for context: AutopilotContext) -> ScreenshotTemplate? {
        ScreenshotTemplate.starter(.above, id: context.app.id, title: context.app.name, slotCount: 1)
    }

    /// Texts the assistant sent: saved at once, then every language is
    /// checked again (`recheck`), unless captions sent with them do it.
    func applyArtworkTexts(
        _ updates: [AutopilotArtworkTextUpdate], client: String, appID: StoreApp.ID, context: AutopilotContext, recheck: Bool = true,
        waitsForExtras: Bool = true
    ) async throws {
        guard let run = runs[appID], run.stage == .localize else {
            throw AutopilotError(String(localized: "The run isn’t localizing now. Without run, propose_captions queues a proposal instead."))
        }
        guard !updates.isEmpty else { return }
        let localizer = AutopilotLocalizer(context: context, now: now())
        guard var document = await localizer.document() else {
            throw AutopilotError(String(localized: "AppLocalizer couldn’t open the screenshots to save them."))
        }
        var texts = document.artworkTexts ?? ArtworkTextBook()
        for update in updates {
            let text = update.headline.isEmpty
                ? nil
                : ScreenshotCaption(headline: update.headline, subhead: nil, provenance: .assistant(client: client, date: now()))
            if let phrase = update.phrase {
                texts.setPhrase(text, source: phrase, locale: update.locale)
            } else {
                texts.set(text, role: update.role, locale: update.locale)
            }
        }
        document.artworkTexts = texts
        try await context.services.saveDocument(document, for: context.app)
        update(appID) { run in
            let phrases = updates.filter { $0.phrase != nil }
            for item in updates where item.phrase == nil {
                let text = item.headline.isEmpty ? String(localized: "none") : "“\(item.headline)”"
                run.appendLog(String(localized: "\(client) wrote \(item.locale) \(item.role.title.lowercased()): \(text)"), kind: .event, at: now())
            }
            // Phrases come by the dozen: one line for them all.
            if !phrases.isEmpty {
                let languages = Set(phrases.map(\.locale)).count
                let what = phrases.count == 1 ? String(localized: "1 phrase") : String(localized: "\(phrases.count) phrases")
                let into = languages == 1 ? phrases[0].locale : String(localized: "\(languages) languages")
                run.appendLog(String(localized: "\(client) translated \(what) into \(into)"), kind: .event, at: now())
            }
        }
        if recheck { await check(appID, with: localizer, waitsForExtras: waitsForExtras) }
    }
}
