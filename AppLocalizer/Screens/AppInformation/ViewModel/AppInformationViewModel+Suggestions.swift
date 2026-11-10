//
//  AppInformationViewModel+Suggestions.swift
//  AppLocalizer
//

import Foundation

// Field suggestions on General, Age Rating, Accessibility and App Review:
// the built-in checks run on the values as shown, and everything open shows
// under its field, question or feature. Accepting queues the change tagged
// with who suggested it (`+SuggestionSlots` writes it), until it's pushed
// or edited.
extension AppInformationViewModel {
    /// Reruns the built-in checks and forgets who suggested values that
    /// aren't pending any more.
    func refreshSuggestions() {
        guard let content else { return }
        let values = suggestionValues
        var found = AppInformationBuiltInSuggestions.suggestions(
            general: values.general,
            review: values.review,
            version: content.version,
            previous: previousReview,
            appID: app.id
        )
        let advertising = canSuggest(.ageRating(.advertising)) ? AppInformationBuiltInSuggestions.advertising(
            current: suggestionValue(.ageRating(.advertising)),
            worksheet: privacy.worksheet,
            appID: app.id
        ) : nil
        if let advertising { found.append(advertising) }
        let scopes = AppInformationSuggestionField.pages.map { SuggestionScope.appInformation($0) } + [.appInformation(.ageRating)]
        suggestions.setBuiltIn(found, appID: app.id, scopes: Set(scopes))
        var pending = Set(allSuggestionSlots.filter(isPending).map(\.target))
        if accessibility.value == nil {
            // Accessibility loads on its own: keep its lines until it has.
            let kept = suggestions.review.provenance.keys.filter { key in
                guard key.appID == app.id, case .accessibility = key.target.scope else { return false }
                return true
            }
            pending.formUnion(kept.map(\.target))
        }
        suggestions.pruneProvenance(appID: app.id, area: .appInformation, keeping: pending)
        noteShownSuggestions()
    }

    /// Tells the store what this section shows, for its badge. Accessibility
    /// loads on its own: until it has, its suggestions stay counted.
    private func noteShownSuggestions() {
        let shown = Self.suggestionPages.flatMap { visibleSuggestions(on: $0, filter: .all) }
        let undecided = accessibility.value == nil
            ? suggestions.open(for: app.id, area: .appInformation).filter { $0.target.scope.page == .accessibility }
            : []
        suggestions.noteShown(shown + undecided, appID: app.id, area: .appInformation)
    }

    // MARK: - Reading

    /// The field's value as shown, as stored (a category by id).
    func suggestionValue(_ field: AppInformationSuggestionField) -> String {
        suggestionValue(.field(field))
    }

    func canSuggest(_ field: AppInformationSuggestionField) -> Bool {
        canSuggest(.field(field))
    }

    /// The suggestion under a field, question or feature: the newest open
    /// one the filter shows, unless it already holds that value.
    func shownSuggestion(_ slot: AppInformationSuggestionSlot, filter: SuggestionSourceFilter? = nil) -> FieldSuggestion? {
        guard canSuggest(slot) else { return nil }
        return suggestions.shown(for: slot.target, appID: app.id, currentValue: suggestionValue(slot), filter: filter ?? suggestionFilter)
    }

    func shownSuggestion(_ field: AppInformationSuggestionField, filter: SuggestionSourceFilter? = nil) -> FieldSuggestion? {
        shownSuggestion(.field(field), filter: filter)
    }

    /// "Accepted Claude Code’s suggestion." under it, while its value
    /// waits to be pushed.
    func provenance(_ slot: AppInformationSuggestionSlot) -> SuggestionProvenance? {
        guard isPending(slot) else { return nil }
        return suggestions.provenance(for: slot.target, appID: app.id)
    }

    func provenance(_ field: AppInformationSuggestionField) -> SuggestionProvenance? {
        provenance(.field(field))
    }

    /// One per field: what Accept All takes in `scope`.
    func visibleSuggestions(in scope: SuggestionScope, filter: SuggestionSourceFilter? = nil) -> [FieldSuggestion] {
        suggestionSlots(in: scope).compactMap { shownSuggestion($0, filter: filter) }
    }

    func visibleSuggestions(on page: AppInformationPage, filter: SuggestionSourceFilter? = nil) -> [FieldSuggestion] {
        suggestionScopes(on: page).flatMap { visibleSuggestions(in: $0, filter: filter) }
    }

    func suggestionCount(in scope: SuggestionScope) -> Int {
        visibleSuggestions(in: scope, filter: .all).count
    }

    /// "2 suggestions" under a page in the page column; Accessibility's
    /// devices together.
    func suggestionCount(on page: AppInformationPage) -> Int {
        visibleSuggestions(on: page, filter: .all).count
    }

