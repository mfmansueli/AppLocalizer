//
//  ReviewPushViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The review sheet's state: which changes show (scope and source), which
/// are checked, and the actions on them. Pushing hands the changes to the
/// shared `PushController`, so the sheet can close while it runs.
@MainActor
@Observable
final class ReviewPushViewModel {
    var scope: ReviewScope
    /// nil shows every source.
    var sourceFilter: ChangeSourceFilter?
    var selection: Set<PendingChange.ID> = []

    let queue: ChangeQueue
    let push: PushController
    let selectedAppID: StoreApp.ID?
    private let appName: (StoreApp.ID) -> String
    private let pushConfirmation: PushConfirmation
    private let confirmsPriceIncreases: Bool

    init(
        queue: ChangeQueue,
        push: PushController,
        selectedAppID: StoreApp.ID?,
        appName: @escaping (StoreApp.ID) -> String,
        pushConfirmation: PushConfirmation = .overFifty,
        confirmsPriceIncreases: Bool = true
    ) {
        self.queue = queue
        self.push = push
        self.selectedAppID = selectedAppID
        self.appName = appName
        self.pushConfirmation = pushConfirmation
        self.confirmsPriceIncreases = confirmsPriceIncreases
        let hasAppChanges = selectedAppID.map { queue.hasChanges(for: $0) } ?? false
        scope = hasAppChanges || queue.totalCount == 0 ? .thisApp : .allApps
    }

    // MARK: - What shows

    var selectedAppName: String? { selectedAppID.map(appName) }
    var thisAppCount: Int { selectedAppID.map { queue.count(for: $0) } ?? 0 }
    var allAppsCount: Int { queue.totalCount }

    /// Changes in the current scope, before the source filter.
    var scopedChanges: [PendingChange] {
        switch scope {
        case .thisApp: selectedAppID.map { queue.changes(for: $0) } ?? []
        case .allApps: queue.changes
        }
    }

    var visibleChanges: [PendingChange] {
        guard let sourceFilter else { return scopedChanges }
        return scopedChanges.filter { $0.source.filter == sourceFilter }
    }

    /// All, then You, Machine translation and each assistant that has
    /// changes in scope.
    var sourceOptions: [ReviewSourceOption] {
        let scoped = scopedChanges
        var options = [ReviewSourceOption(filter: nil, count: scoped.count)]
        var order: [ChangeSourceFilter] = [.you, .machineTranslation]
        for change in scoped {
            let filter = change.source.filter
            if !order.contains(filter) { order.append(filter) }
        }
        for filter in order {
            let count = scoped.count { $0.source.filter == filter }
            if count > 0 { options.append(ReviewSourceOption(filter: filter, count: count)) }
        }
        return options
    }

    /// Assistants with proposals in scope, for "Reject All from …": all of
    /// them under All, the one picked under its own filter, none otherwise.
    var assistantsInScope: [String] {
        if let sourceFilter, !sourceFilter.isAssistant { return [] }
        var clients: [String] = []
        for change in scopedChanges {
            for source in [change.source, change.alternative?.source].compactMap(\.self) {
                if case let .assistant(client) = source, !clients.contains(client) { clients.append(client) }
            }
        }
        if case let .assistant(client) = sourceFilter { return clients.filter { $0 == client } }
        return clients
    }

    /// Visible changes grouped by app, then by heading, in the order made.
    var appGroups: [ReviewAppGroup] {
        var apps: [ReviewAppGroup] = []
        for change in visibleChanges {
            let appIndex = apps.firstIndex { $0.id == change.appID } ?? {
                apps.append(ReviewAppGroup(id: change.appID, appName: appName(change.appID), groups: []))
                return apps.count - 1
            }()
            let groupID = "\(change.appID)|\(change.section.rawValue)|\(change.group)"
            if let groupIndex = apps[appIndex].groups.firstIndex(where: { $0.id == groupID }) {
                apps[appIndex].groups[groupIndex].changes.append(change)
            } else {
                apps[appIndex].groups.append(ReviewChangeGroup(
                    id: groupID,
                    title: change.group,
                    section: change.section,
                    groupID: change.groupID,
                    note: change.groupNote,
                    changes: [change]
                ))
            }
        }
        return apps
    }

