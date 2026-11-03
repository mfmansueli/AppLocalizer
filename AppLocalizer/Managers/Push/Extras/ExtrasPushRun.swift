//
//  ExtrasPushRun.swift
//  AppLocalizer
//

import Foundation
import Observation

/// One push of Autopilot's extras (header and search results artwork, App
/// Previews) through the App Asset Library, one item at a time. Each file
/// is reserved in the app's library, uploaded in parts, committed and
/// processed; only then is it placed, so a failed upload never touches the
/// page. Artwork takes the place of what's in its slot; an App Preview
/// replaces the ones it names and goes first in its group. Apple's
/// reference data decides which groups a file belongs in, by its size.
///
/// The steps live in `ExtrasPushRun+Upload`, `+Placements` and
/// `+Requests`.
@MainActor
@Observable
final class ExtrasPushRun {
    enum Phase: Hashable, Sendable {
        case idle
        case running
        case finished
    }

    let items: [ExtrasPushItem]
    var statuses: [ExtrasPushItem.ID: ExtrasPushStatus]
    var phase: Phase = .idle
    /// While the hourly budget is used up: when the push resumes.
    var pausedUntil: Date?
    /// Why the rest stopped, e.g. "Not sent · offline"; nil while it can
    /// go on.
    var stopReason: String?
    var isCancelling = false

    let environment: ExtrasPushEnvironment
    /// Called when a round ends, to record what it did.
    @ObservationIgnored var onFinish: @MainActor (ExtrasPushRun) async -> Void = { _ in }
    @ObservationIgnored private var task: Task<Void, Never>?

    /// Each app's library ID, read once.
    @ObservationIgnored var libraryIDs: [StoreApp.ID: String] = [:]
    /// Apple's reference data, read once.
    @ObservationIgnored var refData: AssetLibraryRefData?
    /// Uploads Apple accepted, by item, so a retry doesn't send the file
    /// again: it waits for processing or places it.
    @ObservationIgnored var committedAssets: [ExtrasPushItem.ID: AssetLibraryAsset] = [:]
    @ObservationIgnored var processedItemIDs: Set<ExtrasPushItem.ID> = []

    init(items: [ExtrasPushItem], environment: ExtrasPushEnvironment) {
        self.items = items
        self.environment = environment
        statuses = Dictionary(items.map { ($0.id, .waiting) }, uniquingKeysWith: { first, _ in first })
    }

    func status(of item: ExtrasPushItem) -> ExtrasPushStatus {
        statuses[item.id] ?? .waiting
    }

    // MARK: - Progress

    var totalCount: Int { items.count }
    var doneCount: Int { items.count { status(of: $0).isDone } }
    var failedCount: Int { items.count { status(of: $0).isFailure } }
    var finishedCount: Int { items.count { status(of: $0).isFinished } }
    var progress: Double { items.isEmpty ? 0 : Double(finishedCount) / Double(items.count) }
    var isRunning: Bool { phase == .running }

    /// The failed items and why, in order.
    var failures: [(item: ExtrasPushItem, reason: String)] {
        items.compactMap { item in status(of: item).failureReason.map { (item: item, reason: $0) } }
    }

    /// "Pushing 4 extras", "All 4 extras pushed", "3 of 4 extras pushed".
    var title: String {
        switch phase {
        case .idle, .running:
            return totalCount == 1 ? String(localized: "Pushing 1 extra") : String(localized: "Pushing \(totalCount) extras")
        case .finished:
            if doneCount == totalCount {
                return totalCount == 1 ? String(localized: "1 extra pushed") : String(localized: "All \(totalCount) extras pushed")
            }
            return String(localized: "\(doneCount) of \(totalCount) extras pushed")
        }
    }

    // MARK: - Running

    /// Sends every waiting item.
    func start() {
        guard phase != .running else { return }
        phase = .running
        stopReason = nil
        isCancelling = false
        task = Task { [weak self] in
            await self?.sendWaiting()
            await self?.finishRound()
        }
    }

    /// Lets the item in flight finish; the rest are cancelled. A pause for
    /// the hourly budget ends at once.
    func cancelRemaining() {
        guard phase == .running else { return }
        isCancelling = true
    }

    /// Sends the failed items again. Uploads Apple already accepted are
    /// reused.
    func retryFailed() {
        guard phase == .finished else { return }
        var retried = false
        for item in items where status(of: item).isFailure {
            statuses[item.id] = .waiting
            retried = true
        }
        if retried { start() }
    }

    /// Waits for the current round to end (tests).
    func waitUntilFinished() async {
        await task?.value
    }

    private func sendWaiting() async {
        for item in items where status(of: item) == .waiting {
            if isCancelling {
                statuses[item.id] = .cancelled
            } else if let stopReason {
                statuses[item.id] = .failed(stopReason)
            } else {
                await send(item)
            }
        }
    }

    private func finishRound() async {
        phase = .finished
        pausedUntil = nil
        isCancelling = false
        await onFinish(self)
    }

    /// One item: find its groups, make sure an App Preview has room,
    /// upload and wait for processing, then place it.
    private func send(_ item: ExtrasPushItem) async {
        do {
            let targets = try await targets(for: item)
            if case .appPreview = item.kind { try await checkPreviewRoom(for: item, in: targets) }
            let asset = try await processedAsset(for: item)
            statuses[item.id] = .placing
            let placementIDs = try await place(asset, item: item, targets: targets)
            statuses[item.id] = .done(assetID: asset.id, placementIDs: placementIDs)
        } catch {
            statuses[item.id] = status(for: error)
        }
    }
}
