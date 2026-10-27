//
//  ScreenshotProposalsViewModel+Captions.swift
//  AppLocalizer
//

import Foundation

// A caption proposal: each caption against the one it replaces, measured
// with the current template whenever it's shown, a tick per caption, and
// Accept n Selected, Accept All and Reject All. Accepted captions read
// "Proposed by Claude Code" until someone edits them.
extension ScreenshotProposalsViewModel {
    func rows(of proposal: ScreenshotProposal) -> [CaptionProposalRow] {
        guard let document, let template = document.template else { return [] }
        let engine = engine
        return proposal.captions.compactMap { item in
            guard let locale = StoreLocaleCatalog.locale(code: item.locale), template.slots.indices.contains(item.slot) else { return nil }
            let current = document.captions.caption(locale: item.locale, slot: item.slot)
            let proposed = item.caption(over: current, provenance: .assistant(client: proposal.client, date: proposal.receivedAt))
            let capture = document.captures.capture(locale: item.locale, displayType: displayType, slot: item.slot, primary: primaryLocale.code)
            let placement = SlotPreview.Placement(template: template, locale: locale, displayType: displayType, slot: item.slot)
            let preview = SlotPreview.make(placement, caption: proposed, capture: capture, engine: engine, primaryLocaleName: primaryLocale.name)
            let currentFit = current.map {
                SlotPreview.make(placement, caption: $0, capture: capture, engine: engine, primaryLocaleName: primaryLocale.name).fit
            }
            let title = String(localized: "\(locale.name) · slot \(item.slot + 1) · \(document.slotName(item.slot))")
            return CaptionProposalRow(
                item: item, title: title, currentHeadline: current?.headline, currentFit: currentFit,
                proposedFit: preview.fit, proposedPreview: preview
            )
        }
    }

    /// The ticked captions: every one until the person unticks one.
    func selection(of proposal: ScreenshotProposal) -> Set<LocaleSlot> {
        captionSelections[proposal.id] ?? Set(proposal.captions.map(\.key))
    }

    func isSelected(_ key: LocaleSlot, in proposal: ScreenshotProposal) -> Bool {
        selection(of: proposal).contains(key)
    }

    func toggle(_ key: LocaleSlot, in proposal: ScreenshotProposal) {
        var selection = selection(of: proposal)
        if selection.contains(key) { selection.remove(key) } else { selection.insert(key) }
        captionSelections[proposal.id] = selection
    }

    /// "Accept 2 Selected": off with none ticked, and with all of them,
    /// which is Accept All.
    func acceptSelectedTitle(of proposal: ScreenshotProposal) -> String {
        String(localized: "Accept \(selection(of: proposal).count) Selected")
    }

    func canAcceptSelected(_ proposal: ScreenshotProposal) -> Bool {
        let count = selection(of: proposal).count
        return proposal.isWaiting && count > 0 && count < proposal.captions.count
    }

    /// Accept n Selected (the rest are rejected), or Accept All.
    func acceptCaptions(all: Bool) async {
        guard let proposal = selected, var document else { return }
        let keys = all ? nil : selection(of: proposal)
        document.acceptCaptions(of: proposal.id, keys: keys, date: now())
        captionSelections[proposal.id] = nil
        await save(document)
    }

    func loadImages(for rows: [CaptionProposalRow]) {
        captureImages.request(rows.compactMap(\.proposedPreview.job.capture), width: Self.captureImageWidth)
    }
}
