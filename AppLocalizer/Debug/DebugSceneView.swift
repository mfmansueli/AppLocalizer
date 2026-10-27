//
//  DebugSceneView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Renders a `DebugScene` id with canned services:
///
/// - `apps`, `apps-empty`, `apps-error`, `lib-loading`: the main window with
///   the sample apps (Lumen Journal selected), none, a failed load, or the
///   first sync still running.
/// - `overview`, `overview-keep`: Lumen Journal's overview, or Tempo
///   Metronome's with Keep my prices.
///
/// Ids it doesn't know go to each area's own list (`ConnectDebugScenes`,
/// `SettingsDebugScenes`, `ReviewPushDebugScenes`, `PricingDebugScenes`,
/// `StorePageDebugScenes`, `AppInformationDebugScenes`,
/// `ScreenshotsDebugScenes`, `ScreenshotsPushDebugScenes`,
/// `AssistantDebugScenes`).
struct DebugSceneView: View {
    let id: String

    var body: some View {
        switch id {
        case "apps", "overview":
            DebugMainScene()
        case "overview-keep":
            DebugMainScene(selectedAppID: DebugFixtures.AppID.tempo)
        case "apps-empty":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(apps: []) }, selectedAppID: nil)
        case "apps-error":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(error: .unauthorized) }, selectedAppID: nil)
        case "lib-loading":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(delay: .seconds(3600)) })
        default:
            if let scene = ConnectDebugScenes.view(for: id)
                ?? SettingsDebugScenes.view(for: id)
                ?? ReviewPushDebugScenes.view(for: id)
                ?? PricingDebugScenes.view(for: id)
                ?? StorePageDebugScenes.view(for: id)
                ?? AppInformationDebugScenes.view(for: id)
                ?? ScreenshotsDebugScenes.view(for: id)
                ?? ScreenshotsPushDebugScenes.view(for: id)
                ?? AssistantDebugScenes.view(for: id)
            {
                scene
            } else {
                ContentUnavailableView("Unknown debug scene", systemImage: "questionmark.square.dashed", description: Text(id))
            }
        }
    }

    private func services(_ change: (inout WorkspaceServices) -> Void) -> WorkspaceServices {
        var services = WorkspaceServices.debug
        change(&services)
        return services
    }
}
#endif