    var attentionCount: Int { visibleChanges.count(where: \.isBlocked) }

    var subtitle: String {
        let count = visibleChanges.count
        let changes = count == 1 ? String(localized: "1 change") : String(localized: "\(count) changes")
        guard attentionCount > 0 else { return changes }
        return changes + " · " + (attentionCount == 1 ? String(localized: "1 needs attention") : String(localized: "\(attentionCount) need attention"))
    }

    var pushableChanges: [PendingChange] { visibleChanges.filter { !$0.isBlocked } }
    var selectedPushableChanges: [PendingChange] { pushableChanges.filter { selection.contains($0.id) } }
    var estimate: PushEstimate { PushEstimate(changes: selection.isEmpty ? pushableChanges : selectedPushableChanges) }

    /// What the footer says about options that are on, e.g. "2 declarations
    /// publish immediately when pushed": one line per kind of option, for
    /// the changes a push would send.
    var optionFootnotes: [String] {
        let changes = selection.isEmpty ? pushableChanges : selectedPushableChanges
        var counts: [(footnote: ChangeOptionFootnote, count: Int)] = []
        for change in changes {
            guard let option = change.option, option.isEffective, let footnote = option.footnote else { continue }
            if let index = counts.firstIndex(where: { $0.footnote == footnote }) {
                counts[index].count += 1
            } else {
                counts.append((footnote, 1))
            }
        }
        return counts.map { $0.footnote.text(count: $0.count) }
    }

    // MARK: - Selection

    func isSelected(_ id: PendingChange.ID) -> Bool { selection.contains(id) }

    func toggle(_ id: PendingChange.ID) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    // MARK: - Actions

    func discard(_ id: PendingChange.ID) {
        selection.remove(id)
        queue.discard(id: id)
    }

    /// "Discard All": every change the sheet shows.
    func discardVisible() {
        let ids = visibleChanges.map(\.id)
        selection.subtract(ids)
        queue.discard(ids: ids)
    }

    func rejectAll(fromAssistant client: String) {
        queue.rejectAll(fromAssistant: client)
        if sourceFilter == .assistant(client) { sourceFilter = nil }
        selection.formIntersection(queue.changes.map(\.id))
    }

    func keepMine(_ id: PendingChange.ID) { queue.keepMine(id: id) }
    func useRemote(_ id: PendingChange.ID) { discard(id) }

    func resolveAlternative(_ id: PendingChange.ID, keepAlternative: Bool) {
        queue.resolveAlternative(id: id, keepAlternative: keepAlternative)
    }

    /// Flips a change's option, e.g. "Publish to the App Store".
    func setOption(_ id: PendingChange.ID, isOn: Bool) {
        queue.setOption(id: id, isOn: isOn)
    }

    /// What a push of `changes` should confirm first, if anything: a large
    /// push, or price increases existing subscribers may have to agree to.
    func confirmationMessage(for changes: [PendingChange]) -> String? {
        var lines: [String] = []
        if pushConfirmation.requiresConfirmation(changeCount: changes.count) {
            lines.append(String(localized: "\(changes.count) changes will be sent to App Store Connect, one request at a time."))
        }
        let increases = changes.count { $0.section == .subscriptionPricing && ($0.deltaPercent ?? 0) > 0 }
        if confirmsPriceIncreases, increases > 0 {
            lines.append(String(localized: "\(increases) prices go up. Apple may ask existing subscribers to agree before they renew."))
        }
        return lines.isEmpty ? nil : lines.joined(separator: "\n\n")
    }

    /// Starts pushing; the sheet switches to the progress list.
    func startPush(_ changes: [PendingChange]) {
        selection.subtract(changes.map(\.id))
        push.push(changes)
    }
}
