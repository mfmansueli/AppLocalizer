//
//  ScreenshotPushController+Restore.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotPushController {
    /// The backup a screenshot push kept, if this Mac still has it.
    func backup(for record: PushRecord) -> ScreenshotBackup? {
        guard let id = record.screenshots?.backupID, let pushing = workspace?.pushing else { return nil }
        return pushing.backups.backup(id: id, appID: record.appID)
    }

    /// Queues `locale`'s kept screenshots for review and pins the locale,
    /// so it's left out of re-rendering until Use Template Again and the
    /// next push doesn't replace them again. Returns whether it queued.
    @discardableResult
    func queueRestore(locale: StoreLocale, from backup: ScreenshotBackup, appID: StoreApp.ID) async -> Bool {
        guard let workspace, let pushing = workspace.pushing else { return false }
        let images = backup.images(locale: locale.code)
        guard !images.isEmpty else { return false }
        if apps[appID] == nil, let library = try? await workspace.apps() {
            for app in library {
                apps[app.id] = app
            }
        }
        guard let app = apps[appID], let primary = contexts[appID]?.primaryLocale ?? StoreLocaleCatalog.locale(code: "en-US") else { return false }
        do {
            var document = try await workspace.screenshots.document(for: app, primaryLocale: primary)
            document.scope.pin(locale.code, at: now())
            try await workspace.screenshots.save(document, for: app)
        } catch {
            notice = String(localized: "Couldn’t queue the restore: \(error.localizedDescription)")
            return false
        }
        var state = pushing.state.state(appID: appID)
        state.queue(ScreenshotRestoreRequest(locale: locale.code, backupID: backup.id, backupDate: backup.date, images: images))
        try? pushing.state.save(state, appID: appID)
        bumpRevision(for: appID)
        let day = backup.date.formatted(.dateTime.month(.abbreviated).day())
        notice = images.count == 1
            ? String(localized: "1 screenshot from before \(day) is queued for \(locale.name). Review and push to put it back.")
            : String(localized: "\(images.count) screenshots from before \(day) are queued for \(locale.name). Review and push to put them back.")
        await loadPlan(for: app)
        return true
    }
}