    // MARK: - Suggest Everything

    /// Suggest Everything for this app, while it receives.
    var suggestionRun: SuggestionRun? {
        guard let run = suggestions.run, run.appID == app.id, run.isRunning else { return nil }
        return run
    }

    /// The run still owes it a suggestion: its striped placeholder.
    func isComing(_ slot: AppInformationSuggestionSlot) -> Bool {
        suggestionRun?.isComing(slot.target) == true
    }

    /// Next to a device: how many the run still owes it.
    func comingCount(in scope: SuggestionScope) -> Int {
        suggestionRun?.comingCount(in: [scope]) ?? 0
    }

    /// "· 4 coming" under a page in the page column.
    func comingCount(on page: AppInformationPage) -> Int {
        guard Self.suggestionPages.contains(page) else { return 0 }
        return suggestionRun?.comingCount(in: suggestionScopes(on: page)) ?? 0
    }

    /// Whether the page shows the suggestion bar: General, Age Rating,
    /// Accessibility and App Review, once loaded.
    func showsSuggestions(on page: AppInformationPage) -> Bool {
        isLoaded && Self.suggestionPages.contains(page)
    }

    /// The pages that take suggestions, in the page column's order.
    static let suggestionPages: [AppInformationPage] = [.general, .ageRating, .accessibility, .appReview]

    /// With "Only fields with suggestions or changes" on, a field shows
    /// only while it has one or a change.
    func showsField(_ slot: AppInformationSuggestionSlot) -> Bool {
        !showsOnlySuggestedFields || shownSuggestion(slot) != nil || isPending(slot) || isComing(slot)
    }

    func showsField(_ field: AppInformationSuggestionField) -> Bool {
        showsField(.field(field))
    }

    func suggestionBar(for scope: SuggestionScope, assistant: String?) -> SuggestionBarModel {
        let all = suggestions.all(for: app.id, scope: scope)
        let provenanceCount = suggestionSlots(in: scope).count { provenance($0) != nil }
        var counts: [SuggestionSourceFilter: Int] = [:]
        for filter in SuggestionSourceFilter.allCases where filter != .all {
            counts[filter] = visibleSuggestions(in: scope, filter: filter).count
        }
        return SuggestionBarModel(
            openCount: suggestionCount(in: scope),
            totalCount: all.count + provenanceCount,
            countsBySource: counts,
            assistantName: assistant ?? all.lazy.compactMap(\.source.assistantName).first,
            filter: suggestionFilter,
            dismissedCount: all.count(where: suggestions.isDismissed)
        )
    }

    func suggestionBar(for page: AppInformationPage, assistant: String?) -> SuggestionBarModel {
        suggestionBar(for: .appInformation(page), assistant: assistant)
    }

    /// Under a Notes suggestion: "1,204 / 4,000 characters"; nil elsewhere.
    func suggestionMeta(_ suggestion: FieldSuggestion) -> String? {
        guard let field = infoField(of: suggestion), let limit = field.limit else { return nil }
        return String(localized: "\(suggestion.value.count.formatted()) / \(limit.formatted()) characters")
    }

    /// "Lumen 1.4" and the page, for the Ask prompt.
    func suggestionPrompt() -> String {
        SuggestionPrompt.text(for: .appInformation, app: app.name, version: content?.version?.versionString, primaryLanguage: nil)
    }

    // MARK: - Deciding

    func acceptSuggestion(_ suggestion: FieldSuggestion) {
        guard let slot = slot(of: suggestion) else { return }
        accept([suggestion], toast: String(localized: "\(slot.title) accepted. It’s in Review & Push."))
    }

    /// "Use and Edit": the value goes in and the field takes focus.
    func useAndEditSuggestion(_ suggestion: FieldSuggestion) {
        guard let field = infoField(of: suggestion) else { return }
        accept(
            [suggestion],
            isForEditing: true,
            toast: String(localized: "Copied into the field. Edit it there; your version goes to Review & Push."),
            offersReview: false
        )
        focusRequest = field
    }

    func dismissSuggestion(_ suggestion: FieldSuggestion) {
        suggestions.dismiss([suggestion.id])
        suggestionToast = ToastMessage(text: String(localized: "Dismissed. It won’t come back unless the text changes."))
    }

    /// What the filter shows in `scope`, e.g. one device.
    func acceptAllSuggestions(in scope: SuggestionScope) {
        let batch = visibleSuggestions(in: scope)
        let text = batch.count == 1
            ? String(localized: "Accepted 1 on \(scope.title). It’s in Review & Push.")
            : String(localized: "Accepted \(batch.count) on \(scope.title). They’re in Review & Push.")
        accept(batch, toast: text)
    }

