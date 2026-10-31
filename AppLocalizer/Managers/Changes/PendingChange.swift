//
//  PendingChange.swift
//  AppLocalizer
//

import Foundation

/// One edit waiting in Review & Push. Every change goes through review,
/// whether the person made it, a suggestion filled it, machine translation
/// produced it or an assistant proposed it.
struct PendingChange: Identifiable, Hashable, Codable, Sendable {
    /// Stable per target, so editing the same thing twice replaces the change
    /// instead of adding another, e.g. `price.<subscriptionID>.<territoryID>`
    /// or `listing.<versionID>.<locale>.<field>`.
    var id: String
    var appID: StoreApp.ID
    var section: AppWorkspaceSection
    /// The heading this change is grouped under in the review sheet, e.g.
    /// "Subscription Pricing · Lumen Plus Annual" or "Store Page · Version 1.4".
    var group: String
    /// What the group is about, e.g. the subscription ID of a price change,
    /// so the schedule line's "Edit…" can open it.
    var groupID: String?
    /// A line shown under the group heading, e.g. the price schedule:
    /// "Prices change as soon as Apple processes them · existing subscribers
    /// keep their price".
    var groupNote: String?
    /// The territory or locale and field, e.g. "Brazil" or "German · Subtitle".
    var title: String
    /// ISO 3166 alpha-2 code of the flag shown before the title.
    var flagRegion: String?
    var oldValue: String
    var newValue: String
    /// Signed whole percent, for price changes (a delta pill).
    var deltaPercent: Int?
    var source: ChangeSource
    /// Why it can't be pushed (over the limit, invalid URL, unresolved
    /// conflict). Blocked changes stay pending and are skipped by a push.
    var blockedReason: String?
    /// The App Store Connect writes that apply it, in order.
    var requests: [PushRequest]
    /// The writes that put `oldValue` back, for "Restore Previous Values"
    /// after the push. Empty when the old value can't be restored.
    var restoreRequests: [PushRequest]
    var conflictCheck: ConflictCheck?
    /// Set when the value changed in App Store Connect since it was fetched.
    var remoteConflict: RemoteConflict?
    /// Set when the person and an assistant both edited this field.
    var alternative: ChangeAlternative?
    /// A switch the review row shows under the change, e.g. "Publish to the
    /// App Store"; nil for most changes.
    var option: ChangeOption?
    /// What it creates in App Store Connect, e.g. a new App Store language
    /// with its fields; Review & Push shows it as "Create the Polish page"
    /// with the fields under it. Nil for most changes.
    var creation: PendingCreation?
    var createdAt: Date

    init(
        id: String,
        appID: StoreApp.ID,
        section: AppWorkspaceSection,
        group: String,
        groupID: String? = nil,
        groupNote: String? = nil,
        title: String,
        flagRegion: String? = nil,
        oldValue: String,
        newValue: String,
        deltaPercent: Int? = nil,
        source: ChangeSource = .you,
        blockedReason: String? = nil,
        requests: [PushRequest],
        restoreRequests: [PushRequest] = [],
        conflictCheck: ConflictCheck? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.appID = appID
        self.section = section
        self.group = group
        self.groupID = groupID
        self.groupNote = groupNote
        self.title = title
        self.flagRegion = flagRegion
        self.oldValue = oldValue
        self.newValue = newValue
        self.deltaPercent = deltaPercent
        self.source = source
        self.blockedReason = blockedReason
        self.requests = requests
        self.restoreRequests = restoreRequests
        self.conflictCheck = conflictCheck
        self.createdAt = createdAt
    }

    /// Whether a push skips it: invalid, or a conflict nobody resolved yet.
    var isBlocked: Bool { blockedReason != nil || needsDecision }

    /// A conflict the review sheet asks the person to resolve.
    var needsDecision: Bool { remoteConflict != nil || alternative != nil }

    /// Why a push would skip it, for the row and the progress list.
    var blockingMessage: String? {
        if let blockedReason { return blockedReason }
        if remoteConflict != nil { return String(localized: "Changed in App Store Connect since your last fetch.") }
        if let alternative {
            return String(localized: "You and \(alternative.source.title) both changed this field.")
        }
        return nil
    }

    /// What a push sends, in order: the change's own requests, then its
    /// option's while the option is on.
    var pushRequests: [PushRequest] {
        guard let option, option.isEffective else { return requests }
        return requests + option.requests
    }

    /// Set when its one request writes a resource App Store Connect only
    /// takes whole (an age rating declaration): a push sends it in one
    /// request with the other changes that share the key.
    var mergeKey: String? {
        guard pushRequests.count == 1 else { return nil }
        return pushRequests[0].mergeKey
    }

    /// Requests a push sends for it, counting the conflict check's `GET`.
    var estimatedRequestCount: Int {
        pushRequests.count + (conflictCheck == nil ? 0 : 1)
    }

    /// The change that puts the old value back, or nil when it can't be
    /// restored (no restore requests were recorded).
    func restoring(at date: Date = .now) -> PendingChange? {
        guard !restoreRequests.isEmpty else { return nil }
        return PendingChange(
            id: id,
            appID: appID,
            section: section,
            group: group,
            groupID: groupID,
            groupNote: groupNote,
            title: title,
            flagRegion: flagRegion,
            oldValue: newValue,
            newValue: oldValue,
            deltaPercent: deltaPercent.flatMap(Self.reversed),
            source: .restore,
            requests: restoreRequests,
            restoreRequests: requests,
            createdAt: date
        )
    }

    /// The percent that undoes `percent`: −50% is undone by +100%.
    private static func reversed(_ percent: Int) -> Int? {
        guard percent > -100 else { return nil }
        return Int(((100 / (100 + Double(percent)) - 1) * 100).rounded())
    }
}
