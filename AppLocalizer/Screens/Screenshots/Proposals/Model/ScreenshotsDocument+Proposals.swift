//
//  ScreenshotsDocument+Proposals.swift
//  AppLocalizer
//

import Foundation

// Deciding assistants' proposals (design README §6). Accepting a template
// proposal saves the next version tagged with the assistant; accepting
// captions writes them as "Proposed by Claude Code", which they stay until
// a person edits them. Nothing here pushes: the changed renders join
// Review & Push like any others.
extension ScreenshotsDocument {
    func proposal(id: String) -> ScreenshotProposal? {
        proposals.first { $0.id == id }
    }

    /// Proposals nobody has decided yet, oldest first.
    var waitingProposals: [ScreenshotProposal] {
        proposals.filter(\.isWaiting)
    }

    /// Accepts a waiting, current template proposal as the next version.
    /// A stale one is refused: it has to be rebased first.
    mutating func acceptTemplateProposal(
        _ id: String,
        date: Date,
        applier: TemplateOperationApplier = TemplateOperationApplier()
    ) -> Result<TemplateVersion, TemplateRefusals> {
        guard let index = proposals.firstIndex(where: { $0.id == id }), proposals[index].isWaiting,
              let template = proposals[index].template, var history
        else {
            return .failure(TemplateRefusals(items: [
                TemplateRefusal(path: "", kind: .stale, reason: String(localized: "This proposal was already decided.")),
            ]))
        }
        let proposal = proposals[index]
        let result = history.accept(
            template.operations, basedOn: template.basedOn, from: proposal.client, reason: proposal.title, date: date, applier: applier
        )
        if case .success = result {
            self.history = history
            proposals[index].status = .accepted
            proposals[index].decidedAt = date
        }
        return result
    }

    /// Accepts the captions at `keys` (every one when nil) and rejects the
    /// rest. Returns how many were accepted.
    @discardableResult
    mutating func acceptCaptions(of id: String, keys: Set<LocaleSlot>? = nil, date: Date) -> Int {
        guard let index = proposals.firstIndex(where: { $0.id == id }), proposals[index].isWaiting else { return 0 }
        let proposal = proposals[index]
        let provenance = CaptionProvenance.assistant(client: proposal.client, date: proposal.receivedAt)
        var accepted = 0
        for (itemIndex, item) in proposal.captions.enumerated() {
            guard keys?.contains(item.key) ?? true else {
                proposals[index].captions[itemIndex].decision = .rejected
                continue
            }
            let current = captions.caption(locale: item.locale, slot: item.slot)
            captions.setCaption(item.caption(over: current, provenance: provenance), locale: item.locale, slot: item.slot)
            proposals[index].captions[itemIndex].decision = .accepted
            accepted += 1
        }
        proposals[index].status = switch accepted {
        case proposal.captions.count: .accepted
        case 0: .rejected
        default: .partlyAccepted
        }
        proposals[index].decidedAt = date
        return accepted
    }

    /// Reject, Reject All and Discard.
    mutating func rejectProposal(_ id: String, date: Date) {
        guard let index = proposals.firstIndex(where: { $0.id == id }), proposals[index].isWaiting else { return }
        for itemIndex in proposals[index].captions.indices {
            proposals[index].captions[itemIndex].decision = .rejected
        }
        proposals[index].status = .rejected
        proposals[index].decidedAt = date
    }

    /// Rebase onto the current version: the proposal stays waiting, now
    /// based on the current version, with each conflicting path settled by
    /// `choices` (keeping the person's value unless it says otherwise).
    mutating func rebaseProposal(_ id: String, choices: [String: TemplateProposalReview.Choice]) {
        guard let index = proposals.firstIndex(where: { $0.id == id }), proposals[index].isWaiting,
              let template = proposals[index].template, let history else { return }
        let review = TemplateProposalReview(proposal: template, history: history)
        guard review.isStale else { return }
        proposals[index].template = review.rebased(choices: choices)
    }
}