    func acceptAllSuggestions(on page: AppInformationPage) {
        acceptAllSuggestions(in: .appInformation(page))
    }

    /// "Dismiss All": what the filter shows in `scope`.
    func dismissAllSuggestions(in scope: SuggestionScope) {
        suggestions.dismiss(visibleSuggestions(in: scope).map(\.id))
    }

    func dismissAllSuggestions(on page: AppInformationPage) {
        dismissAllSuggestions(in: .appInformation(page))
    }

    /// "Restore n Dismissed".
    func restoreDismissedSuggestions(in scope: SuggestionScope) {
        let dismissed = suggestions.all(for: app.id, scope: scope).filter(suggestions.isDismissed)
        suggestions.restore(dismissed.map(\.id))
    }

    func restoreDismissedSuggestions(on page: AppInformationPage) {
        restoreDismissedSuggestions(in: .appInformation(page))
    }

    /// The provenance line's Undo: it goes back to what it held before, and
    /// the suggestion is open again.
    func undoSuggestion(_ slot: AppInformationSuggestionSlot) {
        guard let provenance = suggestions.undoAcceptance(of: slot.target, appID: app.id) else { return }
        _ = write(slot, provenance.previousValue, source: .you)
    }

    func undoSuggestion(_ field: AppInformationSuggestionField) {
        undoSuggestion(.field(field))
    }

    /// The toast's Undo, or Edit → Undo: the batch's changes and decisions
    /// as they were.
    func undoSuggestionBatch(_ undo: AppInformationSuggestionUndo) {
        for (id, change) in undo.changes {
            queue.discard(id: id)
            if let change { queue.upsert(change) }
        }
        suggestions.restoreReview(undo.review)
        refreshSuggestions()
        if suggestionUndo == undo { suggestionUndo = nil }
        suggestionToast = nil
    }

    /// The toast's Undo.
    func undoLastSuggestionBatch() {
        guard let suggestionUndo else { return }
        undoManager?.removeAllActions(withTarget: self)
        undoSuggestionBatch(suggestionUndo)
    }

    // MARK: - Helpers

    /// Opens the first page with suggestions (General when none has any),
    /// and on Accessibility the first device with some.
    func openSuggestions() {
        openSuggestions(on: Self.suggestionPages.first { suggestionCount(on: $0) > 0 } ?? .general)
    }

    /// Opens `page`, and on Accessibility the first device with
    /// suggestions.
    func openSuggestions(on page: AppInformationPage) {
        self.page = page
        if page == .accessibility, let family = accessibilitySuggestionFamilies.first(where: { suggestionCount(in: .accessibility($0)) > 0 }) {
            accessibilitySuggestionFamily = family
        }
    }

    /// The field an App Information suggestion is for, on General or App
    /// Review.
    func infoField(of suggestion: FieldSuggestion) -> AppInformationSuggestionField? {
        guard case let .field(field) = slot(of: suggestion) else { return nil }
        return field
    }

    func slot(of suggestion: FieldSuggestion) -> AppInformationSuggestionSlot? {
        AppInformationSuggestionSlot(target: suggestion.target)
    }

    /// Accepts a batch as one step: the toast's Undo, or Edit → Undo, puts
    /// back exactly what it changed.
    func accept(_ batch: [FieldSuggestion], isForEditing: Bool = false, toast text: String?, offersReview: Bool = true) {
        var undo = AppInformationSuggestionUndo(changes: [:], review: suggestions.review)
        var accepted: [(suggestion: FieldSuggestion, previous: String)] = []
        for suggestion in batch {
            guard let slot = slot(of: suggestion), canSuggest(slot) else { continue }
            let previousValue = suggestionValue(slot)
            guard let written = write(slot, suggestion.value, source: suggestion.source.changeSource) else { continue }
            if !undo.changes.keys.contains(written.id) { undo.changes.updateValue(written.previous, forKey: written.id) }
            accepted.append((suggestion, previousValue))
        }
        guard !accepted.isEmpty else { return }
        for item in accepted {
            suggestions.markAccepted(item.suggestion, previousValue: item.previous, isForEditing: isForEditing)
        }
        suggestionUndo = undo
        if let text { suggestionToast = ToastMessage(text: text, canUndo: true, actionTitle: offersReview ? String(localized: "Review & Push") : nil) }
        registerUndo(undo, name: accepted.count == 1 ? String(localized: "Accept Suggestion") : String(localized: "Accept Suggestions"))
    }

    private func registerUndo(_ undo: AppInformationSuggestionUndo, name: String) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { model in
            MainActor.assumeIsolated { model.undoSuggestionBatch(undo) }
        }
        undoManager.setActionName(name)
    }
}
