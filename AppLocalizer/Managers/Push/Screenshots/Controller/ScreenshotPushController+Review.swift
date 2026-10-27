//
//  ScreenshotPushController+Review.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotPushController {
    /// Keeps what's live for `items` ("discard"): each stays out of review
    /// until its render changes again, or until Undo.
    func discard(_ items: [ScreenshotPlanItem]) {
        guard let pushing = workspace?.pushing else { return }
        for (appID, appItems) in Dictionary(grouping: items, by: \.appID) {
            var state = pushing.state.state(appID: appID)
            for item in appItems {
                switch item.content {
                case let .render(job): state.kept[item.cell] = job.key
                case let .restore(image): state.keptRestores.insert(image.id)
                }
            }
            try? pushing.state.save(state, appID: appID)
            guard var plan = plans[appID] else { continue }
            let ids = Set(appItems.map(\.id))
            plan.groups = plan.groups.compactMap { group in
                var group = group
                group.items.removeAll { ids.contains($0.id) }
                return group.items.isEmpty ? nil : group
            }
            plan.kept += appItems.filter { item in !plan.kept.contains { $0.id == item.id } }
            setPlan(plan, for: appID)
        }
    }

    /// Undo: every image discarded in `appIDs` goes back to review.
    func undoDiscards(appIDs: [StoreApp.ID]) async {
        guard let pushing = workspace?.pushing else { return }
        for appID in appIDs {
            guard let kept = plans[appID]?.kept, !kept.isEmpty else { continue }
            var state = pushing.state.state(appID: appID)
            for item in kept {
                switch item.content {
                case .render: state.kept[item.cell] = nil
                case let .restore(image): state.keptRestores.remove(image.id)
                }
            }
            try? pushing.state.save(state, appID: appID)
            if let app = apps[appID] { await loadPlan(for: app) }
        }
    }

    /// Show in Captions: remembers the render for the Screenshots view.
    func showInCaptions(_ exclusion: ScreenshotPlanExclusion) {
        captionsRequest = ScreenshotCaptionsRequest(appID: exclusion.appID, cell: exclusion.cell)
    }

    /// Called by the Screenshots view once it has opened Captions.
    func consumeCaptionsRequest() {
        captionsRequest = nil
    }
}
