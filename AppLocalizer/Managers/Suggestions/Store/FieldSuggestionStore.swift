//
//  FieldSuggestionStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Every app's field suggestions and what the person decided about them.
/// Store Page and App Information put their built-in checks' suggestions
/// here (`setBuiltIn`), assistants add theirs over MCP (`add`), and the
/// sections, the toolbar and the overview read them. Shared through the
/// SwiftUI environment, like `ChangeQueue`.
///
/// Rules:
/// - One open suggestion per field per source: a newer one from the same
///   source replaces the older.
/// - Dismissed and accepted suggestions stay out of the open ones; Restore
///   brings dismissed ones back.
/// - Whether a field already holds the value is up to the section, which
///   knows the field's current value (`shown(for:…)`).
@MainActor
@Observable
final class FieldSuggestionStore {
    private(set) var suggestions: [FieldSuggestion] = []
    private(set) var review = SuggestionReviewState()
    /// "Ask Claude Code…", while it waits or suggestions arrive.
    private(set) var request: AssistantSuggestionRequest?
    /// Set when the saved suggestions couldn't be read or written.
    private(set) var persistenceError: String?

    private var nextNumber = 1
    private let persistence: (any FieldSuggestionPersistence)?
    private let now: () -> Date

    init(persistence: (any FieldSuggestionPersistence)? = nil, suggestions: [FieldSuggestion] = [], now: @escaping () -> Date = Date.init) {
        self.persistence = persistence
        self.now = now
        self.suggestions = suggestions
        if let persistence, suggestions.isEmpty {
            do {
                let archive = try persistence.load()
                self.suggestions = archive.suggestions
                review = archive.review
                nextNumber = archive.nextNumber
            } catch {
                persistenceError = error.localizedDescription
            }
        }
    }

    // MARK: - Reading

    func isOpen(_ suggestion: FieldSuggestion) -> Bool {
        !review.dismissedIDs.contains(suggestion.id) && !review.acceptedIDs.contains(suggestion.id)
    }

    func isDismissed(_ suggestion: FieldSuggestion) -> Bool {
        review.dismissedIDs.contains(suggestion.id)
    }

    /// An app's suggestions in `scope` (every scope when nil), or in `area`.
    func all(for appID: StoreApp.ID, scope: SuggestionScope? = nil, area: SuggestionArea? = nil) -> [FieldSuggestion] {
        suggestions.filter { suggestion in
            suggestion.appID == appID
                && scope.map { suggestion.target.scope == $0 } ?? true
                && area.map { suggestion.target.scope.area == $0 } ?? true
        }
    }

    /// The open ones among `all`, from the sources `filter` shows.
    func open(for appID: StoreApp.ID, scope: SuggestionScope? = nil, area: SuggestionArea? = nil, filter: SuggestionSourceFilter = .all) -> [FieldSuggestion] {
        all(for: appID, scope: scope, area: area).filter { isOpen($0) && filter.includes($0.source) }
    }

    /// The suggestion a field shows: the newest open one `filter` lets
    /// through whose value isn't what the field already holds.
    func shown(for target: SuggestionTarget, appID: StoreApp.ID, currentValue: String, filter: SuggestionSourceFilter = .all) -> FieldSuggestion? {
        suggestions
            .filter { $0.appID == appID && $0.target == target && isOpen($0) && filter.includes($0.source) && $0.value != currentValue }
            .max { $0.createdAt < $1.createdAt }
    }

    func suggestion(id: FieldSuggestion.ID) -> FieldSuggestion? {
        suggestions.first { $0.id == id }
    }

    func provenance(for target: SuggestionTarget, appID: StoreApp.ID) -> SuggestionProvenance? {
        review.provenance[SuggestionFieldKey(appID: appID, target: target)]
    }

    // MARK: - Adding

    /// Replaces an app's built-in suggestions in `scopes` with what the
    /// checks found now. Decisions about the same value carry over, since
    /// built-in ids come from the value.
    func setBuiltIn(_ found: [FieldSuggestion], appID: StoreApp.ID, scopes: Set<SuggestionScope>) {
        let kept = suggestions.filter { !($0.appID == appID && $0.source == .builtIn && scopes.contains($0.target.scope)) }
        let current = Dictionary(suggestions.map { ($0.id, $0) }) { first, _ in first }
        // A check that finds the same thing keeps the date it first did, so
        // "newest first" doesn't reshuffle on every edit.
        let found = found.map { suggestion in
            var suggestion = suggestion
            if let existing = current[suggestion.id] { suggestion.createdAt = existing.createdAt }
            return suggestion
        }
        let updated = kept + found
        guard updated != suggestions else { return }
        suggestions = updated
        save()
    }

