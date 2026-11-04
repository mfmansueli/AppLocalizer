//
//  ExtrasPushRun+Progress.swift
//  AppLocalizer
//

import Foundation

/// What Review & Push says while extras are pushed: how many are done,
/// each item in flight and its step, how long it's been and about how long
/// is left, a pause for the hourly budget, and a waiting item's place in
/// line.
extension ExtrasPushRun {
    /// The item with this ID, if it's in the push.
    func pushItem(_ id: ExtrasPushItem.ID) -> ExtrasPushItem? {
        items.first { $0.id == id }
    }

    /// The items in flight, in push order.
    var itemsInFlight: [ExtrasPushItem] {
        items.filter { activities[$0.id] != nil }
    }

    /// "5 of 28 done · 1 failed".
    var countTitle: String {
        var parts = [String(localized: "\(doneCount) of \(totalCount) done")]
        if failedCount > 0 { parts.append(String(localized: "\(failedCount) failed")) }
        return parts.joined(separator: " · ")
    }

    /// What `item` is doing now, e.g. "Uploading 42% · 3.1 MB of 7.4 MB",
    /// "Apple is processing it · 0:42 · checked 3 times", "Placing it on
    /// the product page header"; nil when it isn't in flight.
    func stepDetail(of item: ExtrasPushItem, now: Date) -> String? {
        guard let activity = activities[item.id] else { return nil }
        let inStep = Self.clock(now.timeIntervalSince(activity.stepStartedAt))
        switch status(of: item) {
        case .preparing:
            return preparingDetail(of: item)
        case let .uploading(fraction):
            let percent = Int((min(1, max(0, fraction)) * 100).rounded(.down))
            guard activity.totalBytes > 0 else { return String(localized: "Uploading \(percent)%") }
            let sent = Int64(activity.sentBytes).formatted(.byteCount(style: .file))
            let total = Int64(activity.totalBytes).formatted(.byteCount(style: .file))
            return String(localized: "Uploading \(percent)% · \(sent) of \(total)")
        case .processing:
            if activity.checks > 1 { return String(localized: "Apple is processing it · \(inStep) · checked \(activity.checks) times") }
            return String(localized: "Apple is processing it · \(inStep)")
        case .placing:
            if case .appPreview = item.kind { return String(localized: "Placing it first in App Previews") }
            let names = item.kind.placementTypes.map(ExtrasPushKind.name(ofPlacementType:))
            return String(localized: "Placing it on \(names.formatted(.list(type: .and)))")
        case .waiting, .done, .failed, .cancelled:
            return nil
        }
    }

    /// Before its upload: the first reads Apple's sizes and the library,
    /// an App Preview checks there's room.
    private func preparingDetail(of item: ExtrasPushItem) -> String {
        if refData == nil || libraryIDs[item.appID] == nil {
            return String(localized: "Getting ready: reading Apple’s sizes and the app’s asset library")
        }
        if case .appPreview = item.kind { return String(localized: "Getting ready: checking its App Previews have room") }
        return String(localized: "Getting ready: finding where it goes")
    }

    /// "6:12 so far · about 18 min left"; nil before the push starts.
    func timeTitle(now: Date) -> String? {
        guard let startedAt else { return nil }
        let elapsed = String(localized: "\(Self.clock(now.timeIntervalSince(startedAt))) so far")
        guard let left = remainingSeconds(now: now) else { return elapsed }
        if left < 60 { return String(localized: "\(elapsed) · less than a minute left") }
        return String(localized: "\(elapsed) · about \(Int((left / 60).rounded(.up))) min left")
    }

    /// About how long the rest takes, from how fast items have finished so
    /// far (uploads overlap Apple's processing, so it's the pace, not each
    /// item's own time). Nil until one finished, while paused, or once
    /// nothing's left.
    func remainingSeconds(now: Date) -> TimeInterval? {
        guard isRunning, pausedUntil == nil, let startedAt, !events.isEmpty else { return nil }
        let left = isCancelling ? activities.count : items.count { !status(of: $0).isFinished }
        guard left > 0 else { return nil }
        let pace = now.timeIntervalSince(startedAt) / Double(events.count)
        return pace * Double(left)
    }

    /// A waiting item's place in line while the push runs: "Next",
    /// "Waiting · 6 ahead"; nil otherwise.
    func queueTitle(of item: ExtrasPushItem) -> String? {
        guard isRunning, !isCancelling, status(of: item) == .waiting, let index = items.firstIndex(of: item) else { return nil }
        let ahead = items[..<index].count { status(of: $0) == .waiting }
        return ahead == 0 ? String(localized: "Next") : String(localized: "Waiting · \(ahead) ahead")
    }

    /// The failures so far, one entry per reason in the order they
    /// happened, with the items that failed for it.
    var failureGroups: [ExtrasPushFailureGroup] {
        var groups: [ExtrasPushFailureGroup] = []
        for (item, reason) in failures {
            if let index = groups.firstIndex(where: { $0.reason == reason }) {
                groups[index].items.append(item)
            } else {
                groups.append(ExtrasPushFailureGroup(reason: reason, items: [item]))
            }
        }
        return groups
    }

    /// While the next upload waits for room: "10 files are with Apple; the
    /// next uploads as soon as one is placed."
    var roomTitle: String? {
        guard isRunning, waitsForRoom, !isCancelling, pausedUntil == nil else { return nil }
        return String(localized: "\(activities.count) files are with Apple; the next uploads as soon as one is placed.")
    }

    /// While the hourly budget is used up: when it goes on.
    var pauseTitle: String? {
        guard let pausedUntil else { return nil }
        let time = pausedUntil.formatted(date: .omitted, time: .shortened)
        return String(localized: "Paused until \(time): App Store Connect’s hourly request limit is used up. It goes on by itself.")
    }

    /// After Cancel Remaining: what still finishes.
    var cancellingTitle: String? {
        guard isRunning, isCancelling else { return nil }
        let count = activities.count
        if count == 0 { return String(localized: "Cancelling…") }
        return count == 1
            ? String(localized: "Cancelling: the item in flight finishes, the rest won’t go.")
            : String(localized: "Cancelling: the \(count) items in flight finish, the rest won’t go.")
    }

    /// "0:42", "1:02:05".
    static func clock(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        let pattern: Duration.TimeFormatStyle.Pattern = whole >= 3600 ? .hourMinuteSecond : .minuteSecond
        return Duration.seconds(whole).formatted(.time(pattern: pattern))
    }
}
