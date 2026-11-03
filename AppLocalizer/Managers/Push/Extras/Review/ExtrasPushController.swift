//
//  ExtrasPushController.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Review & Push for Autopilot's extras: each app's header, search image
/// and App Previews waiting to go, which are checked, the push that sends
/// them, and the Product Page Optimization sheet. It lives in the
/// `ScreenshotPushController`, which loads the plans with the screenshots'
/// and runs the push (`ScreenshotPushController+Extras`).
@MainActor
@Observable
final class ExtrasPushController {
    /// Plans with something to show, by app.
    private(set) var plans: [StoreApp.ID: ExtrasReviewPlan] = [:]
    /// Items left out of the next push.
    var unchecked: Set<ExtrasReviewItem.ID> = []
    /// The current or last push; nil before the first and once dismissed.
    var run: ExtrasPushRun?
    /// “Test with Product Page Optimization…”'s sheet while it's open.
    var test: ProductPageTestModel?
    /// Why a push that went couldn't be noted in the set.
    var recordError: String?

    func plans(for appIDs: [StoreApp.ID]) -> [ExtrasReviewPlan] {
        appIDs.compactMap { plans[$0] }
    }

    var orderedPlans: [ExtrasReviewPlan] {
        plans.values.sorted { $0.appName.localizedStandardCompare($1.appName) == .orderedAscending }
    }

    func setPlan(_ plan: ExtrasReviewPlan?, for appID: StoreApp.ID) {
        plans[appID] = plan.flatMap { $0.isEmpty ? nil : $0 }
    }

    func removeAll() {
        plans = [:]
        unchecked = []
    }

    /// The extras every planned app would push, for the toolbar's count.
    var itemCount: Int { plans.values.reduce(0) { $0 + $1.items.count } }

    // MARK: - Checkboxes

    func isChecked(_ item: ExtrasReviewItem) -> Bool { !item.isBlocked && !unchecked.contains(item.id) }

    func toggle(_ item: ExtrasReviewItem) {
        guard !item.isBlocked else { return }
        if unchecked.contains(item.id) { unchecked.remove(item.id) } else { unchecked.insert(item.id) }
    }

    /// What Push sends from `plan`: its checked items without errors.
    func checkedItems(in plan: ExtrasReviewPlan) -> [ExtrasReviewItem] {
        plan.pushable.filter(isChecked)
    }

    var isPushing: Bool { run?.isRunning == true }

    /// The file ID an item had when it was planned, for what's recorded
    /// once it's pushed.
    func fileID(of item: ExtrasPushItem) -> String {
        plans[item.appID]?.items.first { $0.id == item.id }?.fileID ?? item.fileURL.deletingPathExtension().lastPathComponent
    }
}
