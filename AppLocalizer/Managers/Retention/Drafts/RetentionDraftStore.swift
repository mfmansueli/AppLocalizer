//
//  RetentionDraftStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The editor's copies of retention messages while AppLocalizer runs: new
/// messages and edits that aren't in Review & Push yet, so they survive
/// going to another section and back, and the full copy of a queued one
/// (Review & Push keeps what it sends; this keeps the thumbnail and
/// such). Assistants' shorter wordings wait here too.
@MainActor
@Observable
final class RetentionDraftStore {
    static let shared = RetentionDraftStore()

    private var messages: [String: RetentionMessage] = [:]
    private var queued: Set<String> = []
    private var suggestions: [String: RetentionSuggestion] = [:]

    private static func key(_ appID: StoreApp.ID, _ id: String) -> String {
        "\(appID)|\(id)"
    }

    /// The app's copies, in the order they were first kept.
    func messages(for appID: StoreApp.ID) -> [RetentionMessage] {
        messages.filter { $0.key.hasPrefix("\(appID)|") }.map(\.value).sorted { $0.id < $1.id }
    }

    func message(appID: StoreApp.ID, id: String) -> RetentionMessage? {
        messages[Self.key(appID, id)]
    }

    func isQueuedCopy(appID: StoreApp.ID, id: String) -> Bool {
        queued.contains(Self.key(appID, id))
    }

    func keep(_ message: RetentionMessage, appID: StoreApp.ID, queued isQueued: Bool) {
        let key = Self.key(appID, message.id)
        messages[key] = message
        if isQueued { queued.insert(key) } else { queued.remove(key) }
    }

    func remove(appID: StoreApp.ID, id: String) {
        let key = Self.key(appID, id)
        messages[key] = nil
        queued.remove(key)
    }

    // MARK: - Suggestions

    func suggestion(appID: StoreApp.ID, messageID: String, locale: String) -> RetentionSuggestion? {
        suggestions[Self.key(appID, "\(messageID)|\(locale)")]
    }

    func suggest(_ suggestion: RetentionSuggestion, appID: StoreApp.ID) {
        suggestions[Self.key(appID, "\(suggestion.messageID)|\(suggestion.locale)")] = suggestion
    }

    func removeSuggestion(appID: StoreApp.ID, messageID: String, locale: String) {
        suggestions[Self.key(appID, "\(messageID)|\(locale)")] = nil
    }

    /// Forgets everything for the app (tests, sample scenes).
    func reset(appID: StoreApp.ID) {
        for key in messages.keys where key.hasPrefix("\(appID)|") {
            messages[key] = nil
        }
        queued = queued.filter { !$0.hasPrefix("\(appID)|") }
        suggestions = suggestions.filter { !$0.key.hasPrefix("\(appID)|") }
    }
}
