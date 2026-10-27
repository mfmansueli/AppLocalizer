//
//  ReviewPushViewModel+Screenshots.swift
//  AppLocalizer
//

import Foundation

/// Screenshots in Review & Push: the images each app's plan would send,
/// filtered by the same scope and source as the text changes, with their
/// checkboxes, discards and the push.
extension ReviewPushViewModel {
    var screenshots: ScreenshotPushController { push.screenshots }

    /// The plans in scope, before the source filter.
    var scopedScreenshotPlans: [ScreenshotPushPlan] {
        switch scope {
        case .thisApp: screenshots.plans(for: selectedAppID.map { [$0] } ?? [])
        case .allApps: screenshots.orderedPlans
        }
    }

    var scopedImages: [ScreenshotPlanItem] { scopedScreenshotPlans.flatMap(\.items) }

    /// The plans in scope with only the images the source filter shows.
    var screenshotPlans: [ScreenshotPushPlan] {
        guard let sourceFilter else { return scopedScreenshotPlans }
        return scopedScreenshotPlans.map { plan in
            var plan = plan
            plan.groups = plan.groups.compactMap { group in
                var group = group
                group.items = group.items.filter { $0.source.filter == sourceFilter }
                return group.items.isEmpty ? nil : group
            }
            plan.kept = plan.kept.filter { $0.source.filter == sourceFilter }
            return plan
        }
    }

    var visibleImages: [ScreenshotPlanItem] { screenshotPlans.flatMap(\.items) }

    /// Whether the screenshot section shows: images, renders left out, or
    /// discards to undo.
    var showsScreenshots: Bool { screenshotPlans.contains { !$0.isEmpty } }

    /// Images a push can send: not on a version that's live.
    var pushableImages: [ScreenshotPlanItem] { screenshotPlans.filter(\.canPush).flatMap(\.items) }

    var checkedImages: [ScreenshotPlanItem] { pushableImages.filter { !uncheckedImages.contains($0.id) } }

    /// Some images are unchecked but not all: Push Selected sends the rest.
    var hasPartialImageSelection: Bool {
        let checked = checkedImages.count
        return checked > 0 && checked < pushableImages.count
    }

    var keptImages: [ScreenshotPlanItem] { screenshotPlans.flatMap(\.kept) }

    /// Renders failing a check, in scope.
    var failedRenders: [ScreenshotPlanExclusion] { screenshotPlans.flatMap(\.failedChecks) }

    /// Renders waiting for a localization, in scope.
    var unlocalizedRenders: [ScreenshotPlanExclusion] { screenshotPlans.flatMap(\.missingLocalizations) }

    func imageCount(thisAppOnly: Bool) -> Int {
        guard thisAppOnly else { return screenshots.orderedPlans.reduce(0) { $0 + $1.items.count } }
        return selectedAppID.flatMap { screenshots.plans[$0] }?.items.count ?? 0
    }

    /// "40 images in 8 sets", or nil without images.
    var imagesCountTitle: String? {
        let images = visibleImages.count
        guard images > 0 else { return nil }
        let sets = screenshotPlans.reduce(0) { $0 + $1.groups.count }
        let imageText = images == 1 ? String(localized: "1 image") : String(localized: "\(images) images")
        let setText = sets == 1 ? String(localized: "1 set") : String(localized: "\(sets) sets")
        return String(localized: "\(imageText) in \(setText)")
    }

    /// The header's line when only images wait.
    var imagesSubtitle: String? {
        guard let count = imagesCountTitle else { return nil }
        let explanation = String(localized: "old → new for each slot. Uncheck an image to leave it out of this push; discard it to keep what’s live.")
        return "\(count) · \(explanation)"
    }

    // MARK: - Checkboxes

    func isChecked(_ item: ScreenshotPlanItem) -> Bool { !uncheckedImages.contains(item.id) }

    func toggle(_ item: ScreenshotPlanItem) {
        if uncheckedImages.contains(item.id) { uncheckedImages.remove(item.id) } else { uncheckedImages.insert(item.id) }
    }

    /// A group's checkbox: on when every image is, off when none is,
    /// mixed otherwise (nil).
    func checkState(of group: ScreenshotPlanGroup) -> Bool? {
        let checked = group.items.count(where: isChecked)
        if checked == group.items.count { return true }
        return checked == 0 ? false : nil
    }

    func toggle(_ group: ScreenshotPlanGroup) {
        let ids = group.items.map(\.id)
        if checkState(of: group) == true { uncheckedImages.formUnion(ids) } else { uncheckedImages.subtract(ids) }
    }

    // MARK: - Discards

    /// Keeps what's live for `item`.
    func discardImage(_ item: ScreenshotPlanItem) {
        uncheckedImages.remove(item.id)
        screenshots.discard([item])
    }

    /// Discard All's part for images.
    func discardVisibleImages() {
        let items = visibleImages
        uncheckedImages.subtract(items.map(\.id))
        screenshots.discard(items)
    }

    func undoImageDiscards() async {
        await screenshots.undoDiscards(appIDs: screenshotPlans.map(\.appID))
    }

    // MARK: - Pushing

    /// What Push Selected sends: the selected changes, and the checked
    /// images when some are unchecked.
    var selectedPushCount: Int {
        selectedPushableChanges.count + (hasPartialImageSelection ? checkedImages.count : 0)
    }

    /// The count Push n Selected shows: what it sends, or while nothing is
    /// singled out (it's disabled) every checked image.
    var selectedTitleCount: Int {
        selectedPushCount > 0 ? selectedPushCount : checkedImages.count
    }

    /// What Push All sends: every pushable change and image.
    var allPushCount: Int { pushableChanges.count + pushableImages.count }

    /// "About 168 requests · 2 min · 5% of the hourly limit" for what Push
    /// All sends, or Push Selected when something is selected.
    var imagesEstimateText: String {
        let selected = !selection.isEmpty || hasPartialImageSelection
        let changes = selected ? selectedPushableChanges : pushableChanges
        let images = selected ? (hasPartialImageSelection ? checkedImages : []) : pushableImages
        let ids = Set(images.map(\.id))
        let groups = screenshotPlans.filter(\.canPush).flatMap(\.groups)
        let cost = PushCostEstimate(groups: groups) { ids.contains($0.id) }
        return cost.reviewText(otherRequests: PushEstimate(changes: changes).requestCount)
    }

    /// Starts the screenshot push: every pushable image, or for Push
    /// Selected the checked ones when some are unchecked.
    func startImagePush(selectedOnly: Bool) {
        let plans = screenshotPlans.filter(\.canPush)
        let images = selectedOnly ? (hasPartialImageSelection ? checkedImages : []) : pushableImages
        let ids = Set(images.map(\.id))
        guard !ids.isEmpty else { return }
        uncheckedImages = []
        screenshots.push(plans, selection: ids)
    }

    /// Loads the plans for the scope. `refreshCount` is Refresh's count.
    func loadScreenshotPlans(refreshCount: Int) async {
        await screenshots.loadPlans(selectedAppID: selectedAppID, allApps: scope == .allApps, refreshCount: refreshCount)
    }
}
