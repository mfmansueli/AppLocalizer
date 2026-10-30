//
//  StorePageViewModel+Suggestions.swift
//  AppLocalizer
//

import Foundation

// Field suggestions: the built-in checks run on the listing as shown, and
// everything open shows under its field in the editor. Accepting goes
// through `ListingFieldDraft.acceptSuggestion`, so the change is tagged with
// who suggested it until it's pushed or edited.
extension StorePageViewModel {
    /// Suggestions follow the version the overview is about: the editable
    /// one, else the live one when there's no other.
    var tracksSuggestions: Bool {
        guard let content else { return false }
        return content.editableVersion == nil || content.version.isEditable
    }

    /// Reruns the built-in checks and forgets who suggested values that
    /// aren't pending any more.
    func refreshSuggestions() {
        guard tracksSuggestions, let listing else { return }
        let shownScopes = listing.displayLocales.map { SuggestionScope.storePage($0) }
        let scopes = Set(suggestions.all(for: app.id, area: .storePage).map(\.target.scope)).union(shownScopes)
        suggestions.setBuiltIn(StorePageBuiltInSuggestions.suggestions(for: listing, appID: app.id), appID: app.id, scopes: scopes)
        let pending = listing.displayLocales.flatMap { locale in
            listing.fields.filter { listing.draft($0, in: locale).isPending }.map { SuggestionTarget.storePage(locale, $0) }
        }
        suggestions.pruneProvenance(appID: app.id, area: .storePage, keeping: Set(pending))
    }

    // MARK: - Reading

    /// The suggestion under a field: the newest open one the filter shows,
    /// unless the field already holds it.
    func shownSuggestion(_ field: ListingField, in locale: StoreLocale, filter: SuggestionSourceFilter? = nil) -> FieldSuggestion? {
        guard tracksSuggestions, canEdit(field), listing?.contains(locale) == true else { return nil }
        return suggestions.shown(for: .storePage(locale, field), appID: app.id, currentValue: value(field, in: locale), filter: filter ?? suggestionFilter)
    }

    /// "Accepted Claude Code’s suggestion." under a field, while its value
    /// waits to be pushed.
    func provenance(_ field: ListingField, in locale: StoreLocale) -> SuggestionProvenance? {
        guard tracksSuggestions, draft(field, in: locale).isPending else { return nil }
        return suggestions.provenance(for: .storePage(locale, field), appID: app.id)
    }

    /// One per field: what Accept All takes in `locale`.
    func visibleSuggestions(in locale: StoreLocale, filter: SuggestionSourceFilter? = nil) -> [FieldSuggestion] {
        (listing?.fields ?? []).compactMap { shownSuggestion($0, in: locale, filter: filter) }
    }

    /// The purple count next to a language in the picker.
    func suggestionCount(in locale: StoreLocale) -> Int {
        visibleSuggestions(in: locale, filter: .all).count
    }

    /// Every language's open suggestions, for the action bar.
    var totalSuggestionCount: Int {
        (listing?.displayLocales ?? []).reduce(0) { $0 + suggestionCount(in: $1) }
    }

    /// The editor's fields, or only those with a suggestion or a change
    /// when the bar's checkbox is on.
    func editorFields(in locale: StoreLocale) -> [ListingField] {
        let fields = listing?.fields ?? []
        guard showsOnlySuggestedFields else { return fields }
        return fields.filter { shownSuggestion($0, in: locale) != nil || draft($0, in: locale).isPending }
    }

