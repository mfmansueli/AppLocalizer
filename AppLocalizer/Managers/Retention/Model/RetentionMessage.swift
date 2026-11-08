//
//  RetentionMessage.swift
//  AppLocalizer
//

import Foundation

/// A retention message as the editor holds it: its name, the subscriptions
/// that show it, what it shows, and its header and message per language.
/// `remote` is what App Store Connect has; a new draft has none until it's
/// pushed.
struct RetentionMessage: Identifiable, Hashable, Codable, Sendable {
    /// App Store Connect's message ID, or `draft-<n>` for a new one.
    var id: String
    /// Only the person sees it. It can't change once the message exists.
    var referenceName: String
    var subscriptionIDs: [String] = []
    var kind = RetentionMessageKind.message
    var image: RetentionImage?
    /// By locale code.
    var texts: [String: RetentionText] = [:]
    var remote: RetentionRemoteMessage?

    static let draftPrefix = "draft-"

    var isNew: Bool { remote == nil }

    /// A new message's ID: `draft-1`, `draft-2`, … not taken by `existing`.
    static func draftID(notIn existing: [RetentionMessage]) -> String {
        var number = 1
        while existing.contains(where: { $0.id == "\(draftPrefix)\(number)" }) { number += 1 }
        return "\(draftPrefix)\(number)"
    }

    /// An empty draft, "Message 2": write English first, then translate.
    static func draft(id: String, number: Int) -> RetentionMessage {
        RetentionMessage(id: id, referenceName: String(localized: "Message \(number)"))
    }

    /// A message App Store Connect has, as it has it.
    init(remote: RetentionRemoteMessage, image: RetentionImage?, kind: RetentionMessageKind) {
        id = remote.messageID
        referenceName = remote.referenceName
        subscriptionIDs = remote.subscriptionIDs
        self.kind = kind
        self.image = image
        texts = remote.texts
        self.remote = remote
    }

    init(
        id: String,
        referenceName: String,
        subscriptionIDs: [String] = [],
        kind: RetentionMessageKind = .message,
        image: RetentionImage? = nil,
        texts: [String: RetentionText] = [:],
        remote: RetentionRemoteMessage? = nil
    ) {
        self.id = id
        self.referenceName = referenceName
        self.subscriptionIDs = subscriptionIDs
        self.kind = kind
        self.image = image
        self.texts = texts
        self.remote = remote
    }

    func text(for locale: String) -> RetentionText {
        texts[locale] ?? .empty
    }

    /// Languages with something written.
    var writtenLocales: [String] {
        texts.filter { !$0.value.isEmpty }.map(\.key).sorted()
    }

    /// Languages over 66 or 144.
    var tooLongLocales: [String] {
        texts.filter(\.value.isTooLong).map(\.key).sorted()
    }

    /// Whether the editor's copy differs from App Store Connect's: new, or
    /// another name, subscriptions, kind, image or text.
    var hasChanges: Bool {
        guard let remote else { return true }
        if Set(subscriptionIDs) != Set(remote.subscriptionIDs) { return true }
        if (image?.assetID ?? image?.localPath) != remote.imageID, kind == .image { return true }
        if kind != .image, remote.imageID != nil { return true }
        let locales = Set(texts.keys).union(remote.localizations.keys)
        return locales.contains { !text(for: $0).hasSameWords(as: remote.localizations[$0]?.text) }
    }
}
