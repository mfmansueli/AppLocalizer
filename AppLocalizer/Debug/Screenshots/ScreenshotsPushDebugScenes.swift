//
//  ScreenshotsPushDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Review & Push for screenshots' DEBUG scenes (`-AppLocalizerDebugScene
/// <id>`), named after the design's screenshots. Every scene is Lumen
/// Journal's store page on the Screenshots view, with a simulated App Store
/// Connect behind the push:
///
/// - `shots-review`: Review & Push with 40 images in 8 sets: Arabic,
///   Chinese (Simplified), Dutch and Spanish (Mexico) on iPhone and iPad.
/// - `shots-push`: the push running, 15 of 40 done, three images held at
///   uploading, committing and reserving.
/// - `shots-push-partial`: in dark mode, 38 of 40 pushed: one upload timed
///   out, one image Apple couldn't process. Retry Failed sends them again.
/// - `shots-act`: Activity with the Oct 12 screenshot push.
/// - `shots-act-restore`: Restore Previous Screenshots… on German.
enum ScreenshotsPushDebugScenes {
    static let ids = ["shots-review", "shots-push", "shots-push-partial", "shots-act", "shots-act-restore"]

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "shots-review":
            scene(sheet: .review)
        case "shots-push":
            scene(sheet: .review, script: holdingScript, autoPush: true)
        case "shots-push-partial":
            scene(sheet: .review, script: failingScript, autoPush: true, colorScheme: .dark)
        case "shots-act":
            scene(sheet: .activity)
        case "shots-act-restore":
            scene(sheet: .activity, restoreOnOpen: ScreenshotRestorePresentation(recordID: ScreenshotsPushDebugData.recordID, locale: "de-DE"))
        default:
            nil
        }
    }

    /// Three sets at a time: once Arabic, Chinese and Dutch on iPhone are
    /// done, the next three stop on their first image.
    private static var holdingScript: DebugScreenshotUploadScript {
        var script = DebugScreenshotUploadScript()
        script.holds = ["es-MX_iPhone_1_": .upload(afterParts: 2), "ar-SA_iPad_1_": .commit, "zh-Hans_iPad_1_": .reserve]
        return script
    }

    private static var failingScript: DebugScreenshotUploadScript {
        var script = DebugScreenshotUploadScript()
        script.delay = .milliseconds(10)
        script.usedThisHour = 380
        script.timeouts = ["zh-Hans_iPhone_1_"]
        script.processingFailures = ["es-MX_iPhone_2_"]
        return script
    }

    @MainActor
    private static func scene(
        sheet: WorkspaceSheet,
        script: DebugScreenshotUploadScript = DebugScreenshotUploadScript(),
        autoPush: Bool = false,
        restoreOnOpen: ScreenshotRestorePresentation? = nil,
        colorScheme: ColorScheme? = nil
    ) -> AnyView {
        let base = DebugScreenshotsServices()
        let push = DebugScreenshotPushServices(
            script: script, images: DebugScreenshotImages(fonts: base.fonts), autoPush: autoPush, restoreOnOpen: restoreOnOpen
        )
        var storePage = DebugStorePageServices()
        storePage.screenshots = DebugPushingScreenshotsServices(base: base, push: push)
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return AnyView(
            DebugMainScene(
                services: services, section: .screenshots, pendingChanges: [], pushRecords: ScreenshotsPushDebugData.records, presentedSheet: sheet
            )
            .preferredColorScheme(colorScheme)
        )
    }
}
#endif
