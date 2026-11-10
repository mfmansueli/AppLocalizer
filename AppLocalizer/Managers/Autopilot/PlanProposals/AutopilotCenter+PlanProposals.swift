//
//  AutopilotCenter+PlanProposals.swift
//  AppLocalizer
//

import Foundation

/// What the assistant sends for an app's plan outside a run's capture: new
/// screens (`propose_screens` without Suggest Screens) and changes to the
/// plan (`update_capture_plan` at Review & Push, say, or with no run at
/// all). Nothing changes on its own: they wait for the next plan, where the
/// person adds the screens they want and accepts or rejects each change.
extension AutopilotCenter {
    // MARK: - Screens

    /// Screens for the next plan, under `display`'s (Apple Watch's own, or
    /// the set's for any other device). A screen sent again in place of
    /// one still waiting takes its place.
    @discardableResult
    func queueScreenSuggestions(
        _ items: [AutopilotScreenSuggestion], on display: ScreenshotDisplayType, client: String, appID: StoreApp.ID
    ) throws -> AutopilotScreenSuggestions {
        guard !items.isEmpty else {
            throw AutopilotError(String(localized: "Send at least one screen, each with a name, why and the steps."))
        }
        let device: ScreenshotDisplayType = display == .watch ? .watch : .iPhone
        let items = device.hasCaptions ? items : items.map { item in
            var item = item
            item.caption = ""
            return item
        }
        let suggestions = AutopilotScreenSuggestions(
            client: client, items: items, receivedAt: now(), displayType: device == .watch ? .watch : nil,
            id: "ps-" + makeID().prefix(8)
        )
        updatePlanProposals(appID) { proposals in
            for index in proposals.screens.indices where proposals.screens[index].device == device {
                proposals.screens[index].items.removeAll { waiting in
                    waiting.status == .open && items.contains { $0.isNamed(waiting.name) }
                }
            }
            proposals.screens.removeAll { $0.items.isEmpty }
            proposals.screens.append(suggestions)
        }
        return suggestions
    }

    /// Add to Plan on a screen kept for the next plan.
    func addQueuedScreen(_ id: String, appID: StoreApp.ID) {
        let proposals = planProposals(for: appID)
        guard let batch = proposals.batchIndex(holding: id), let item = proposals.screens[batch].items.first(where: { $0.id == id }) else {
            return
        }
        var added = false
        update(appID) { run in added = Self.append(item, from: proposals.screens[batch], to: &run) }
        if added { setQueuedScreen(id, to: .added, appID: appID) }
    }

    func dismissQueuedScreen(_ id: String, appID: StoreApp.ID) {
        setQueuedScreen(id, to: .dismissed, appID: appID)
    }

    /// Done on screens kept for the next plan: the ones not added go away.
    func closeQueuedScreens(_ proposalID: String, appID: StoreApp.ID) {
        updatePlanProposals(appID) { $0.screens.removeAll { $0.id == proposalID } }
    }

    /// Start: the screens added or dismissed leave the queue; the others
    /// wait for the plan after this run.
    func settleQueuedScreens(appID: StoreApp.ID) {
        guard proposalsForNextPlan[appID]?.screens.isEmpty == false else { return }
        updatePlanProposals(appID) { proposals in
            for index in proposals.screens.indices {
                proposals.screens[index].items.removeAll { $0.status != .open }
            }
            proposals.screens.removeAll { $0.items.isEmpty }
        }
    }

    private func setQueuedScreen(_ id: String, to status: AutopilotScreenSuggestion.Status, appID: StoreApp.ID) {
        updatePlanProposals(appID) { proposals in
            guard let batch = proposals.batchIndex(holding: id),
                  let index = proposals.screens[batch].items.firstIndex(where: { $0.id == id })
            else { return }
            proposals.screens[batch].items[index].status = status
        }
    }

    // MARK: - Changes

    /// A change for the next plan. What it sends again takes the place of
    /// what an earlier change still waits with.
    @discardableResult
    func queuePlanChange(_ change: AutopilotPlanChange, appID: StoreApp.ID) -> AutopilotPlanChange {
        updatePlanProposals(appID) { proposals in
            proposals.changes = proposals.changes.map { $0.without(change) }.filter { !$0.isEmpty }
            proposals.changes.append(change)
        }
        return change
    }

    /// Accept: the change joins the open plan, the next run's.
    func acceptPlanChange(_ id: String, appID: StoreApp.ID) {
        guard runs[appID]?.stage == .plan, let change = planProposals(for: appID).changes.first(where: { $0.id == id }) else { return }
        updatePlan(for: appID) { change.apply(to: &$0) }
        updatePlanProposals(appID) { $0.changes.removeAll { $0.id == id } }
    }

    /// Reject: the plan stays as it is.
    func rejectPlanChange(_ id: String, appID: StoreApp.ID) {
        updatePlanProposals(appID) { $0.changes.removeAll { $0.id == id } }
    }
}
