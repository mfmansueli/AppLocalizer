//
//  RetentionDraftStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The editor's copies of retention messages: new messages and edits that
/// aren't in Review & Push yet, so they survive going to another section
/// and back and closing AppLocalizer, and the full copy of a queued one
/// (Review & Push keeps what it sends; this keeps the thumbnail and
/// such). Assistants' shorter wordings wait here too.
@MainActor
@Observable
final class RetentionDraftStore {
    static let shared = RetentionDraftStore(url: defaultURL)

    /// `RetentionDrafts.json`, beside the Retention images.
    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "AppLocalizer/RetentionDrafts.json")
    }

    /// What's on disk.
    private struct Archive: Codable {
        var messages: [String: RetentionMessage]
        var queued: Set<String>
        var suggestions: [String: RetentionSuggestion]
        var sourceEdited: Set<String>
    }

    private var messages: [String: RetentionMessage] = [:]
    private var queued: Set<String> = []
    private var suggestions: [String: RetentionSuggestion] = [:]
    /// Messages whose source words changed since Translate All: it redoes
    /// their translated languages.
    private var sourceEdited: Set<String> = []

    @ObservationIgnored private let url: URL?
    @ObservationIgnored private var pendingSave: Task<Void, Never>?

    /// With no `url`, the copies last until the app closes (tests, scenes).
    init(url: URL? = nil) {
        self.url = url
        load()
    }

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
        scheduleSave()
    }

    func remove(appID: StoreApp.ID, id: String) {
        let key = Self.key(appID, id)
        messages[key] = nil
        queued.remove(key)
        sourceEdited.remove(key)
        scheduleSave()
    }

    // MARK: - Source words

    func isSourceEdited(appID: StoreApp.ID, id: String) -> Bool {
        sourceEdited.contains(Self.key(appID, id))
    }

    func noteSourceEdited(appID: StoreApp.ID, id: String) {
        sourceEdited.insert(Self.key(appID, id))
        scheduleSave()
    }

    func clearSourceEdited(appID: StoreApp.ID, id: String) {
        sourceEdited.remove(Self.key(appID, id))
        scheduleSave()
    }

    // MARK: - Suggestions

    func suggestion(appID: StoreApp.ID, messageID: String, locale: String) -> RetentionSuggestion? {
        suggestions[Self.key(appID, "\(messageID)|\(locale)")]
    }

    func suggest(_ suggestion: RetentionSuggestion, appID: StoreApp.ID) {
        suggestions[Self.key(appID, "\(suggestion.messageID)|\(suggestion.locale)")] = suggestion
        scheduleSave()
    }

    func removeSuggestion(appID: StoreApp.ID, messageID: String, locale: String) {
        suggestions[Self.key(appID, "\(messageID)|\(locale)")] = nil
        scheduleSave()
    }

    /// Forgets everything for the app (tests, sample scenes).
    func reset(appID: StoreApp.ID) {
        let prefix = "\(appID)|"
        messages = messages.filter { !$0.key.hasPrefix(prefix) }
        queued = queued.filter { !$0.hasPrefix(prefix) }
        suggestions = suggestions.filter { !$0.key.hasPrefix(prefix) }
        sourceEdited = sourceEdited.filter { !$0.hasPrefix(prefix) }
        scheduleSave()
    }

    // MARK: - Disk

    private func load() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        do {
            let archive = try JSONDecoder().decode(Archive.self, from: data)
            messages = archive.messages
            queued = archive.queued
            suggestions = archive.suggestions
            sourceEdited = archive.sourceEdited
        } catch {
            NSLog("Retention: couldn’t read the drafts: \(error.localizedDescription)")
        }
    }

    /// Typing keeps a copy on every key, so the write waits for a pause.
    private func scheduleSave() {
        guard url != nil else { return }
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    /// Writes what's kept now, rather than after the pause.
    func saveNow() {
        pendingSave?.cancel()
        guard let url else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let archive = Archive(messages: messages, queued: queued, suggestions: suggestions, sourceEdited: sourceEdited)
            try JSONEncoder().encode(archive).write(to: url, options: .atomic)
        } catch {
            NSLog("Retention: couldn’t save the drafts: \(error.localizedDescription)")
        }
    }
}
