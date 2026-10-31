//
//  PushController.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Sends reviewed changes to App Store Connect, one request at a time, and
/// keeps the progress list Review & Push shows. It lives above the sheet, so
/// a push keeps going while the person works elsewhere.
///
/// Each change is checked first when it has a `ConflictCheck`; a value that
/// changed in App Store Connect isn't overwritten but goes back to review.
/// Pushed changes leave the queue and are recorded in `PushHistory`.
///
/// A change sends its `pushRequests` (its own, then its option's when that's
/// on). Changes with the same `mergeKey` (an age rating declaration's
/// answers) go out together as one `PATCH`, since App Store Connect only
/// takes that resource whole. Placeholders are filled in just before each request goes: a
/// `{createdID}` with the ID an earlier `POST` of the same change returned,
/// a `{secret:…}` from `secrets`.
@MainActor
@Observable
final class PushController {
    enum Phase: Hashable, Sendable {
        case idle
        case running
        case finished
    }

    private(set) var phase: Phase = .idle
    private(set) var items: [PushItem] = []
    /// What the workspace banner shows; nil when there's nothing to report.
    private(set) var notice: PushNotice?
    /// Set by the session: the API client, or a simulation.
    var transport: (any PushTransport)?
    /// The app names Activity records carry.
    var appName: (StoreApp.ID) -> String = { $0 }
    /// Called with the apps whose values changed, so their numbers reload.
    var onPushed: (Set<StoreApp.ID>) -> Void = { _ in }

    private let queue: ChangeQueue
    private let history: PushHistory
    /// Where `{secret:…}` placeholders are read from (the Keychain).
    private let secrets: any SecretStore
    private let now: () -> Date
    private var task: Task<Void, Never>?
    private var isCancelling = false
    /// Requests this hour, shared with screenshot pushes.
    let rateTracker: RequestRateTracker
    /// Screenshot pushes: images uploaded set by set beside these changes.
    let screenshots: ScreenshotPushController

    init(
        queue: ChangeQueue,
        history: PushHistory,
        transport: (any PushTransport)? = nil,
        secrets: any SecretStore = KeychainSecretStore(),
        now: @escaping () -> Date = { .now }
    ) {
        self.queue = queue
        self.history = history
        self.transport = transport
        self.secrets = secrets
        self.now = now
        let rateTracker = RequestRateTracker(now: now)
        self.rateTracker = rateTracker
        screenshots = ScreenshotPushController(history: history, rate: rateTracker, now: now)
        screenshots.appName = { [weak self] id in self?.appName(id) ?? id }
        screenshots.onPushed = { [weak self] appIDs in self?.onPushed(appIDs) }
    }

    // MARK: - Progress

    var totalCount: Int { items.count }
    var doneCount: Int { items.count { $0.status == .done } }
    var failedCount: Int { items.count { $0.status.isFailure } }
    var finishedCount: Int { items.count { $0.status.isFinished } }
    var progress: Double { items.isEmpty ? 0 : Double(finishedCount) / Double(items.count) }
    var isRunning: Bool { phase == .running }
    /// Whether this push changed prices, so "View Results" applies.
    var changedPrices: Bool {
        items.contains { $0.status == .done && $0.change.section == .subscriptionPricing }
    }

    /// Requests used this hour: Apple's own count when a response reported
    /// it, otherwise what this Mac sent in the last hour.
    var rateLimit: AppStoreConnectRateLimit { rateTracker.rateLimit }

    var title: String {
        switch phase {
        case .idle, .running:
            return totalCount == 1 ? String(localized: "Pushing 1 change") : String(localized: "Pushing \(totalCount) changes")
        case .finished:
            guard failedCount > 0 else { return String(localized: "\(doneCount) pushed") }
            return String(localized: "\(doneCount) pushed · \(failedCount) failed")
        }
    }

