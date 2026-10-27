//
//  ScreenshotPushController.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Observation

/// Review & Push for screenshots: each app's push plan (derived from its
/// screenshot document, its renders and the live sets), discards, restores
/// queued from Activity, and the running push. It lives in the
/// `PushController`, above the sheet, so a push keeps going while the
/// person works elsewhere.
///
/// Review and push live in `ScreenshotPushController+Review` and `+Push`,
/// restores in `+Restore`, thumbnails in `+Thumbnails`.
@MainActor
@Observable
final class ScreenshotPushController {
    /// Plans with something to show, by app.
    private(set) var plans: [StoreApp.ID: ScreenshotPushPlan] = [:]
    private(set) var loadingAppIDs: Set<StoreApp.ID> = []
    private(set) var loadErrors: [StoreApp.ID: String] = [:]
    /// The current or last push; nil before the first and once dismissed.
    var run: ScreenshotPushRun?
    /// Bumped whenever a push, a discard or a restore saved an app's
    /// screenshot document, so the Screenshots view reloads it.
    var revisions: [StoreApp.ID: Int] = [:]
    /// Show in Captions, for the Screenshots view to pick up.
    var captionsRequest: ScreenshotCaptionsRequest?
    /// Said after queueing a restore, until dismissed.
    var notice: String?
    /// Kept screenshots' thumbnails by backup image ID.
    var backupThumbnails: [String: CGImage] = [:]
    /// Restore Previous Screenshots… for Activity to open when it appears
    /// (DEBUG scenes).
    var pendingRestore: ScreenshotRestorePresentation?

    private(set) var workspace: ScreenshotPushWorkspace?
    /// The app names Activity records carry.
    @ObservationIgnored var appName: (StoreApp.ID) -> String = { $0 }
    /// Called with the apps a push changed, so their numbers reload.
    @ObservationIgnored var onPushed: (Set<StoreApp.ID>) -> Void = { _ in }
    /// How a paused push waits; tests return at once.
    @ObservationIgnored var sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    @ObservationIgnored var apps: [StoreApp.ID: StoreApp] = [:]
    @ObservationIgnored var contexts: [StoreApp.ID: ScreenshotsContext] = [:]
    @ObservationIgnored var liveSets: [StoreApp.ID: LiveScreenshots] = [:]
    @ObservationIgnored var renderQueues: [String: ScreenshotRenderQueue] = [:]
    @ObservationIgnored private var refreshCount: Int?

    let rate: RequestRateTracker
    let history: PushHistory
    let now: () -> Date

    init(history: PushHistory, rate: RequestRateTracker, now: @escaping () -> Date = { .now }) {
        self.history = history
        self.rate = rate
        self.now = now
    }

    /// Whether these services can push screenshots at all.
    var canPush: Bool { workspace?.pushing != nil }

    /// Points the controller at an account. Another account starts over.
    func attach(_ workspace: ScreenshotPushWorkspace?) {
        if workspace?.teamName != self.workspace?.teamName {
            plans = [:]
            loadErrors = [:]
            apps = [:]
            contexts = [:]
            liveSets = [:]
            renderQueues = [:]
            backupThumbnails = [:]
        }
        self.workspace = workspace
        #if DEBUG
        if pendingRestore == nil, let debug = workspace?.pushing as? DebugScreenshotPushServices {
            pendingRestore = debug.consumeRestoreOnOpen()
        }
        #endif
    }

    // MARK: - Plans

    /// The plans for `appIDs` that have something to show, in that order.
    func plans(for appIDs: [StoreApp.ID]) -> [ScreenshotPushPlan] {
        appIDs.compactMap { plans[$0] }
    }

    /// The plans in the order the apps were loaded.
    var orderedPlans: [ScreenshotPushPlan] {
        plans.values.sorted { $0.appName.localizedStandardCompare($1.appName) == .orderedAscending }
    }

    var isLoading: Bool { !loadingAppIDs.isEmpty }

