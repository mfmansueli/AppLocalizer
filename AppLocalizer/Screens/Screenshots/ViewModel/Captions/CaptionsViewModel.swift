//
//  CaptionsViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Captions tab (design README §2 "Captions"): the locales × slots
/// table with a fit meter in each cell, and the editor for the selected
/// caption.
///
/// Edits are local document edits: the renders change and part 4's push
/// picks them up. They're written half a second after the last keystroke,
/// and at once when the selection changes or the editor closes.
@MainActor
@Observable
final class CaptionsViewModel {
    unowned let screenshots: ScreenshotsViewModel

    var filter: CaptionsFilter = .all
    private(set) var selection: LocaleSlot?
    /// The editor's fields.
    private(set) var headline = ""
    private(set) var subhead = ""
    /// The fields differ from what's saved.
    private(set) var hasPendingEdit = false
    /// Set by "Suggest a Shorter Version".
    var suggestion: CaptionSuggestion?
    var isSuggesting = false
    /// Why there's no shorter version.
    var suggestionMessage: String?
    var isTranslateSheetPresented = false
    @ObservationIgnored private var commitTask: Task<Void, Never>?

    /// How long typing pauses before the caption is written.
    static let commitDelay: Duration = .milliseconds(500)

    /// Translate Missing….
    @ObservationIgnored lazy var translation = CaptionTranslationViewModel(screenshots: screenshots)

    init(screenshots: ScreenshotsViewModel) {
        self.screenshots = screenshots
    }

    private var document: ScreenshotsDocument? { screenshots.document }
    private var primary: StoreLocale { screenshots.context.primaryLocale }

    // MARK: - The table

    var slotCount: Int { document?.slotCount ?? 5 }

    /// The localized sets, the primary locale first, then by name.
    var allRows: [CaptionsRow] {
        guard let document else { return [] }
        let codes = document.scope.orderedLocales(in: screenshots.locales.map(\.code))
        let locales = codes.compactMap(screenshots.locale(code:))
        let others = locales.filter { $0 != primary }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return ([primary] + others).map(row(for:))
    }

    /// The rows the filter shows.
    var rows: [CaptionsRow] {
        filter == .all ? allRows : allRows.filter(\.needsAttention)
    }

    /// Locales outside the scope, for "NOT LOCALIZED 27 · Add Locales…".
    var notLocalizedCount: Int {
        screenshots.locales.count - (document?.scope.count ?? 1)
    }

    private func row(for locale: StoreLocale) -> CaptionsRow {
        let isPrimary = locale == primary
        let cells = (0..<slotCount).map { slot in
            let key = LocaleSlot(locale: locale.code, slot: slot)
            let caption = document?.captions.caption(locale: locale.code, slot: slot)
            return CaptionsCell(
                key: key, caption: caption, fit: caption.flatMap { screenshots.fit(of: $0, at: key) }, isPrimary: isPrimary,
                showsSubhead: document?.template?.isHero(slot: slot) ?? (slot == 0),
                proposalClient: document?.proposal(locale: locale.code, slot: slot)?.client
            )
        }
        return CaptionsRow(locale: locale, isPrimary: isPrimary, cells: cells)
    }

    /// "12 locales × 5 slots · 1 overflow · 9 machine-translated · 0
    /// missing".
    var stats: String {
        let cells = allRows.flatMap(\.cells)
        let overflow = cells.count(where: \.isOverflowing)
        let machine = cells.count(where: \.isMachineTranslated)
        let missing = cells.count(where: \.isMissing)
        return String(localized: "\(allRows.count) locales × \(slotCount) slots · \(overflow) overflow · \(machine) machine-translated · \(missing) missing")
    }

    /// "1 Today", and whether the slot has a subhead.
    func slotHeader(_ slot: Int) -> (name: String, hasSubhead: Bool) {
        (document?.slotName(slot) ?? "", document?.template?.isHero(slot: slot) ?? (slot == 0))
    }

    // MARK: - Selection

    /// Opens the editor on a caption, writing the one being edited first.
    func select(_ key: LocaleSlot?) {
        guard key != selection else { return }
        commitNow()
        selection = key
        suggestion = nil
        suggestionMessage = nil
        let caption = key.flatMap { document?.captions.caption(locale: $0.locale, slot: $0.slot) }
        headline = caption?.headline ?? ""
        subhead = caption?.subhead ?? ""
        hasPendingEdit = false
    }

    /// The ×: writes the edit and closes the editor.
    func close() {
        select(nil)
    }

    var selectedLocale: StoreLocale? {
        selection.flatMap { screenshots.locale(code: $0.locale) }
    }

    /// The saved caption of the selection.
    var selectedCaption: ScreenshotCaption? {
        selection.flatMap { document?.captions.caption(locale: $0.locale, slot: $0.slot) }
    }

    // MARK: - Editing

    func setHeadline(_ text: String) {
        guard text != headline else { return }
        headline = text
        edited()
    }

    func setSubhead(_ text: String) {
        guard text != subhead else { return }
        subhead = text
        edited()
    }

    private func edited() {
        hasPendingEdit = true
        suggestion = nil
        commitTask?.cancel()
        commitTask = Task { [weak self] in
            try? await Task.sleep(for: Self.commitDelay)
            guard !Task.isCancelled else { return }
            await self?.commitEdits()
        }
    }

    /// The caption the fields make: tagged written for the primary locale,
    /// edited elsewhere. Nil when the headline is empty.
    var editedCaption: ScreenshotCaption? {
        guard let selection, !headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let provenance: CaptionProvenance = selection.locale == primary.code ? .written : .edited
        let trimmedSubhead = subhead.trimmingCharacters(in: .whitespacesAndNewlines)
        return ScreenshotCaption(headline: headline, subhead: trimmedSubhead.isEmpty ? nil : subhead, provenance: provenance)
    }

    /// Writes the fields to the document, if they changed.
    func commitEdits() async {
        guard let document = takePendingEdit() else { return }
        await screenshots.commit(document)
    }

    /// Writes a pending edit without waiting, when the editor moves on.
    private func commitNow() {
        guard let document = takePendingEdit() else { return }
        Task { await screenshots.commit(document) }
    }

    /// The document with the fields written, read now, before the
    /// selection can change; nil when nothing changed.
    private func takePendingEdit() -> ScreenshotsDocument? {
        commitTask?.cancel()
        commitTask = nil
        guard hasPendingEdit, let selection, var document = screenshots.document else { return nil }
        hasPendingEdit = false
        let saved = document.captions.caption(locale: selection.locale, slot: selection.slot)
        let caption = editedCaption
        guard caption?.renderText != saved?.renderText else { return nil }
        document.captions.setCaption(caption, locale: selection.locale, slot: selection.slot)
        return document
    }

    /// Shows `caption` in the fields as saved, dropping any pending edit.
    func showSaved(_ caption: ScreenshotCaption) {
        commitTask?.cancel()
        commitTask = nil
        headline = caption.headline
        subhead = caption.subhead ?? ""
        hasPendingEdit = false
        suggestion = nil
    }

    /// Mark Reviewed: the MT tag goes, the text stays.
    func markReviewed() async {
        await commitEdits()
        guard let selection, var document = screenshots.document,
              var caption = document.captions.caption(locale: selection.locale, slot: selection.slot) else { return }
        caption.provenance = .reviewed
        document.captions.setCaption(caption, locale: selection.locale, slot: selection.slot)
        await screenshots.commit(document)
    }
}