    var subtitle: String {
        switch phase {
        case .idle, .running:
            let sent = String(localized: "\(finishedCount) of \(totalCount) sent")
            let failed = failedCount > 0 ? String(localized: " · \(failedCount) failed") : ""
            return sent + failed + String(localized: " · one request at a time")
        case .finished:
            if failedCount > 0 { return String(localized: "Failed changes stay here. Retry them or fix them first.") }
            let notSent = items.count { !$0.status.isFailure && $0.status != .done }
            if notSent > 0 { return String(localized: "\(notSent) not sent. They stay in Review & Push.") }
            return String(localized: "Everything reached App Store Connect.")
        }
    }

    // MARK: - Running

    /// Starts pushing `changes` in order. Blocked ones are left in review.
    func push(_ changes: [PendingChange]) {
        guard phase != .running else { return }
        items = changes.filter { !$0.isBlocked }.map { PushItem(change: $0) }
        notice = nil
        guard !items.isEmpty else { return }
        run()
    }

    /// Lets the request in flight finish and marks the rest as not sent.
    func cancelRemaining() {
        guard phase == .running else { return }
        isCancelling = true
    }

    /// Sends the failed changes again, resuming after any request of theirs
    /// that already went through.
    func retryFailed() {
        guard phase == .finished else { return }
        var retried = false
        for index in items.indices where items[index].status.isFailure {
            if let current = queue.change(id: items[index].id) {
                items[index].change = current
                items[index].status = .queued
                retried = true
            }
        }
        guard retried else { return }
        notice = nil
        run()
    }

    /// Clears a finished push so the sheet shows the review list again.
    func dismissFinished() {
        guard phase == .finished else { return }
        phase = .idle
        items = []
    }

    /// Shows a banner about App Store Connect (offline, rate limited, an
    /// API error) outside a push, e.g. when a section's load hit one.
    func report(_ notice: PushNotice) {
        self.notice = notice
    }

    func dismissNotice() {
        notice = nil
    }

    /// Waits for the current push to end (tests).
    func waitUntilFinished() async {
        await task?.value
    }

    private func run() {
        phase = .running
        isCancelling = false
        task = Task { [weak self] in
            await self?.sendQueuedItems()
        }
    }

    private func sendQueuedItems() async {
        var pushedApps: Set<StoreApp.ID> = []
        var failures: [PendingChange.ID: String] = [:]
        var stopReason: String?

        // Items sent with an earlier one's merged request aren't queued
        // anymore when the loop reaches them.
        for index in items.indices where items[index].status == .queued {
            if let reason = stopReason ?? (isCancelling ? String(localized: "Cancelled") : nil) {
                items[index].status = .notSent(reason)
                continue
            }
            let batch = mergedBatch(startingAt: index)
            let outcomes: [(Int, ItemOutcome)]
            if batch.count > 1 {
                outcomes = await processMerged(batch)
            } else {
                let outcome = await process(index)
                outcomes = [(index, outcome)]
            }
            for (itemIndex, outcome) in outcomes {
                switch outcome {
                case let .pushed(appID):
                    pushedApps.insert(appID)
                case let .failed(text, stop):
                    failures[items[itemIndex].id] = text
                    stopReason = stop ?? stopReason
                case let .stopped(reason):
                    stopReason = reason
                case .skipped:
                    break
                }
            }
        }

        record(failures: failures)
        phase = .finished
        isCancelling = false
        if failedCount > 0, notice == nil {
            notice = .partialFailure(failed: failedCount, total: totalCount)
        }
        if !pushedApps.isEmpty { onPushed(pushedApps) }
    }

    /// Sends one item and sets its status.
    private func process(_ index: Int) async -> ItemOutcome {
        guard prepare(index) else { return .skipped }
        let change = items[index].change
        do {
            try await send(index)
            items[index].status = .done
            queue.discard(id: change.id)
            return .pushed(change.appID)
        } catch let conflict as ConflictFound {
            items[index].status = .conflict
            queue.markRemoteConflict(id: change.id, conflict.conflict)
            return .skipped
        } catch {
            let (status, stop) = handle(error)
            items[index].status = status
            return Self.outcome(status, stop: stop)
        }
    }

