//
//  ArtworkTextEditor.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The editor beside Captions for a Search results or Header cell: one
/// headline, written to the document a moment after typing pauses, its fit
/// on the artwork and its words, with the language's subtitle and keywords
/// to start the search headline from. For a phrase cell, the phrase's
/// words in that language, with the original words to start from.
@MainActor
@Observable
final class ArtworkTextEditor {
    @ObservationIgnored unowned let captions: CaptionsViewModel
    private(set) var selection: ArtworkTextKey?
    private(set) var headline = ""
    private(set) var hasPendingEdit = false
    @ObservationIgnored private var commitTask: Task<Void, Never>?

    init(captions: CaptionsViewModel) {
        self.captions = captions
    }

    private var screenshots: ScreenshotsViewModel { captions.screenshots }
    private var primary: String { screenshots.context.primaryLocale.code }

    // MARK: - Selection

    /// Opens the editor on a cell, closing the caption editor.
    func select(_ key: ArtworkTextKey?) {
        guard key != selection else { return }
        commitNow()
        if key != nil { captions.select(nil) }
        selection = key
        headline = key.map(current) ?? ""
        hasPendingEdit = false
    }

    func close() {
        select(nil)
    }

    var locale: StoreLocale? {
        selection.flatMap { screenshots.locale(code: $0.locale) }
    }

    /// What `key` holds now: the placement's text, or the phrase's words
    /// (in the primary language the page's own unless changed).
    private func current(_ key: ArtworkTextKey) -> String {
        let texts = screenshots.document?.artworkTexts
        guard let phrase = key.phrase else { return texts?.text(key.role, locale: key.locale)?.headline ?? "" }
        return texts?.phrase(phrase, locale: key.locale)?.headline ?? (key.locale == primary ? phrase : "")
    }

    var isPhrase: Bool { selection?.phrase != nil }

    /// "Search results · German", "Phrase 2 · German".
    var title: String {
        guard let selection else { return "" }
        let place = selection.phrase.flatMap { phrase in captions.artworkPhrases.firstIndex(of: phrase) }.map(ArtworkTextCell.phraseTitle)
        return "\(place ?? selection.role.title) · \(locale?.name ?? selection.locale)"
    }

    var guidance: String {
        guard let selection else { return "" }
        guard selection.phrase != nil else { return selection.role.guidance }
        let image = selection.role.title.lowercased()
        return selection.locale == primary
            ? String(localized: """
            Words the design wrote on the \(image) image. Change them here; every language translates from the \
            original words.
            """)
            : String(localized: """
            Words the design wrote on the \(image) image, in this language. Write them for its readers, not word by \
            word, and about as short: the box they go in doesn’t grow.
            """)
    }

    /// The field's prompt.
    var prompt: String {
        if isPhrase { return locale.map { String(localized: "The phrase in \($0.name)") } ?? "" }
        return selection?.role.isOptional == true ? String(localized: "None") : String(localized: "3–5 words")
    }

    var isRightToLeft: Bool {
        locale.map { ScreenshotScript(locale: $0).isRightToLeft } ?? false
    }

    /// The headline (or phrase) on its artwork, as typed.
    var fit: CaptionFit? {
        guard let selection, let locale, !headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if let phrase = selection.phrase { return captions.phraseFit(phrase, locale: locale, words: headline) }
        return captions.artworkFit(role: selection.role, locale: locale, headline: headline)
    }

    var count: ArtworkTextCount? {
        guard let selection, selection.phrase == nil, !headline.isEmpty else { return nil }
        return ArtworkTextCount(headline, role: selection.role, locale: selection.locale)
    }

    /// "4 words · at most 5" or the warning when it's over.
    var countDetail: String? {
        guard let count, let role = selection?.role else { return nil }
        let limit = String(localized: "at most \(role.maximumWords) words")
        return count.isTooLong
            ? String(localized: "\(count.title): longer than the \(limit) Apple’s small card reads at a glance")
            : "\(count.title) · \(limit)"
    }

    /// The language's subtitle and keywords, to start a search headline;
    /// a phrase's original words in another language.
    var sources: [(title: String, text: String)] {
        if let phrase = selection?.phrase {
            guard selection?.locale != primary else { return [] }
            let language = screenshots.locale(code: primary)?.name ?? primary
            return [(String(localized: "Original · \(language)"), phrase)]
        }
        guard let selection, selection.role == .search else { return [] }
        let texts = screenshots.studio.storeTexts
        var result: [(String, String)] = []
        if let subtitle = texts.subtitles[selection.locale], !subtitle.isEmpty { result.append((String(localized: "Subtitle"), subtitle)) }
        if let keywords = texts.keywords[selection.locale], !keywords.isEmpty { result.append((String(localized: "Keywords"), keywords)) }
        return result
    }

    // MARK: - Editing

    func setHeadline(_ text: String) {
        guard text != headline else { return }
        headline = text
        hasPendingEdit = true
        commitTask?.cancel()
        commitTask = Task { [weak self] in
            try? await Task.sleep(for: CaptionsViewModel.commitDelay)
            guard !Task.isCancelled else { return }
            await self?.commitEdits()
        }
    }

    /// Uses a source as the headline.
    func use(_ text: String) {
        setHeadline(text)
    }

    func commitEdits() async {
        guard let document = takePendingEdit() else { return }
        await screenshots.commit(document)
    }

    private func commitNow() {
        guard let document = takePendingEdit() else { return }
        Task { await screenshots.commit(document) }
    }

    /// The document with the headline written: written in the primary
    /// language, edited elsewhere; an empty one removes it. A phrase's
    /// words go in its versions; in the primary language, the original
    /// words again remove the change.
    private func takePendingEdit() -> ScreenshotsDocument? {
        commitTask?.cancel()
        commitTask = nil
        guard hasPendingEdit, let selection, var document = screenshots.document else { return nil }
        hasPendingEdit = false
        var texts = document.artworkTexts ?? ArtworkTextBook()
        let trimmed = headline.trimmingCharacters(in: .whitespacesAndNewlines)
        if let phrase = selection.phrase {
            let words = ArtworkTextBook.phraseKey(trimmed)
            guard words != ArtworkTextBook.phraseKey(current(selection)) else { return nil }
            let isOriginal = selection.locale == primary && words == phrase
            let caption = words.isEmpty || isOriginal ? nil : ScreenshotCaption(headline: words, subhead: nil, provenance: .edited)
            texts.setPhrase(caption, source: phrase, locale: selection.locale)
            document.artworkTexts = texts
            return document
        }
        guard trimmed != texts.headline(selection.role, locale: selection.locale) else { return nil }
        let provenance: CaptionProvenance = selection.locale == primary ? .written : .edited
        let caption = trimmed.isEmpty ? nil : ScreenshotCaption(headline: trimmed, subhead: nil, provenance: provenance)
        texts.set(caption, role: selection.role, locale: selection.locale)
        document.artworkTexts = texts
        return document
    }
}