    /// Plans the selected app, or every app. `refreshCount` is Refresh's
    /// (⌘R) count: when it changed, live sets are read again.
    func loadPlans(selectedAppID: StoreApp.ID?, allApps: Bool, refreshCount: Int = 0) async {
        guard let workspace, workspace.pushing != nil else {
            plans = [:]
            return
        }
        if self.refreshCount != refreshCount {
            self.refreshCount = refreshCount
            contexts = [:]
            liveSets = [:]
        }
        let library = await (try? workspace.apps()) ?? []
        for app in library {
            apps[app.id] = app
        }
        let targets = allApps ? library : library.filter { $0.id == selectedAppID }
        for app in targets {
            await loadPlan(for: app)
        }
        #if DEBUG
        // Push scenes start sending once the plans are in.
        if let debug = workspace.pushing as? DebugScreenshotPushServices, debug.consumeAutoPush() { push(orderedPlans) }
        #endif
    }

    /// Re-plans one app from its saved document and state, reading the
    /// version and live sets only when they aren't known yet.
    func loadPlan(for app: StoreApp) async {
        guard let workspace, let pushing = workspace.pushing else { return }
        apps[app.id] = app
        loadingAppIDs.insert(app.id)
        defer { loadingAppIDs.remove(app.id) }
        do {
            let screenshots = workspace.screenshots
            guard let guess = contexts[app.id]?.primaryLocale ?? StoreLocaleCatalog.locale(code: "en-US") else { return }
            let document = try await screenshots.document(for: app, primaryLocale: guess)
            var state = pushing.state.state(appID: app.id)
            if state.pruneRestores(keeping: { document.scope.isPinned($0) }) { try? pushing.state.save(state, appID: app.id) }
            guard document.template != nil || !state.restores.isEmpty else {
                plans[app.id] = nil
                return
            }
            let context = try await context(for: app, pushing: pushing)
            let live = try await live(for: app, context: context, screenshots: screenshots)
            let input = ScreenshotPlanInput(
                appID: app.id, appName: app.name, document: document, live: live, context: context, fonts: screenshots.fonts, state: state
            )
            let plan = await Task.detached(priority: .userInitiated) { ScreenshotPushPlanner().plan(input) }.value
            prepareThumbnails(for: plan, app: app)
            plans[app.id] = plan.isEmpty ? nil : plan
            loadErrors[app.id] = nil
        } catch {
            loadErrors[app.id] = error.localizedDescription
        }
    }

    private func context(for app: StoreApp, pushing: any ScreenshotPushServices) async throws -> ScreenshotsContext {
        if let context = contexts[app.id] { return context }
        let context = try await pushing.context(for: app)
        contexts[app.id] = context
        return context
    }

    private func live(for app: StoreApp, context: ScreenshotsContext, screenshots: any ScreenshotsServices) async throws -> LiveScreenshots {
        if let live = liveSets[app.id] { return live }
        let live = try await screenshots.liveScreenshots(for: app, localizations: context.localizations)
        liveSets[app.id] = live
        return live
    }

    /// Replaces an app's plan after a local change (a discard, Undo).
    func setPlan(_ plan: ScreenshotPushPlan?, for appID: StoreApp.ID) {
        plans[appID] = plan.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Forgets what's live for `appID`, so the next plan reads it again.
    func invalidateLive(for appID: StoreApp.ID) {
        liveSets[appID] = nil
    }

    /// "English (U.S.)": what an app's locales without a set of their own
    /// show.
    func primaryLocaleName(for appID: StoreApp.ID) -> String {
        contexts[appID]?.primaryLocale.name ?? plans[appID]?.primaryLocaleName
            ?? apps[appID]?.primaryLocale.flatMap { StoreLocaleCatalog.locale(code: $0)?.name }
            ?? String(localized: "the primary locale")
    }

    /// Reads the account's apps once, for what Activity shows before
    /// Review & Push has opened.
    func loadAppsIfNeeded() async {
        guard apps.isEmpty, let workspace, let library = try? await workspace.apps() else { return }
        for app in library {
            apps[app.id] = app
        }
    }

    func bumpRevision(for appID: StoreApp.ID) {
        revisions[appID, default: 0] += 1
    }
}
