//
//  AutopilotCenter+ArtworkTexts.swift
//  AppLocalizer
//

import Foundation

/// Localize and check's placement texts: once every caption fits, each
/// language's search headline (and any header line) is checked, and the
/// ones missing or too long go to the assistant, like captions, before the
/// artwork is made.
extension AutopilotCenter {
    /// The texts still to write; empty when the plan makes no artwork or
    /// they're all there and fit.
    func artworkTextNeeds(of run: AutopilotRun, in document: ScreenshotsDocument, context: AutopilotContext) -> [AutopilotArtworkTextNeed] {
        guard run.plan.alsoMakes.makesArtwork, let direction = run.chosenDirection else { return [] }
        return AutopilotArtworkTextChecker(
            template: direction.artworkLook, texts: document.artworkTexts ?? ArtworkTextBook(),
            size: run.plan.alsoMakes.artworkSize, catalog: context.services.fonts, shows: run.plan.alsoMakes.artworkShows
        ).needs(locales: run.plan.localeCodes)
    }

    /// Texts the assistant sent: saved at once, then every language is
    /// checked again (`recheck`), unless captions sent with them do it.
    func applyArtworkTexts(
        _ updates: [AutopilotArtworkTextUpdate], client: String, appID: StoreApp.ID, context: AutopilotContext, recheck: Bool = true
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
            texts.set(text, role: update.role, locale: update.locale)
        }
        document.artworkTexts = texts
        try await context.services.saveDocument(document, for: context.app)
        update(appID) { run in
            for item in updates {
                let text = item.headline.isEmpty ? String(localized: "none") : "“\(item.headline)”"
                run.appendLog(String(localized: "\(client) wrote \(item.locale) \(item.role.title.lowercased()): \(text)"), kind: .event, at: now())
            }
        }
        if recheck { await check(appID, with: localizer) }
    }
}
