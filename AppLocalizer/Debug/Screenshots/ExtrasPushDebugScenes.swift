//
//  ExtrasPushDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Review & Push for Autopilot's extras (`-AppLocalizerDebugScene <id>`),
/// with a simulated App Store Connect behind the push:
///
/// - `shots-review-extras`: Lumen's screenshots, then its header, search
///   image and App Previews in every language; German's header can't go
///   (“−50%”).
/// - `shots-review-extras-only`: the same extras for an app with no
///   screenshot set (a run that made only extras): nothing else waits.
/// - `shots-ppo`: “Test with Product Page Optimization…” on the header,
///   with the Outcome variant rendered and checked.
/// - `shots-ppo-export`: the same test where the treatment won't take the
///   artwork, so both variants are exported with the steps.
enum ExtrasPushDebugScenes {
    static let ids = ["shots-review-extras", "shots-review-extras-only", "shots-ppo", "shots-ppo-export"]

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "shots-review-extras":
            scene(script: DebugExtrasScript(), variant: false)
        case "shots-review-extras-only":
            scene(script: DebugExtrasScript(), variant: false, onlyExtras: true)
        case "shots-ppo":
            scene(script: DebugExtrasScript(opensTest: .header), variant: true)
        case "shots-ppo-export":
            scene(script: DebugExtrasScript(delay: .milliseconds(20), refusesTreatmentArtwork: true, opensTest: .header, createsTest: true), variant: true)
        default:
            nil
        }
    }

    @MainActor
    private static func scene(script: DebugExtrasScript, variant: Bool, onlyExtras: Bool = false) -> AnyView {
        let run = StudioDebugExtras.run(.ready)
        let center = AutopilotCenter()
        center.holdsStages = true
        center.now = { StudioDebugRuns.date(day: 31, month: 10, hour: 15, minute: 10) }
        center.install(run)
        let base = DebugScreenshotsServices()
        base.autopilot = center
        let extras = ExtrasPushDebugData.extras(for: run, variant: variant)
        if let extras { ExtrasPushDebugData.writeFiles(for: run, extras: extras, fonts: base.fonts) }
        base.documentChange = { document in
            document.extras = extras
            if onlyExtras { document.history = nil }
        }
        let push = DebugScreenshotPushServices(images: DebugScreenshotImages(fonts: base.fonts), extrasScript: script)
        var storePage = DebugStorePageServices()
        storePage.screenshots = DebugPushingScreenshotsServices(base: base, push: push)
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return AnyView(DebugMainScene(services: services, section: .screenshots, pendingChanges: [], presentedSheet: .review))
    }
}
#endif
