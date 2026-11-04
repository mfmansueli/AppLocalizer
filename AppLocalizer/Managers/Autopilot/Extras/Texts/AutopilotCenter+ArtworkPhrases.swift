//
//  AutopilotCenter+ArtworkPhrases.swift
//  AppLocalizer
//

import Foundation

/// The phrases Claude Design wrote on the chosen direction's header and
/// search pages (`data-al="text"`), written once in the primary language
/// and translated by AppLocalizer like captions: Localize reads them off
/// the pages before checking every language.
extension AutopilotCenter {
    /// Reads each of the chosen direction's pages in the primary language:
    /// its phrases go on the direction (`AutopilotArtworkDesign.phrases`),
    /// and the versions a page from before carries itself go into the book
    /// where it has none, as the design source wrote them, so the person
    /// reviews them in Captions like the rest. The run and document as they
    /// are after.
    /// Who wrote the pages' phrases: the chosen concept's or direction's
    /// designer.
    static func phraseProvenance(of run: AutopilotRun) -> CaptionProvenance {
        if run.usesConcepts, let concept = run.chosenConcept {
            return .assistant(client: concept.client ?? concept.source.title, date: concept.receivedAt)
        }
        let direction = run.chosenDirection
        return .assistant(client: direction?.client ?? direction?.sourceTitle ?? "", date: direction?.receivedAt ?? .now)
    }

    func readPhrases(
        of run: AutopilotRun, in document: ScreenshotsDocument, context: AutopilotContext
    ) async -> (run: AutopilotRun, document: ScreenshotsDocument) {
        guard let made = run.madeArtworkDesign, !made.isEmpty,
              let primary = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)
        else { return (run, document) }
        var design = made
        var book = document.artworkTexts ?? ArtworkTextBook()
        let pages = AutopilotArtworkPages(context: context)
        let provenance = Self.phraseProvenance(of: run)
        for kind in run.plan.artworkKinds {
            guard let html = design.page(for: kind) else { continue }
            let request = await pages.request(html: html, kind: kind, locale: primary, headline: "", run: run, icon: nil, withCaptures: false)
            guard let measure = try? await ArtworkWebRenderer.shared.measure(request) else { continue }
            design.setPhrases(measure.phraseSources, for: kind)
            for element in measure.elements(.text) {
                Self.importVersions(of: element, locales: run.plan.localeCodes, primary: primary.code, provenance: provenance, into: &book)
            }
        }
        var updated = run
        if design != made {
            update(run.appID) { $0.setMadeArtworkDesign(design) }
            updated.setMadeArtworkDesign(design)
        }
        var saved = document
        if book != (document.artworkTexts ?? ArtworkTextBook()) {
            saved.artworkTexts = book
            try? await context.services.saveDocument(saved, for: context.app)
        }
        return (updated, saved)
    }

    /// A page's own versions of a phrase, for the run's languages the book
    /// has none in.
    static func importVersions(
        of element: ArtworkWebMeasure.Element, locales: [String], primary: String, provenance: CaptionProvenance, into book: inout ArtworkTextBook
    ) {
        let source = ArtworkTextBook.phraseKey(element.source ?? "")
        guard !source.isEmpty, let versions = element.versions, !versions.isEmpty else { return }
        for code in locales where code != primary && book.phrase(source, locale: code) == nil {
            guard let lang = ArtworkWebTextVersions.version(in: Array(versions.keys), for: code),
                  let words = versions[lang].map(ArtworkTextBook.phraseKey), !words.isEmpty
            else { continue }
            book.setPhrase(ScreenshotCaption(headline: words, subhead: nil, provenance: provenance), source: source, locale: code)
        }
    }
}
