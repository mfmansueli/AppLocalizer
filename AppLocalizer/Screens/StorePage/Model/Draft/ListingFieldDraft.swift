//
//  ListingFieldDraft.swift
//  AppLocalizer
//

import Foundation

/// One field of one locale: the value App Store Connect has and the value
/// on this Mac, plus where the local value came from.
///
/// Rules:
/// - Any edit by you clears the machine-translated tag and turns an
///   assistant's proposal into your own change.
/// - Accepted machine translation stays tagged until it's edited or marked
///   reviewed, even after it's pushed.
/// - An assistant proposing over a change of yours doesn't overwrite it:
///   both are kept as a conflict, and you pick one before pushing.
/// - Discarding returns to the remote value and clears every tag.
struct ListingFieldDraft: Hashable, Sendable {
    /// What App Store Connect has, as of the last fetch or push.
    private(set) var remote: String
    /// What's shown and what would be pushed. Equal to `remote` when
    /// nothing is pending.
    private(set) var local: String
    /// Accepted machine translation nobody has reviewed yet.
    private(set) var isMachineTranslated: Bool
    /// The assistant whose proposal `local` is, while it's pending.
    private(set) var proposedBy: String?
    /// An assistant's different proposal for a field you had already changed.
    private(set) var conflictingProposal: ListingAssistantProposal?

    init(remote: String = "", local: String? = nil, isMachineTranslated: Bool = false, proposedBy: String? = nil) {
        self.remote = remote
        self.local = local ?? remote
        self.isMachineTranslated = isMachineTranslated
        self.proposedBy = proposedBy
        conflictingProposal = nil
    }

    /// The local value differs from App Store Connect's.
    var isPending: Bool { local != remote }

    var hasConflict: Bool { conflictingProposal != nil }

    /// Who the pending value came from, for the review sheet's source tag.
    var source: ChangeSource {
        if let proposedBy { return .assistant(client: proposedBy) }
        return isMachineTranslated ? .machineTranslation : .you
    }

    /// You typed, imported, replaced or copied a value.
    mutating func edit(_ value: String) {
        local = value
        isMachineTranslated = false
        proposedBy = nil
        guard let proposal = conflictingProposal else { return }
        if proposal.value == value {
            conflictingProposal = nil
        } else if !isPending {
            // Your change is gone, so the assistant's proposal stands alone.
            conflictingProposal = nil
            local = proposal.value
            proposedBy = proposal.client
        }
    }

    /// You accepted a machine translation: tagged until reviewed.
    mutating func acceptMachineTranslation(_ value: String) {
        edit(value)
        isMachineTranslated = true
    }

    /// "Mark Reviewed": the text stays, the tag goes.
    mutating func markReviewed() {
        isMachineTranslated = false
    }

    /// An assistant proposes a value. Returns how it was queued.
    mutating func propose(_ value: String, by client: String) -> ListingProposalOutcome {
        guard value != local else { return .unchanged }
        if isPending, proposedBy == nil {
            conflictingProposal = ListingAssistantProposal(client: client, value: value)
            return .conflict
        }
        local = value
        proposedBy = isPending ? client : nil
        isMachineTranslated = false
        conflictingProposal = nil
        return .queued
    }

    /// Settles a conflict between your change and an assistant's.
    mutating func resolveConflict(keeping choice: ListingConflictChoice) {
        guard let proposal = conflictingProposal else { return }
        conflictingProposal = nil
        guard choice == .assistant else { return }
        local = proposal.value
        proposedBy = isPending ? proposal.client : nil
        isMachineTranslated = false
    }

    /// Back to App Store Connect's value, with every tag cleared.
    mutating func discard() {
        local = remote
        isMachineTranslated = false
        proposedBy = nil
        conflictingProposal = nil
    }

    /// "Reject All from <client>": drops that assistant's proposals only.
    /// Returns whether anything was dropped.
    mutating func discardProposal(from client: String) -> Bool {
        var dropped = false
        if conflictingProposal?.client == client {
            conflictingProposal = nil
            dropped = true
        }
        if proposedBy == client {
            local = remote
            proposedBy = nil
            dropped = true
        }
        return dropped
    }

    /// The local value reached App Store Connect. A machine-translated tag
    /// stays until someone reviews the text.
    mutating func markPushed() {
        remote = local
        proposedBy = nil
        conflictingProposal = nil
    }

    /// A fresh fetch. An untouched field follows the new value; a pending
    /// change is kept on top of it.
    mutating func updateRemote(_ value: String) {
        let wasPending = isPending
        remote = value
        if !wasPending { local = value }
        if !isPending { proposedBy = nil }
    }
}
