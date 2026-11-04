//
//  ExtrasPushRun.swift
//  AppLocalizer
//

import Foundation
import Observation
import OSLog

/// One push of Autopilot's extras (header and search results artwork, App
/// Previews) through the App Asset Library. Each file is reserved in the
/// app's library, uploaded in parts, committed and processed; only then is
/// it placed, so a failed upload never touches the page. Uploads go one at
/// a time, and the next starts while Apple processes the ones before it (up
/// to `ExtrasPushEnvironment.processingWindow` at once); placements go one
/// at a time too. Artwork takes the place of what's in its slot; an App
/// Preview replaces the ones it names and goes first in its group. Apple's
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
    /// When the current round started.
    var startedAt: Date?
    /// The items in flight (one uploading, the rest with Apple or being
    /// placed) and how far each has got.
    var activities: [ExtrasPushItem.ID: ExtrasPushActivity] = [:]
    /// What each item sent this push did, oldest first.
    var events: [ExtrasPushEvent] = []
    /// The next upload waits for one of the files with Apple to finish:
    /// `processingWindow` are in flight.
    var waitsForRoom = false

    let environment: ExtrasPushEnvironment
    /// Called when a round ends, to record what it did.
    @ObservationIgnored var onFinish: @MainActor (ExtrasPushRun) async -> Void = { _ in }
    /// Called as soon as an item is placed, before the next placement, to
    /// note it: a push cut short (the app quit) then doesn't send it again.
    @ObservationIgnored var onItemDone: @MainActor (ExtrasPushItem) async -> Void = { _ in }
    @ObservationIgnored private var task: Task<Void, Never>?

    /// Each app's library ID, read once.
    @ObservationIgnored var libraryIDs: [StoreApp.ID: String] = [:]
    /// Apple's reference data, read once.
    @ObservationIgnored var refData: AssetLibraryRefData?
    /// Uploads Apple accepted, by item, so a retry doesn't send the file
    /// again: it waits for processing or places it.
    @ObservationIgnored var committedAssets: [ExtrasPushItem.ID: AssetLibraryAsset] = [:]
    @ObservationIgnored var processedItemIDs: Set<ExtrasPushItem.ID> = []
    /// The last placement asked for: each waits for the one before it.
    @ObservationIgnored private var lastPlacement: Task<Void, Never>?

    /// Each failure with Apple's words, so it can be read after the sheet
    /// closes (`log show --predicate 'subsystem == "com.lima.applocalizer"'`).
    private static let logger = Logger(subsystem: "com.lima.applocalizer", category: "ExtrasPush")

    /// An item uploaded and committed, waiting for Apple's processing.
    private struct Upload: Sendable {
        var item: ExtrasPushItem
        var targets: [ExtrasPushTarget]
        var asset: AssetLibraryAsset
        var began: Date
    }

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
        startedAt = environment.now()
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

    /// Uploads the waiting items one by one; each goes on to processing
    /// and placing while the next uploads, with at most
    /// `processingWindow` uploaded and not finished.
    private func sendWaiting() async {
        let window = max(1, environment.processingWindow)
        await withTaskGroup(of: Void.self) { group in
            var inFlight = 0
            for item in items where status(of: item) == .waiting {
                waitsForRoom = inFlight >= window
                while inFlight >= window, await group.next() != nil {
                    inFlight -= 1
                }
                waitsForRoom = false
                if isCancelling {
                    statuses[item.id] = .cancelled
                } else if let stopReason {
                    statuses[item.id] = .failed(stopReason)
                } else if let upload = await upload(item) {
                    inFlight += 1
                    group.addTask { await self.finish(upload) }
                }
            }
        }
    }

    private func finishRound() async {
        phase = .finished
        activities = [:]
        waitsForRoom = false
        pausedUntil = nil
        isCancelling = false
        await onFinish(self)
    }

    /// Finds the item's groups, makes sure an App Preview has room, and
    /// uploads and commits it (or reuses an earlier round's upload). Nil
    /// when it failed: its status says why.
    private func upload(_ item: ExtrasPushItem) async -> Upload? {
        let began = environment.now()
        activities[item.id] = ExtrasPushActivity(itemID: item.id, startedAt: began, stepStartedAt: began)
        enter(.preparing, for: item.id)
        do {
            let targets = try await targets(for: item)
            if case .appPreview = item.kind { try await checkPreviewRoom(for: item, in: targets) }
            let asset = try await committedAsset(for: item)
            return Upload(item: item, targets: targets, asset: asset, began: began)
        } catch {
            statuses[item.id] = status(for: error)
            end(item, began: began)
            return nil
        }
    }

    /// Waits for Apple to process the upload, then places it once the
    /// placements before it are done.
    private func finish(_ upload: Upload) async {
        let item = upload.item
        do {
            try await process(upload.asset, for: item)
            try await inTurn {
                self.enter(.placing, for: item.id)
                let placementIDs = try await self.place(upload.asset, item: item, targets: upload.targets)
                self.statuses[item.id] = .done(assetID: upload.asset.id, placementIDs: placementIDs)
                await self.onItemDone(item)
            }
        } catch {
            statuses[item.id] = status(for: error)
        }
        end(item, began: upload.began)
    }

    /// Runs `body` after the placements asked for before it.
    private func inTurn<Result: Sendable>(_ body: @escaping @MainActor () async throws -> Result) async throws -> Result {
        let before = lastPlacement
        let mine = Task { @MainActor () -> Result in
            await before?.value
            return try await body()
        }
        lastPlacement = Task { _ = try? await mine.value }
        return try await mine.value
    }

    /// Notes what the item did and how long it took.
    private func end(_ item: ExtrasPushItem, began: Date) {
        if let reason = status(of: item).failureReason {
            Self.logger.error("\(item.id, privacy: .public) failed: \(reason, privacy: .public)")
        }
        let ended = environment.now()
        events.append(ExtrasPushEvent(id: events.count, item: item, status: status(of: item), date: ended, seconds: ended.timeIntervalSince(began)))
        activities[item.id] = nil
    }

    /// Moves the item to `status`, its step's clock starting again.
    func enter(_ status: ExtrasPushStatus, for id: ExtrasPushItem.ID) {
        statuses[id] = status
        activities[id]?.stepStartedAt = environment.now()
    }
}
