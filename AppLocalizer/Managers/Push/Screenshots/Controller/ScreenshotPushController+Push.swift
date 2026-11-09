//
//  ScreenshotPushController+Push.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ScreenshotPushController {
    var isRunning: Bool { run?.isRunning ?? false }

    /// Starts pushing the images of `plans`; `selection` limits it to
    /// those, nil sends them all. Blocked plans (no version being
    /// prepared) are skipped.
    func push(_ plans: [ScreenshotPushPlan], selection: Set<ScreenshotPlanItem.ID>? = nil) {
        guard !isRunning, let pushing = workspace?.pushing else { return }
        let environment = ScreenshotPushEnvironment(
            transport: pushing.uploads,
            backups: pushing.backups,
            imageData: { [weak self] item in
                guard let self else { throw ScreenshotPushFailure.image }
                return try await imageData(for: item)
            },
            liveData: { try await pushing.liveImageData($0) },
            rate: rate,
            now: now,
            sleep: sleep
        )
        let run = ScreenshotPushRun(plans: plans, selection: selection, environment: environment)
        guard !run.items.isEmpty else { return }
        run.onFinish = { [weak self] run in await self?.record(run) }
        self.run = run
        run.start()
    }

    func cancelRemaining() {
        run?.cancelRemaining()
    }

    func retryFailed() {
        run?.retryFailed()
    }

    /// Clears a finished push so the sheet shows the review list again.
    func dismissFinished() {
        guard let run, run.phase == .finished else { return }
        self.run = nil
    }

    /// The PNG an image uploads: the render at full size, or the kept file.
    func imageData(for item: ScreenshotPlanItem) async throws -> Data {
        guard let workspace, let pushing = workspace.pushing, let app = apps[item.appID] else { throw ScreenshotPushFailure.image }
        switch item.content {
        case let .render(job):
            var capture: CGImage?
            var companion: CGImage?
            if let file = job.capture {
                capture = await workspace.screenshots.captureImage(file, for: app, pixelWidth: job.layout.canvas.pixelSize.width)
            }
            if let file = job.companion {
                companion = await workspace.screenshots.captureImage(file, for: app, pixelWidth: job.layout.canvas.pixelSize.width)
            }
            guard let data = ScreenshotImageRenderer.pngData(layout: job.layout, capture: capture, companion: companion)
            else { throw ScreenshotPushFailure.image }
            return data
        case let .restore(image):
            return try pushing.backups.data(for: image, appID: item.appID)
        }
    }

    // MARK: - Recording

    /// After each round: what went live goes into the app's document, done
    /// restores and discards are cleared, and Activity gets a record per app.
    func record(_ run: ScreenshotPushRun) async {
        let round = run.items.filter { run.roundItemIDs.contains($0.id) }
        var changed: Set<StoreApp.ID> = []
        for appID in run.appIDs {
            let items = round.filter { $0.appID == appID && ($0.status == .done || $0.status.isFailure) }
            guard !items.isEmpty else { continue }
            let done = items.filter { $0.status == .done }
            if !done.isEmpty {
                await savePushed(done, appID: appID)
                changed.insert(appID)
            }
            history.add(PushRecord(
                date: now(),
                appID: appID,
                appName: run.plans.first { $0.appID == appID }?.appName ?? appName(appID),
                title: summary(of: items, backupID: run.backupID).title,
                pushed: [],
                screenshots: summary(of: items, backupID: run.backupID)
            ))
        }
        guard !changed.isEmpty else { return }
        onPushed(changed)
        for appID in changed {
            if let app = apps[appID] { await loadPlan(for: app) }
        }
    }

    /// Records the renders that went live, and clears restores and
    /// discards they settled.
    private func savePushed(_ done: [ScreenshotUploadItem], appID: StoreApp.ID) async {
        guard let workspace, let pushing = workspace.pushing, let app = apps[appID],
              let primary = contexts[appID]?.primaryLocale ?? StoreLocaleCatalog.locale(code: "en-US") else { return }
        let date = now()
        do {
            var document = try await workspace.screenshots.document(for: app, primaryLocale: primary)
            for item in done {
                guard let key = item.plan.renderKey, let checksum = item.checksum else { continue }
                document.pushed.removeAll { $0.cell == item.plan.cell }
                document.pushed.append(PushedRender(cell: item.plan.cell, renderKey: key, checksum: checksum, date: date))
            }
            try await workspace.screenshots.saveDocument(document, for: app)
        } catch {
            notice = String(localized: "The push went through, but this Mac couldn’t note it: \(error.localizedDescription)")
        }
        var state = pushing.state.state(appID: appID)
        for item in done {
            state.kept[item.plan.cell] = nil
            guard let image = item.plan.content.backupImage,
                  let index = state.restores.firstIndex(where: { $0.locale == image.locale && $0.backupID == image.backupID }) else { continue }
            state.restores[index].images.removeAll { $0.id == image.id }
            let left = state.restores[index].images.filter { !state.keptRestores.contains($0.id) }
            if left.isEmpty { state.removeRestore(for: image.locale) }
        }
        try? pushing.state.save(state, appID: appID)
        invalidateLive(for: appID)
        bumpRevision(for: appID)
    }

    private func summary(of items: [ScreenshotUploadItem], backupID: String) -> ScreenshotPushSummary {
        let done = items.filter { $0.status == .done }
        // A full set's old screenshot can be gone even when its new one failed.
        let kept = items.filter { $0.backup != nil && ($0.status == .done || $0.isOldDeleted) }
        return ScreenshotPushSummary(
            pushedCount: done.count,
            failures: items.compactMap { item in item.status.failureText.map { "\(item.title): \($0)" } },
            locales: Self.unique(items.map(\.plan.cell.locale)),
            keptLocales: Self.unique(kept.map(\.plan.cell.locale)),
            backupID: kept.isEmpty ? nil : backupID,
            isRestore: items.allSatisfy(\.plan.isRestore)
        )
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0).inserted }
    }
}