    // MARK: - Merged writes

    /// The queued items sent with the one at `index`: itself, then the later
    /// ones whose change shares its merge key.
    private func mergedBatch(startingAt index: Int) -> [Int] {
        guard let key = queue.change(id: items[index].id)?.mergeKey else { return [index] }
        return [index] + items.indices.filter { other in
            other > index && items[other].status == .queued && queue.change(id: items[other].id)?.mergeKey == key
        }
    }

    /// Sends items whose changes write one resource App Store Connect only
    /// takes whole: their conflict checks (one `GET` per path), then a
    /// single `PATCH` with all their attributes. Those that go out succeed
    /// or fail together.
    private func processMerged(_ indices: [Int]) async -> [(Int, ItemOutcome)] {
        var sending = indices.filter { prepare($0) }
        var outcomes = indices.filter { !sending.contains($0) }.map { ($0, ItemOutcome.skipped) }
        do {
            guard let transport else { throw AppStoreConnectError.invalidResponse }
            let conflicted = try await markMergedConflicts(among: sending, transport: transport)
            outcomes += conflicted.map { ($0, .skipped) }
            sending.removeAll(where: conflicted.contains)
            guard !sending.isEmpty else { return outcomes }
            try await sendMerged(sending, transport: transport)
            outcomes += sending.map { ($0, .pushed(items[$0].change.appID)) }
        } catch {
            let (status, stop) = handle(error)
            for index in sending where items[index].status == .sending {
                items[index].status = status
                outcomes.append((index, Self.outcome(status, stop: stop)))
            }
        }
        return outcomes
    }

    /// Takes the item at `index` from the queue to send it, or sets why it
    /// can't go (discarded, or blocked by a conflict or a problem).
    private func prepare(_ index: Int) -> Bool {
        guard let change = queue.change(id: items[index].id) else {
            items[index].status = .notSent(String(localized: "Discarded"))
            return false
        }
        guard !change.isBlocked else {
            items[index].status = change.needsDecision ? .conflict : .notSent(change.blockingMessage ?? "")
            return false
        }
        items[index].change = change
        items[index].status = .sending
        return true
    }

    /// Runs the merged items' conflict checks, fetching each path once, and
    /// marks those App Store Connect changed since; returns them.
    private func markMergedConflicts(among indices: [Int], transport: any PushTransport) async throws -> [Int] {
        var fetched: [String: Data] = [:]
        var conflicted: [Int] = []
        for index in indices {
            guard let check = items[index].change.conflictCheck else { continue }
            if fetched[check.path] == nil {
                let response = try await transport.fetch(check.path)
                noteRequest(response.rateLimit)
                fetched[check.path] = response.data
            }
            let actual = check.value(in: fetched[check.path] ?? Data())
            guard check.differs(from: actual) else { continue }
            items[index].status = .conflict
            queue.markRemoteConflict(
                id: items[index].id,
                RemoteConflict(remoteRawValue: actual, remoteDisplayValue: check.format.display(actual))
            )
            conflicted.append(index)
        }
        return conflicted
    }

    /// One `PATCH` for every item in `indices`, which are all done after it.
    private func sendMerged(_ indices: [Int], transport: any PushTransport) async throws {
        guard let request = PushRequest.merged(indices.map { items[$0].change.pushRequests[0] }) else {
            throw AppStoreConnectError.invalidResponse
        }
        let resolved = try request.resolved(createdID: nil) { try secrets.secret(named: $0) }
        let response = try await transport.send(resolved)
        noteRequest(response.rateLimit)
        for index in indices {
            items[index].sentRequestCount = 1
            items[index].status = .done
            queue.discard(id: items[index].id)
        }
    }