    /// An assistant's or the AI provider's suggestion. Replaces the open one
    /// from the same source for the same field; the same value again
    /// changes nothing.
    @discardableResult
    func add(
        appID: StoreApp.ID,
        target: SuggestionTarget,
        value: String,
        reason: String,
        source: SuggestionSource,
        evidence: [SuggestionEvidence] = []
    ) -> (suggestion: FieldSuggestion, outcome: SuggestionAddOutcome) {
        let sameField = suggestions.filter { $0.appID == appID && $0.target == target && $0.source == source && isOpen($0) }
        if let existing = sameField.first(where: { $0.value == value }) {
            return (existing, .unchanged)
        }
        let suggestion = FieldSuggestion(
            id: "sg_\(nextNumber)",
            appID: appID,
            target: target,
            value: value,
            reason: reason,
            source: source,
            evidence: evidence,
            createdAt: now()
        )
        nextNumber += 1
        let replacedIDs = Set(sameField.map(\.id))
        suggestions.removeAll { replacedIDs.contains($0.id) }
        suggestions.append(suggestion)
        noteArrival(of: suggestion)
        save()
        return (suggestion, replacedIDs.isEmpty ? .queued : .replaced)
    }

    // MARK: - Deciding

    func dismiss(_ ids: some Sequence<FieldSuggestion.ID>) {
        let ids = Set(ids)
        guard !ids.isSubset(of: review.dismissedIDs) else { return }
        review.dismissedIDs.formUnion(ids)
        save()
    }

    /// "Restore n Dismissed".
    func restore(_ ids: some Sequence<FieldSuggestion.ID>) {
        let ids = Set(ids)
        guard !ids.isDisjoint(with: review.dismissedIDs) else { return }
        review.dismissedIDs.subtract(ids)
        save()
    }

    /// The suggestion's value went into its field, which held
    /// `previousValue` before.
    func markAccepted(_ suggestion: FieldSuggestion, previousValue: String, isForEditing: Bool = false) {
        review.acceptedIDs.insert(suggestion.id)
        review.dismissedIDs.remove(suggestion.id)
        review.provenance[SuggestionFieldKey(appID: suggestion.appID, target: suggestion.target)] = SuggestionProvenance(
            suggestionID: suggestion.id,
            source: suggestion.source,
            value: suggestion.value,
            previousValue: previousValue,
            isForEditing: isForEditing
        )
        save()
    }

    /// The provenance line's Undo: the suggestion is open again. Returns
    /// what the field should go back to.
    func undoAcceptance(of target: SuggestionTarget, appID: StoreApp.ID) -> SuggestionProvenance? {
        let key = SuggestionFieldKey(appID: appID, target: target)
        guard let provenance = review.provenance.removeValue(forKey: key) else { return nil }
        review.acceptedIDs.remove(provenance.suggestionID)
        save()
        return provenance
    }

    /// Forgets who suggested values in `area` that are no longer waiting to
    /// be pushed (pushed, discarded, or typed back), so an edit made later
    /// doesn't read "Edited from …".
    func pruneProvenance(appID: StoreApp.ID, area: SuggestionArea, keeping pending: Set<SuggestionTarget>) {
        let stale = review.provenance.keys.filter { $0.appID == appID && $0.target.scope.area == area && !pending.contains($0.target) }
        guard !stale.isEmpty else { return }
        for key in stale {
            review.provenance.removeValue(forKey: key)
        }
        save()
    }

    /// Accept All's Undo puts every decision back.
    func restoreReview(_ state: SuggestionReviewState) {
        guard review != state else { return }
        review = state
        save()
    }

    // MARK: - Asking an assistant

    /// "Ask Claude Code…": the prompt is copied; suggestions from `client`
    /// for `appID` count toward the request from now on.
    func beginRequest(appID: StoreApp.ID, area: SuggestionArea, client: String, prompt: String) {
        request = AssistantSuggestionRequest(appID: appID, area: area, client: client, prompt: prompt, startedAt: now())
    }

    /// The assistant said how many it will send in all.
    func noteExpectedTotal(_ total: Int, client: String, appID: StoreApp.ID) {
        guard request?.client == client, request?.appID == appID, total > 0 else { return }
        request?.total = total
    }

    func cancelRequest() {
        request = nil
    }

    /// Ends the request and returns it, for the toast with the total.
    func finishRequest() -> AssistantSuggestionRequest? {
        defer { request = nil }
        return request
    }

    private func noteArrival(of suggestion: FieldSuggestion) {
        guard case let .assistant(client) = suggestion.source, request?.client == client, request?.appID == suggestion.appID else { return }
        request?.received += 1
    }

    // MARK: - Storage

    private func save() {
        guard let persistence else { return }
        do {
            try persistence.save(FieldSuggestionArchive(suggestions: suggestions, review: review, nextNumber: nextNumber))
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }
}
