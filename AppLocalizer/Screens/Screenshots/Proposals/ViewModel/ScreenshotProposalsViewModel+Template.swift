//
//  ScreenshotProposalsViewModel+Template.swift
//  AppLocalizer
//

import Foundation

// A template proposal: its changes read against the version it was based
// on, the before-and-after strip, accepting it as the next version, and
// rebasing a stale one with the person's pick for each path both sides
// changed.
extension ScreenshotProposalsViewModel {
    func review(of proposal: ScreenshotProposal) -> TemplateProposalReview? {
        guard let template = proposal.template, let history = document?.history else { return nil }
        return TemplateProposalReview(proposal: template, history: history, applier: applier)
    }

    func choice(for path: String, in proposal: ScreenshotProposal) -> TemplateProposalReview.Choice {
        rebaseChoices[proposal.id]?[path] ?? .keepYours
    }

    func setChoice(_ choice: TemplateProposalReview.Choice, for path: String, in proposal: ScreenshotProposal) {
        rebaseChoices[proposal.id, default: [:]][path] = choice
    }

    /// "Since then · v4 · You, Oct 12: Device width 80% → 78%".
    func sinceText(_ version: TemplateVersion) -> String {
        let date = version.date.formatted(.dateTime.month(.abbreviated).day())
        return String(localized: "v\(version.number) · \(version.author.title), \(date): \(version.note)")
    }

    /// Why Accept is off: stale, or the operations can't be applied.
    func acceptRefusal(of proposal: ScreenshotProposal) -> String? {
        guard let review = review(of: proposal) else { return nil }
        if review.isStale { return String(localized: "Rebase it onto v\(review.currentNumber) first.") }
        if case let .failure(refusals) = review.proposedTemplate() { return refusals.items.first?.reason }
        return nil
    }

    /// Accept as v5.
    func acceptTemplate() async {
        guard let id = selectedID, var document else { return }
        switch document.acceptTemplateProposal(id, date: now(), applier: applier) {
        case .success: await save(document)
        case let .failure(refusals): errorMessage = refusals.items.first?.reason
        }
    }

    /// Rebase onto v4: the proposal stays waiting, now on the current
    /// version, with each conflict settled as picked.
    func rebase() async {
        guard let proposal = selected, var document else { return }
        document.rebaseProposal(proposal.id, choices: rebaseChoices[proposal.id] ?? [:])
        rebaseChoices[proposal.id] = nil
        await save(document)
    }

    // MARK: - Before and after

    /// The stress strip's locales on `stressSlot`, laid out from the
    /// current template and from the one accepting would save (stale
    /// proposals with the picks so far).
    func stressColumns(for proposal: ScreenshotProposal) -> [ProposalStressColumn] {
        guard let document, let current = document.template, let review = review(of: proposal) else { return [] }
        let slot = min(stressSlot, current.slots.count - 1)
        let engine = engine
        let inputs = StressStripPlanner.Inputs(
            template: current, slot: slot, displayType: displayType, primary: primaryLocale,
            ownCaption: { document.captions.caption(locale: $0, slot: slot) },
            previewCaption: { _ in nil },
            capture: { [displayType, primaryLocale] in
                document.captures.capture(locale: $0, displayType: displayType, slot: slot, primary: primaryLocale.code)
            }
        )
        let proposed = try? review.proposedTemplate(choices: rebaseChoices[proposal.id] ?? [:]).get()
        return StressStripPlanner(engine: engine).entries(inputs).map { entry in
            let after = proposed.map { template in
                SlotPreview.make(
                    SlotPreview.Placement(template: template, locale: entry.locale, displayType: displayType, slot: min(slot, template.slots.count - 1)),
                    caption: entry.caption, capture: inputs.capture(entry.locale.code), engine: engine, primaryLocaleName: primaryLocale.name
                )
            }
            return ProposalStressColumn(locale: entry.locale, title: "\(entry.locale.name) · \(entry.role.title)", before: entry.preview, after: after)
        }
    }

    /// Asks for the capture images the strip draws.
    func loadImages(for columns: [ProposalStressColumn]) {
        let captures = columns.flatMap { [$0.before.job.capture, $0.after?.job.capture] }.compactMap(\.self)
        captureImages.request(captures, width: Self.captureImageWidth)
    }
}
