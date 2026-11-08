//
//  RetentionModel+Queue.swift
//  AppLocalizer
//

import Foundation

extension RetentionModel {
    /// What keeps the selected message from Review & Push, first one first.
    var problems: [RetentionMessageProblem] {
        guard let message = selectedMessage else { return [] }
        return builder.problems(for: message, messageCount: messages.count)
    }

    /// Whether Add to Review & Push has something to add: a new message,
    /// one that differs from App Store Connect's, or offers to show or hide.
    var hasChangesToQueue: Bool {
        guard let message = selectedMessage else { return false }
        if message.hasChanges { return true }
        let existing = message.subscriptionIDs.flatMap { content.offers(for: $0) }
        return message.kind == .offer ? existing.contains { !$0.isShown } : existing.contains(where: \.isShown)
    }

    /// Add to Review & Push, or take it out again.
    func toggleQueue() {
        guard let message = selectedMessage else { return }
        let changeID = RetentionChangeBuilder.messageChangeID(appID: app.id, messageID: message.id)
        if queue.change(id: changeID) != nil {
            queue.discard(id: changeID)
            store.keep(message, appID: app.id, queued: false)
            return
        }
        guard hasChangesToQueue else { return }
        if let problem = problems.first {
            notice = problem.message
            return
        }
        queue.upsert(builder.change(for: message, messageCount: messages.count))
        store.keep(message, appID: app.id, queued: true)
        notice = nil
    }

    /// Deletes a new message that isn't queued (one App Store Connect has
    /// stays; App Store Connect deletes it).
    func discardDraft(_ message: RetentionMessage) {
        guard message.isNew else { return }
        queue.discard(id: RetentionChangeBuilder.messageChangeID(appID: app.id, messageID: message.id))
        store.remove(appID: app.id, id: message.id)
        messages.removeAll { $0.id == message.id }
        if selectedMessageID == message.id { selectedMessageID = messages.first?.id }
    }

    // MARK: - Offers

    func offers(for subscriptionID: String) -> [RetentionOffer] {
        offers.filter { $0.subscriptionID == subscriptionID }
    }

    /// New Offer…: the selected message's first subscription, else the
    /// first one.
    func newOfferDraft() -> RetentionOfferDraft? {
        let id = selectedMessage?.subscriptionIDs.first ?? subscriptions.first?.id
        return id.flatMap(content.subscription(id:)).map(RetentionOfferDraft.starting(for:))
    }

    func offerProblems(_ draft: RetentionOfferDraft) -> [RetentionOfferProblem] {
        guard let subscription = content.subscription(id: draft.subscriptionID) else { return [.termUnavailable] }
        return draft.problems(for: subscription, existing: offers(for: draft.subscriptionID))
    }

    /// Add Offer: it waits in Review & Push, which creates it with Apple's
    /// equalized prices and shows it with the subscription's message.
    @discardableResult
    func addOffer(_ draft: RetentionOfferDraft) -> Bool {
        guard let subscription = content.subscription(id: draft.subscriptionID),
              let offer = draft.offer(for: subscription, existing: offers(for: draft.subscriptionID))
        else { return false }
        queue.upsert(builder.offerChange(for: offer))
        isOfferSheetPresented = false
        refresh()
        notice = String(localized: "“\(offer.referenceName)” waits in Review & Push with the message.")
        return true
    }
}
