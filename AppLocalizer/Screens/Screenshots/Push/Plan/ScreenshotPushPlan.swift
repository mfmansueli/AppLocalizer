//
//  ScreenshotPushPlan.swift
//  AppLocalizer
//

import Foundation

/// What a screenshot push of one app would change, derived from its
/// screenshot document, its renders and the sets live in App Store
/// Connect (`ScreenshotPushPlanner`). Nothing here is queued by hand:
/// editing a caption, a capture or the template changes the plan.
struct ScreenshotPushPlan: Hashable, Sendable {
    var appID: StoreApp.ID
    var appName: String
    var version: ScreenshotsVersion
    /// "English (U.S.)": what a locale without its own set shows.
    var primaryLocaleName: String
    /// The sets that change, iPhone then iPad, locales in scope order.
    var groups: [ScreenshotPlanGroup]
    /// Renders that differ from what's live but can't go: failed checks.
    var excluded: [ScreenshotPlanExclusion]
    /// Renders discarded in review ("keep what's live"), until they
    /// change again.
    var kept: [ScreenshotPlanItem]
    /// Why nothing can be pushed, e.g. no version being prepared; nil
    /// when it can.
    var blockedReason: String?

    static func empty(appID: StoreApp.ID, appName: String, version: ScreenshotsVersion, primaryLocaleName: String = "") -> ScreenshotPushPlan {
        ScreenshotPushPlan(
            appID: appID, appName: appName, version: version, primaryLocaleName: primaryLocaleName, groups: [], excluded: [], kept: [],
            blockedReason: nil
        )
    }

    var items: [ScreenshotPlanItem] { groups.flatMap(\.items) }

    var canPush: Bool { blockedReason == nil }

    /// Nothing to show in review: no images, no renders left out and
    /// nothing discarded.
    var isEmpty: Bool { groups.isEmpty && excluded.isEmpty && kept.isEmpty }

    /// Renders that fail a check, for the banner.
    var failedChecks: [ScreenshotPlanExclusion] { excluded.filter(\.isFailedCheck) }

    /// Renders waiting for a localization App Store Connect doesn't have.
    var missingLocalizations: [ScreenshotPlanExclusion] { excluded.filter { !$0.isFailedCheck } }

    func group(containing item: ScreenshotPlanItem) -> ScreenshotPlanGroup? {
        groups.first { group in group.items.contains { $0.id == item.id } }
    }

    /// "Lumen Journal · Screenshots · Version 1.4", the review section's
    /// heading.
    var heading: String {
        String(localized: "\(appName) · Screenshots · Version \(version.versionString)")
    }
}
