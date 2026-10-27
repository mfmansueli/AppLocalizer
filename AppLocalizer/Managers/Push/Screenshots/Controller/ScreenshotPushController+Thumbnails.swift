//
//  ScreenshotPushController+Thumbnails.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ScreenshotPushController {
    /// The new image's thumbnail: the render, or the kept file.
    func newImage(for item: ScreenshotPlanItem) -> CGImage? {
        switch item.content {
        case let .render(job): renderQueue(appID: item.appID, displayType: item.cell.displayType)?.images[job.key]
        case let .restore(image): backupThumbnails[image.id]
        }
    }

    /// The live screenshot's thumbnail, once loaded.
    func oldImage(for item: ScreenshotPlanItem) -> CGImage? {
        guard let old = item.old else { return nil }
        return renderQueue(appID: item.appID, displayType: item.cell.displayType)?.liveImages[old.id]
    }

    func isRendering(_ item: ScreenshotPlanItem) -> Bool {
        guard item.content.renderJob != nil else { return backupThumbnails[item.content.backupImage?.id ?? ""] == nil }
        return renderQueue(appID: item.appID, displayType: item.cell.displayType)?.isRendering ?? false
    }

    func renderQueue(appID: StoreApp.ID, displayType: ScreenshotDisplayType) -> ScreenshotRenderQueue? {
        renderQueues["\(appID)|\(displayType.rawValue)"]
    }

    /// Renders the plan's thumbnails and loads the live ones they replace.
    func prepareThumbnails(for plan: ScreenshotPushPlan, app: StoreApp) {
        guard let screenshots = workspace?.screenshots else { return }
        let items = plan.items + plan.kept
        for display in ScreenshotDisplayType.rendered {
            let shown = items.filter { $0.cell.displayType == display }
            guard !shown.isEmpty else { continue }
            let key = "\(app.id)|\(display.rawValue)"
            let queue = renderQueues[key] ?? ScreenshotRenderQueue(
                cache: ScreenshotRenderCache(directory: screenshots.renderCacheDirectory),
                captureImage: { capture, width in await screenshots.captureImage(capture, for: app, pixelWidth: width) },
                liveImage: { shot, width in await screenshots.liveImage(shot, pixelWidth: width) }
            )
            renderQueues[key] = queue
            let width = ThumbnailSize.renderPixelWidth(for: display)
            queue.render(shown.compactMap(\.content.renderJob), pixelWidth: width)
            queue.loadLive(shown.compactMap(\.old), pixelWidth: width)
        }
        loadBackupThumbnails(items.compactMap(\.content.backupImage), appID: app.id)
    }

    /// Decodes kept screenshots small, off the main actor.
    func loadBackupThumbnails(_ images: [ScreenshotBackupImage], appID: StoreApp.ID) {
        guard let pushing = workspace?.pushing else { return }
        for image in images where backupThumbnails[image.id] == nil {
            guard let data = try? pushing.backups.data(for: image, appID: appID) else { continue }
            let size = ThumbnailSize.renderPixelWidth(for: image.displayType) * 3
            Task { [weak self] in
                let thumbnail = await Task.detached(priority: .userInitiated) { ScreenshotThumbnailer.thumbnail(data, maxPixelSize: size) }.value
                self?.backupThumbnails[image.id] = thumbnail
            }
        }
    }
}