    func suggestionBar(for locale: StoreLocale, assistant: String?) -> SuggestionBarModel {
        let scope = SuggestionScope.storePage(locale)
        let all = suggestions.all(for: app.id, scope: scope)
        let provenanceCount = (listing?.fields ?? []).count { provenance($0, in: locale) != nil }
        var counts: [SuggestionSourceFilter: Int] = [:]
        for filter in SuggestionSourceFilter.allCases where filter != .all {
            counts[filter] = visibleSuggestions(in: locale, filter: filter).count
        }
        let everywhere = (listing?.displayLocales ?? []).reduce(0) { $0 + visibleSuggestions(in: $1).count }
        return SuggestionBarModel(
            openCount: visibleSuggestions(in: locale, filter: .all).count,
            totalCount: all.count + provenanceCount,
            countsBySource: counts,
            assistantName: assistant ?? all.lazy.compactMap(\.source.assistantName).first,
            filter: suggestionFilter,
            dismissedCount: all.count(where: suggestions.isDismissed),
            everywhereCount: everywhere
        )
    }

    /// Under a suggestion: "75 / 100 bytes · frees 13", "29 / 30
    /// characters", "1,204 characters"; nil for URLs.
    func suggestionMeta(_ suggestion: FieldSuggestion) -> String? {
        guard let (field, locale) = storeField(of: suggestion), let limit = field.limit else { return nil }
        let suggested = limit.count(suggestion.value)
        switch limit.unit {
        case .bytes:
            let current = limit.count(value(field, in: locale))
            let change = current >= suggested
                ? String(localized: "frees \(current - suggested)")
                : String(localized: "uses \(suggested - current) more")
            return String(localized: "\(suggested.formatted()) / \(limit.maximum.formatted()) bytes · \(change)")
        case .characters where limit.maximum <= 170:
            return String(localized: "\(suggested.formatted()) / \(limit.maximum.formatted()) characters")
        case .characters:
            return String(localized: "\(suggested.formatted()) characters")
        }
    }

    /// "Lumen 1.4" and the primary language, for the Ask prompt.
    func suggestionPrompt() -> String {
        SuggestionPrompt.text(
            for: .storePage,
            app: app.name,
            version: content?.version.versionString,
            primaryLanguage: listing?.primaryLocale.name
        )
    }

    // MARK: - Deciding

    func acceptSuggestion(_ suggestion: FieldSuggestion) {
        guard let (field, _) = storeField(of: suggestion) else { return }
        accept([suggestion], toast: String(localized: "Accepted the \(field.title) suggestion. Nothing is pushed yet."))
    }

    /// "Use and Edit": the value goes in and the field takes focus.
    func useAndEditSuggestion(_ suggestion: FieldSuggestion) {
        guard let (field, locale) = storeField(of: suggestion) else { return }
        accept([suggestion], isForEditing: true, toast: nil)
        focusRequest = ListingFieldKey(locale, field)
    }

    func dismissSuggestion(_ suggestion: FieldSuggestion) {
        suggestions.dismiss([suggestion.id])
    }

    /// "Accept All (n)": what the filter shows in `locale`.
    func acceptAllSuggestions(in locale: StoreLocale) {
        let batch = visibleSuggestions(in: locale)
        let text = batch.count == 1
            ? String(localized: "Accepted 1 suggestion in \(locale.name). Nothing is pushed yet.")
            : String(localized: "Accepted \(batch.count) suggestions in \(locale.name). Nothing is pushed yet.")
        accept(batch, toast: text)
    }

    /// "Accept All n in Every Language".
    func acceptSuggestionsEverywhere() {
        let batch = (listing?.displayLocales ?? []).flatMap { visibleSuggestions(in: $0) }
        accept(batch, toast: String(localized: "Accepted \(batch.count) suggestions across languages. Nothing is pushed yet."))
    }

    /// "Dismiss All": what the filter shows in `locale`.
    func dismissAllSuggestions(in locale: StoreLocale) {
        suggestions.dismiss(visibleSuggestions(in: locale).map(\.id))
    }

    /// "Restore n Dismissed".
    func restoreDismissedSuggestions(in locale: StoreLocale) {
        let dismissed = suggestions.all(for: app.id, scope: .storePage(locale)).filter(suggestions.isDismissed)
        suggestions.restore(dismissed.map(\.id))
    }

