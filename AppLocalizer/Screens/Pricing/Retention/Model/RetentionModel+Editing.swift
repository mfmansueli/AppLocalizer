//
//  RetentionModel+Editing.swift
//  AppLocalizer
//

import Foundation

extension RetentionModel {
    /// New Message: an empty draft, up to 10. Write English (the source)
    /// first, then Translate All.
    func newMessage() {
        guard canAddMessage else { return }
        let id = RetentionMessage.draftID(notIn: messages)
        let message = RetentionMessage.draft(id: id, number: messages.count + 1)
        messages.append(message)
        store.keep(message, appID: app.id, queued: false)
        selectedMessageID = id
        selectedLocale = sourceLocale.code
        showsAllLanguages = false
        notice = nil
    }

    func select(_ message: RetentionMessage) {
        selectedMessageID = message.id
        notice = nil
    }

    /// Changes the selected message. A queued one stays queued with the
    /// change; any other is kept as an edit.
    func edit(_ change: (inout RetentionMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == selectedMessageID }) else { return }
        var message = messages[index]
        change(&message)
        guard message != messages[index] else { return }
        messages[index] = message
        let queued = isQueued(message)
        store.keep(message, appID: app.id, queued: queued)
        if queued { queue.upsert(builder.change(for: message, messageCount: messages.count)) }
    }

    // MARK: - Fields

    /// Only a new message's name can change.
    var canRename: Bool { selectedMessage?.isNew ?? false }

    func setName(_ name: String) {
        guard canRename else { return }
        edit { $0.referenceName = name }
    }

    /// Whether the subscription already shows this message in App Store
    /// Connect: App Store Connect can't take it off, only give the
    /// subscription another message.
    func isAssignedRemotely(_ subscriptionID: String) -> Bool {
        selectedMessage?.remote?.subscriptionIDs.contains(subscriptionID) ?? false
    }

    /// The other message the subscription shows now, which this one
    /// replaces.
    func otherMessage(showing subscriptionID: String) -> RetentionMessage? {
        messages.first { $0.id != selectedMessageID && $0.subscriptionIDs.contains(subscriptionID) }
    }

    func toggleSubscription(_ subscriptionID: String) {
        guard !isAssignedRemotely(subscriptionID) else { return }
        edit { message in
            if let index = message.subscriptionIDs.firstIndex(of: subscriptionID) {
                message.subscriptionIDs.remove(at: index)
            } else {
                message.subscriptionIDs.append(subscriptionID)
            }
        }
    }

    func setKind(_ kind: RetentionMessageKind) {
        edit { $0.kind = kind }
        if kind == .image, selectedMessage?.image == nil, libraryState.value == nil { Task { await loadLibrary() } }
    }

    // MARK: - Words

    var selectedText: RetentionText {
        selectedMessage?.text(for: selectedLocale) ?? .empty
    }

    func setHeader(_ header: String) {
        let locale = selectedLocale
        edit { message in
            var text = message.text(for: locale)
            text.header = header
            text.origin = .written
            message.texts[locale] = text
        }
        if locale == sourceLocale.code, let id = selectedMessageID { store.noteSourceEdited(appID: app.id, id: id) }
    }

    func setBody(_ body: String) {
        let locale = selectedLocale
        edit { message in
            var text = message.text(for: locale)
            text.body = body
            text.origin = .written
            message.texts[locale] = text
        }
        if locale == sourceLocale.code, let id = selectedMessageID { store.noteSourceEdited(appID: app.id, id: id) }
    }

    func status(of locale: StoreLocale, in message: RetentionMessage) -> RetentionTextStatus {
        RetentionTextStatus.of(message.text(for: locale.code), isSource: locale.code == sourceLocale.code)
    }

    /// "All 18 languages ready", "17 of 18 languages ready · 1 too long",
    /// or "1 of 18 languages written · write English first, then Translate All".
    func languagesSummary(of message: RetentionMessage) -> String {
        let languages = builder.languages(of: message)
        let total = languages.count
        let ready = languages.count { status(of: $0, in: message).isReady }
        let tooLong = languages.count { status(of: $0, in: message) == .tooLong }
        let written = languages.count { !message.text(for: $0.code).isEmpty }
        if ready == total { return String(localized: "All \(total) languages ready") }
        if tooLong > 0 { return String(localized: "\(ready) of \(total) languages ready · \(tooLong) too long") }
        let source = RetentionLanguages.shortName(of: sourceLocale, among: languages)
        if !message.text(for: sourceLocale.code).isComplete {
            return String(localized: "\(written) of \(total) languages written · write \(source) first, then Translate All")
        }
        return String(localized: "\(written) of \(total) languages written · Translate All fills in the rest")
    }

    /// Where the selected language's words came from, under the fields.
    var sourceNote: String? {
        let text = selectedText
        guard selectedLocale != sourceLocale.code, !text.isEmpty else { return nil }
        switch text.origin {
        case .written:
            return nil
        case .translated:
            return String(localized: "Translated by AppLocalizer from \(sourceLocale.name) · edit it here if you like")
        case let .assistant(client):
            return String(localized: "Written by \(client) · edit it here if you like")
        }
    }

    // MARK: - Shorter versions

    var suggestion: RetentionSuggestion? {
        guard let id = selectedMessageID else { return nil }
        return store.suggestion(appID: app.id, messageID: id, locale: selectedLocale)
    }

    func useSuggestion() {
        guard let suggestion else { return }
        edit { message in
            message.texts[suggestion.locale] = suggestion.applied(to: message.text(for: suggestion.locale))
        }
        store.removeSuggestion(appID: app.id, messageID: suggestion.messageID, locale: suggestion.locale)
    }

    // MARK: - Images

    func loadLibrary() async {
        guard !libraryState.isLoading else { return }
        libraryState = .loading
        do {
            libraryState = try await .loaded(services.libraryImages(for: app))
        } catch {
            libraryState = .failed(error.localizedDescription)
        }
    }

    func chooseImage() {
        pickedImageID = selectedMessage?.image?.id
        isImageSheetPresented = true
        if libraryState.value == nil { Task { await loadLibrary() } }
    }

    /// The library's images that fit first, each once.
    var libraryImages: [RetentionImage] {
        let images = libraryState.value ?? []
        return images.filter(\.fits) + images.filter { !$0.fits }
    }

    func useImage(_ image: RetentionImage) {
        edit { message in
            message.image = image
            message.kind = .image
        }
        isImageSheetPresented = false
    }

    /// A PNG Claude Design (or the person) made, checked against Apple's
    /// rules; it's uploaded to the Asset Library when the message is pushed.
    func useImageFile(at url: URL) {
        guard let image = RetentionImageRule.image(at: url, name: url.deletingPathExtension().lastPathComponent) else {
            notice = String(localized: "AppLocalizer can’t read \(url.lastPathComponent) as an image.")
            return
        }
        if let problem = image.problems.first {
            notice = problem.message
            return
        }
        useImage(image)
    }
}
