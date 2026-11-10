//
//  ScreenshotsDocument+ProposedCaptions.swift
//  AppLocalizer
//

import Foundation

// Caption proposals one caption at a time, for the Screenshots language
// page: what still waits, and Accept or Dismiss on some of them. Accepting
// writes the caption as "Proposed by Claude Code", as the Proposals sheet
// does; an older suggestion for the same slot goes with it. A proposal is
// decided once none of its captions waits.
extension ScreenshotsDocument {
    /// Every caption still waiting, newest proposal per slot, by locale and
    /// slot.
    var openProposedCaptions: [ProposedCaption] {
        var newest: [LocaleSlot: ProposedCaption] = [:]
        for proposal in waitingProposals where proposal.kind == .captions {
            for item in proposal.captions where item.decision == nil {
                let suggestion = ProposedCaption(
                    proposalID: proposal.id, item: item, client: proposal.client, reason: proposal.reason, receivedAt: proposal.receivedAt
                )
                if let kept = newest[item.key], kept.receivedAt > proposal.receivedAt { continue }
                newest[item.key] = suggestion
            }
        }
        return newest.values.sorted { lhs, rhs in
            lhs.locale == rhs.locale ? lhs.slot < rhs.slot : lhs.locale < rhs.locale
        }
    }

    func openProposedCaptions(in locale: String) -> [ProposedCaption] {
        openProposedCaptions.filter { $0.locale == locale }
    }

    /// Accepts (or dismisses) the open captions with these ids. Returns how
    /// many were decided.
    @discardableResult
    mutating func decideCaptions(_ ids: Set<String>, accept: Bool, date: Date) -> Int {
        let chosen = openProposedCaptions.filter { ids.contains($0.id) }
        let keys = Set(chosen.map(\.key))
        guard !keys.isEmpty else { return 0 }
        for index in proposals.indices where proposals[index].isWaiting && proposals[index].kind == .captions {
            let proposal = proposals[index]
            let provenance = CaptionProvenance.assistant(client: proposal.client, date: proposal.receivedAt)
            var touched = false
            for itemIndex in proposal.captions.indices where proposal.captions[itemIndex].decision == nil {
                let item = proposal.captions[itemIndex]
                guard keys.contains(item.key) else { continue }
                touched = true
                let isChosen = ids.contains(ProposedCaption.makeID(proposalID: proposal.id, key: item.key))
                if accept, isChosen {
                    let current = captions.caption(locale: item.locale, slot: item.slot)
                    captions.setCaption(item.caption(over: current, provenance: provenance), locale: item.locale, slot: item.slot)
                    proposals[index].captions[itemIndex].decision = .accepted
                } else {
                    proposals[index].captions[itemIndex].decision = .rejected
                }
            }
            if touched { settleStatus(at: index, date: date) }
        }
        return chosen.count
    }

    /// Decided once no caption waits: accepted, rejected or partly accepted.
    private mutating func settleStatus(at index: Int, date: Date) {
        let captions = proposals[index].captions
        guard !captions.contains(where: { $0.decision == nil }) else { return }
        let accepted = captions.count { $0.decision == .accepted }
        proposals[index].status = switch accepted {
        case captions.count: .accepted
        case 0: .rejected
        default: .partlyAccepted
        }
        proposals[index].decidedAt = date
    }
}