    /// The provenance line's Undo: the field goes back to what it held
    /// before, and the suggestion is open again.
    func undoSuggestion(_ field: ListingField, in locale: StoreLocale) {
        guard var edited = listing, let provenance = suggestions.undoAcceptance(of: .storePage(locale, field), appID: app.id) else { return }
        edited.update(field, in: locale) { draft in
            if provenance.previousValue == draft.remote { draft.discard() } else { draft.edit(provenance.previousValue) }
        }
        commit(edited, replacing: [ListingFieldKey(locale, field)])
    }

    /// The toast's Undo, or Edit → Undo: the batch's fields and decisions
    /// as they were.
    func undoSuggestionBatch(_ undo: StorePageSuggestionUndo) {
        guard var edited = listing else { return }
        for (key, draft) in undo.drafts {
            edited.update(key.field, in: key.locale) { $0 = draft }
        }
        commit(edited, replacing: Array(undo.drafts.keys))
        suggestions.restoreReview(undo.review)
        if suggestionUndo == undo { suggestionUndo = nil }
        toast = nil
    }

    /// The toast's Undo.
    func undoLastSuggestionBatch() {
        guard let suggestionUndo else { return }
        undoManager?.removeAllActions(withTarget: self)
        undoSuggestionBatch(suggestionUndo)
    }

    // MARK: - Committing

    /// Commits, first dropping the queued changes of `keys`, so a value
    /// that changes hands (yours ↔ an assistant's) replaces the old one
    /// instead of becoming a conflict.
    func commit(_ edited: StoreListing, replacing keys: some Sequence<ListingFieldKey>) {
        if let builder = changeBuilder {
            queue.discard(ids: keys.flatMap { [builder.changeID(for: $0), builder.newLocaleChangeID(for: $0.locale, at: $0.field.level)] })
        }
        commit(edited)
    }

    // MARK: - Helpers

    /// Opens the editor on the first language with suggestions.
    func openSuggestions() {
        guard let listing else { return }
        let locale = listing.displayLocales.first { suggestionCount(in: $0) > 0 } ?? editorLocale ?? defaultEditorLocale
        if let locale { openEditor(locale) }
    }

    /// The field and language a Store Page suggestion is for.
    func storeField(of suggestion: FieldSuggestion) -> (ListingField, StoreLocale)? {
        guard case let .storePage(code) = suggestion.target.scope, let field = ListingField(rawValue: suggestion.target.field),
              let locale = StoreLocaleCatalog.locale(code: code) else { return nil }
        return (field, locale)
    }

    private func accept(_ batch: [FieldSuggestion], isForEditing: Bool = false, toast text: String?) {
        guard var edited = listing, !batch.isEmpty else { return }
        var undo = StorePageSuggestionUndo(drafts: [:], review: suggestions.review)
        var accepted: [(suggestion: FieldSuggestion, previous: String)] = []
        for suggestion in batch {
            guard let (field, locale) = storeField(of: suggestion), edited.canEdit(field) else { continue }
            let key = ListingFieldKey(locale, field)
            if undo.drafts[key] == nil { undo.drafts[key] = edited.draft(key) }
            let previous = edited.value(field, in: locale)
            edited.update(field, in: locale) { $0.acceptSuggestion(suggestion.value, from: suggestion.source.changeSource) }
            accepted.append((suggestion, previous))
        }
        guard !accepted.isEmpty else { return }
        commit(edited, replacing: Array(undo.drafts.keys))
        for item in accepted {
            suggestions.markAccepted(item.suggestion, previousValue: item.previous, isForEditing: isForEditing)
        }
        suggestionUndo = undo
        if let text { toast = ToastMessage(text: text, canUndo: true) }
        registerUndo(undo, name: accepted.count == 1 ? String(localized: "Accept Suggestion") : String(localized: "Accept Suggestions"))
    }

    private func registerUndo(_ undo: StorePageSuggestionUndo, name: String) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { model in
            MainActor.assumeIsolated { model.undoSuggestionBatch(undo) }
        }
        undoManager.setActionName(name)
    }
}
