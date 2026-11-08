//
//  RetentionWorkingSet.swift
//  AppLocalizer
//

import Foundation

/// One app's retention messages and offers as Pricing → Retention and the
/// MCP tools see them: App Store Connect's, with what waits in Review &
/// Push and the edits kept since on top, then the new ones.
@MainActor
struct RetentionWorkingSet {
    let appID: StoreApp.ID
    let content: RetentionContent
    let queue: ChangeQueue
    let store: RetentionDraftStore

    /// App Store Connect's offers, then the ones waiting in Review & Push.
    var offers: [RetentionOffer] {
        let queued = queue.changes(for: appID, section: .subscriptionPricing).compactMap(RetentionQueuedChanges.offer(from:))
        return content.offers + queued.filter { queued in !content.offers.contains { $0.offerID == queued.offerID } }
    }

    /// App Store Connect's messages, then the new ones in the order they
    /// were made.
    var messages: [RetentionMessage] {
        var result = content.messages.compactMap { workingCopy(of: $0.id, remote: $0) }
        let newIDs = Set(store.messages(for: appID).map(\.id) + queuedMessageIDs()).filter { id in !result.contains { $0.id == id } }
        for id in newIDs.sorted(by: Self.draftOrder) {
            if let message = workingCopy(of: id, remote: nil) { result.append(message) }
        }
        return result
    }

    /// The content with these messages and offers, for building changes.
    var current: RetentionContent {
        var current = content
        current.messages = messages
        current.offers = offers
        return current
    }

    /// `draft-2` before `draft-10`.
    private static func draftOrder(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedStandardCompare(rhs) == .orderedAscending
    }

    /// The kept copy while it's current, else the queued change's, else
    /// App Store Connect's. A new message that was queued and has left
    /// Review & Push since (pushed or discarded) is gone.
    private func workingCopy(of id: String, remote: RetentionMessage?) -> RetentionMessage? {
        let change = queue.change(id: RetentionChangeBuilder.messageChangeID(appID: appID, messageID: id))
        if let kept = store.message(appID: appID, id: id) {
            if !store.isQueuedCopy(appID: appID, id: id) || change != nil { return kept }
            store.remove(appID: appID, id: id)
        }
        if let change, let message = RetentionQueuedChanges.message(from: change, remote: remote) { return message }
        return remote
    }

    private func queuedMessageIDs() -> [String] {
        queue.changes(for: appID, section: .subscriptionPricing).compactMap(RetentionChangeBuilder.messageID(of:))
    }
}
