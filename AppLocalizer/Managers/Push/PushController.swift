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
    private let now: () -> Date
    private var task: Task<Void, Never>?
    private var isCancelling = false
    private var reportedRateLimit: AppStoreConnectRateLimit?
    private var sentDates: [Date] = []

    init(queue: ChangeQueue, history: PushHistory, transport: (any PushTransport)? = nil, now: @escaping () -> Date = { .now }) {
        self.queue = queue
        self.history = history
        self.transport = transport
        self.now = now
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
    var rateLimit: AppStoreConnectRateLimit {
        if let reportedRateLimit { return reportedRateLimit }
        let hourAgo = now().addingTimeInterval(-3600)
        let used = sentDates.count { $0 > hourAgo }
        let limit = AppStoreConnectRateLimit.defaultHourlyLimit
        return AppStoreConnectRateLimit(limit: limit, remaining: max(0, limit - used))
    }

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

        for index in items.indices where items[index].status == .queued {
            if let reason = stopReason ?? (isCancelling ? String(localized: "Cancelled") : nil) {
                items[index].status = .notSent(reason)
                continue
            }
            let outcome = await process(index)
            switch outcome {
            case let .pushed(appID):
                pushedApps.insert(appID)
            case let .failed(text, stop):
                failures[items[index].id] = text
                stopReason = stop
            case let .stopped(reason):
                stopReason = reason
            case .skipped:
                break
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
        guard let change = queue.change(id: items[index].id) else {
            items[index].status = .notSent(String(localized: "Discarded"))
            return .skipped
        }
        guard !change.isBlocked else {
            items[index].status = change.needsDecision ? .conflict : .notSent(change.blockingMessage ?? "")
            return .skipped
        }
        items[index].change = change
        items[index].status = .sending
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
            if case let .failed(text) = status { return .failed(text, stop: stop) }
            return stop.map(ItemOutcome.stopped) ?? .skipped
        }
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
        for request in change.requests.dropFirst(items[index].sentRequestCount) {
            let response = try await transport.send(request)
            noteRequest(response.rateLimit)
            items[index].sentRequestCount += 1
        }
    }

    private func noteRequest(_ rateLimit: AppStoreConnectRateLimit?) {
        sentDates.append(now())
        sentDates.removeAll { $0 < now().addingTimeInterval(-3600) }
        if let rateLimit { reportedRateLimit = rateLimit }
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
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .hour, for: now())?.start ?? now()
        return start.addingTimeInterval(3600)
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

    /// What happened to one item, for the loop that sends them.
    private enum ItemOutcome {
        case pushed(StoreApp.ID)
        case failed(String, stop: String?)
        /// Not sent, and the rest stop too (rate limit, offline).
        case stopped(String)
        case skipped
    }
}