    private static func outcome(_ status: PushItemStatus, stop: String?) -> ItemOutcome {
        if case let .failed(text) = status { return .failed(text, stop: stop) }
        return stop.map(ItemOutcome.stopped) ?? .skipped
    }

    /// Checks for a conflict, then sends the item's remaining requests.
    private func send(_ index: Int) async throws {
        guard let transport else { throw AppStoreConnectError.invalidResponse }
        let change = items[index].change
        if items[index].sentRequestCount == 0, let check = change.conflictCheck {
            let response = try await transport.fetch(check.path)
            noteRequest(response.rateLimit)
            let actual = check.value(in: response.data)
            if check.differs(from: actual) {
                throw ConflictFound(conflict: RemoteConflict(remoteRawValue: actual, remoteDisplayValue: check.format.display(actual)))
            }
        }
        for request in change.pushRequests.dropFirst(items[index].sentRequestCount) {
            let resolved = try request.resolved(createdID: items[index].createdID) { try secrets.secret(named: $0) }
            let response = try await transport.send(resolved)
            noteRequest(response.rateLimit)
            items[index].sentRequestCount += 1
            if request.method == .post, let id = Self.createdID(in: response.data) {
                items[index].createdID = id
            }
        }
    }

    private func noteRequest(_ rateLimit: AppStoreConnectRateLimit?) {
        rateTracker.note(rateLimit)
    }

    /// The row status for an error, and why the rest stop, if they do.
    private func handle(_ error: any Error) -> (PushItemStatus, stop: String?) {
        if let error = error as? AppStoreConnectError {
            switch error {
            case .rateLimited:
                notice = .rateLimited(resumeAt: nextHour())
                return (.notSent(String(localized: "Rate limited")), String(localized: "Rate limited"))
            case .unauthorized, .invalidPrivateKey:
                notice = .apiError(error.errorDescription ?? "")
                return (.failed(error.pushFailureText), String(localized: "Stopped"))
            default:
                return (.failed(error.pushFailureText), nil)
            }
        }
        if let error = error as? URLError, Self.offlineCodes.contains(error.code) {
            notice = .offline
            return (.notSent(String(localized: "Offline")), String(localized: "Offline"))
        }
        return (.failed(error.localizedDescription), nil)
    }

    private func nextHour() -> Date {
        rateTracker.nextHour()
    }

    /// One Activity record per app that had something sent or refused.
    private func record(failures: [PendingChange.ID: String]) {
        let attempted = items.filter { $0.status == .done || failures[$0.id] != nil }
        let byApp = Dictionary(grouping: attempted, by: \.change.appID)
        let date = now()
        for (appID, appItems) in byApp {
            let pushed = appItems.filter { $0.status == .done }.map(\.change)
            let failed = appItems.compactMap { item in failures[item.id].map { (item.id, $0) } }
            history.add(PushRecord(
                date: date,
                appID: appID,
                appName: appName(appID),
                title: PushRecord.title(for: appItems.map(\.change)),
                pushed: pushed,
                failures: Dictionary(uniqueKeysWithValues: failed),
                failedChanges: appItems.filter { failures[$0.id] != nil }.map(\.change)
            ))
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut, .dnsLookupFailed,
    ]

    /// Thrown by `send` when the conflict check found a different value.
    private struct ConflictFound: Error {
        var conflict: RemoteConflict
    }

    /// The `data.id` of a `POST`'s response: the resource it created.
    private static func createdID(in data: Data) -> String? {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (object?["data"] as? [String: Any])?["id"] as? String
    }

    /// What happened to one item, for the loop that sends them.
    private enum ItemOutcome {
        case pushed(StoreApp.ID)
        case failed(String, stop: String?)
        /// Not sent, and the rest stop too (rate limit, offline).
        case stopped(String)
        case skipped
    }
}
