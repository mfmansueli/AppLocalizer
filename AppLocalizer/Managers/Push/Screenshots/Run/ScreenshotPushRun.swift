//
//  ScreenshotPushRun.swift
//  AppLocalizer
//

import Foundation
import Observation

/// One screenshot push: every image chosen in review, uploaded set by set,
/// a few sets at a time. Each image is reserved, uploaded in parts,
/// committed and checked; only then is the screenshot it replaces kept on
/// this Mac and deleted, and each set is reordered last, so a failure
/// never leaves a live set with a gap. When the hourly budget runs out the
/// push pauses until the next hour, then resumes.
///
/// The steps live in `ScreenshotPushRun+Sets`, `+Images` and `+Requests`.
@MainActor
@Observable
final class ScreenshotPushRun {
    enum Phase: Hashable, Sendable {
        case running
        case finished
    }

    /// Ten screenshots is the most a set can hold.
    static let setCapacity = 10

    let date: Date
    /// Where this push keeps what it replaces.
    let backupID: String
    let plans: [ScreenshotPushPlan]
    var phase: Phase = .running
    var items: [ScreenshotUploadItem]
    /// Each set's ID and order as this push leaves it, by plan group ID.
    var sets: [String: ScreenshotSetProgress]
    /// The images the current round started with: all of them, or the
    /// failed ones on a retry.
    var roundItemIDs: Set<ScreenshotUploadItem.ID> = []
    /// While the hourly budget is used up: when the push resumes.
    var pausedUntil: Date?
    /// Why the rest stopped, e.g. "Offline"; nil while it can go on.
    var stopReason: String?
    var isCancelling = false

    let environment: ScreenshotPushEnvironment
    /// Called when a round ends, to record what it did.
    @ObservationIgnored var onFinish: @MainActor (ScreenshotPushRun) async -> Void = { _ in }
    @ObservationIgnored private var task: Task<Void, Never>?
    let groupOrder: [String]

    /// `selection` limits the push to those images; nil sends them all.
    init(plans: [ScreenshotPushPlan], selection: Set<ScreenshotPlanItem.ID>? = nil, environment: ScreenshotPushEnvironment) {
        self.plans = plans
        self.environment = environment
        date = environment.now()
        backupID = ScreenshotBackup.id(for: date)
        var items: [ScreenshotUploadItem] = []
        var sets: [String: ScreenshotSetProgress] = [:]
        var order: [String] = []
        for plan in plans where plan.canPush {
            for group in plan.groups {
                let chosen = group.items.filter { selection?.contains($0.id) ?? true }
                guard !chosen.isEmpty else { continue }
                items += chosen.map { ScreenshotUploadItem(plan: $0, groupID: group.id, localeName: group.locale.name) }
                sets[group.id] = ScreenshotSetProgress(group: group)
                order.append(group.id)
            }
        }
        self.items = items
        self.sets = sets
        groupOrder = order
    }

    // MARK: - Progress

    var totalCount: Int { items.count }
    var doneCount: Int { items.count { $0.status == .done } }
    var failedCount: Int { items.count { $0.status.isFailure } }
    var finishedCount: Int { items.count { $0.status.isFinished } }
    var progress: Double { items.isEmpty ? 0 : Double(finishedCount) / Double(items.count) }
    var isRunning: Bool { phase == .running }
    /// The apps this push sends images for.
    var appIDs: [StoreApp.ID] { plans.map(\.appID).filter { id in items.contains { $0.appID == id } } }
    /// Something live was replaced, so there's a backup to restore from.
    var replacedSomething: Bool { items.contains { $0.isCommitted && $0.backup != nil } }

    /// "Pushing 40 images", "All 40 images pushed", "38 of 40 images
    /// pushed".
    var title: String {
        switch phase {
        case .running:
            return totalCount == 1 ? String(localized: "Pushing 1 image") : String(localized: "Pushing \(totalCount) images")
        case .finished:
            if doneCount == totalCount {
                return totalCount == 1 ? String(localized: "1 image pushed") : String(localized: "All \(totalCount) images pushed")
            }
            return String(localized: "\(doneCount) of \(totalCount) images pushed")
        }
    }

    /// "15 of 40 done · reserve, upload and commit for each image".
    var subtitle: String {
        switch phase {
        case .running:
            if let pausedUntil {
                let time = pausedUntil.formatted(date: .omitted, time: .shortened)
                return String(localized: "Paused: this hour’s requests are used up. Resumes at \(time).")
            }
            return String(localized: "\(doneCount) of \(totalCount) done · reserve, upload and commit for each image")
        case .finished:
            if failedCount == 1 { return String(localized: "1 failed. Its live screenshot wasn’t touched.") }
            if failedCount > 1 { return String(localized: "\(failedCount) failed. Their live screenshots weren’t touched.") }
            let notSent = totalCount - doneCount
            if notSent > 0 { return String(localized: "\(notSent) not sent. They stay in Review & Push.") }
            if replacedSomething { return String(localized: "Old screenshots were kept on this Mac. Restore them from Activity.") }
            return String(localized: "Apple processes new screenshots over the next few minutes.")
        }
    }

    // MARK: - Running

    /// Sends every queued image.
    func start() {
        phase = .running
        stopReason = nil
        isCancelling = false
        roundItemIDs = Set(items.filter { $0.status == .queued }.map(\.id))
        task = Task { [weak self] in
            await self?.sendQueuedSets()
            await self?.finishRound()
        }
    }

    /// Lets the images in flight finish; the rest are cancelled.
    func cancelRemaining() {
        guard phase == .running else { return }
        isCancelling = true
    }

    /// Sends the failed images again. Copies already kept and sets already
    /// made are reused.
    func retryFailed() {
        guard phase == .finished else { return }
        var retried = false
        for index in items.indices where items[index].status.isFailure {
            items[index].status = .queued
            items[index].screenshotID = nil
            retried = true
        }
        if retried { start() }
    }

    /// Waits for the current round to end (tests).
    func waitUntilFinished() async {
        await task?.value
    }

    private func finishRound() async {
        phase = .finished
        pausedUntil = nil
        isCancelling = false
        await onFinish(self)
    }

    /// The status an image that won't start now gets, when the push is
    /// stopping; nil while it goes on.
    var haltStatus: ScreenshotUploadStatus? {
        if isCancelling { return .cancelled }
        return stopReason.map(ScreenshotUploadStatus.notSent)
    }
}
