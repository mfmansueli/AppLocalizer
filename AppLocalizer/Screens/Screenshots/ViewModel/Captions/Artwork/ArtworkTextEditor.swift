//
//  ArtworkTextEditor.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The editor beside Captions for a Search results or Header cell: one
/// headline, written to the document a moment after typing pauses, its fit
/// on the artwork and its words, with the language's subtitle and keywords
/// to start the search headline from.
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
        headline = key.flatMap { screenshots.document?.artworkTexts?.text($0.role, locale: $0.locale)?.headline } ?? ""
        hasPendingEdit = false
    }

    func close() {
        select(nil)
    }

    var locale: StoreLocale? {
        selection.flatMap { screenshots.locale(code: $0.locale) }
    }

    /// "Search results · German".
    var title: String {
        guard let selection else { return "" }
        return "\(selection.role.title) · \(locale?.name ?? selection.locale)"
    }

    var guidance: String { selection?.role.guidance ?? "" }

    var isRightToLeft: Bool {
        locale.map { ScreenshotScript(locale: $0).isRightToLeft } ?? false
    }

    /// The headline on its artwork, as typed.
    var fit: CaptionFit? {
        guard let selection, let locale, !headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return captions.artworkFit(role: selection.role, locale: locale, headline: headline)
    }

    var count: ArtworkTextCount? {
        guard let selection, !headline.isEmpty else { return nil }
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

    /// The language's subtitle and keywords, to start a search headline.
    var sources: [(title: String, text: String)] {
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
    /// language, edited elsewhere; an empty one removes it.
    private func takePendingEdit() -> ScreenshotsDocument? {
        commitTask?.cancel()
        commitTask = nil
        guard hasPendingEdit, let selection, var document = screenshots.document else { return nil }
        hasPendingEdit = false
        var texts = document.artworkTexts ?? ArtworkTextBook()
        let trimmed = headline.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != texts.headline(selection.role, locale: selection.locale) else { return nil }
        let provenance: CaptionProvenance = selection.locale == primary ? .written : .edited
        let caption = trimmed.isEmpty ? nil : ScreenshotCaption(headline: trimmed, subhead: nil, provenance: provenance)
        texts.set(caption, role: selection.role, locale: selection.locale)
        document.artworkTexts = texts
        return document
    }
}
