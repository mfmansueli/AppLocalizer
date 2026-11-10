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
/// - `apps-unnamed`: the sample apps under a key the person hasn't named;
///   App Store Connect calls its team Northpier Studio.
/// - `overview`, `overview-keep`: Lumen Journal's overview, or Tempo
///   Metronome's with Keep my prices.
///
/// Ids it doesn't know go to each area's own list (`ConnectDebugScenes`,
/// `SettingsDebugScenes`, `ReviewPushDebugScenes`, `PricingDebugScenes`, `RetentionDebugScenes`,
/// `StorePageDebugScenes`, `AppInformationDebugScenes`,
/// `ScreenshotsDebugScenes`, `ScreenshotsPushDebugScenes`, `ExtrasPushDebugScenes`,
/// `ScreenshotsProposalsDebugScenes`, `AssistantDebugScenes`,
/// `SuggestionsDebugScenes`, `AssistDebugScenes`, `EverythingDebugScenes`,
/// `NewLanguagesDebugScenes`, `StudioDebugScenes`, `ClaudeCodeDebugScenes`).
struct DebugSceneView: View {
    let id: String

    var body: some View {
        switch id {
        case "apps", "overview":
            DebugMainScene()
        case "apps-badges":
            DebugMainScene(suggestions: SuggestionsDebugData.store())
        case "overview-keep":
            DebugMainScene(selectedAppID: DebugFixtures.AppID.tempo)
        case "apps-empty":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(apps: []) }, selectedAppID: nil)
        case "apps-error":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(error: .unauthorized) }, selectedAppID: nil)
        case "lib-loading":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(delay: .seconds(3600)) })
        case "apps-unnamed":
            DebugMainScene(services: services { $0.appList = DebugAppListServices(teamName: DebugFixtures.northpier.name) }, unnamedKey: true)
        default:
            if let scene = Self.scene(for: id) {
                scene
            } else {
                ContentUnavailableView("Unknown debug scene", systemImage: "questionmark.square.dashed", description: Text(id))
            }
        }
    }

    /// The first area's scene with this id.
    private static func scene(for id: String) -> AnyView? {
        let areas: [@MainActor (String) -> AnyView?] = [
            ConnectDebugScenes.view(for:),
            SettingsDebugScenes.view(for:),
            ReviewPushDebugScenes.view(for:),
            PricingDebugScenes.view(for:),
            RetentionDebugScenes.view(for:),
            StorePageDebugScenes.view(for:),
            AppInformationDebugScenes.view(for:),
            ScreenshotsDebugScenes.view(for:),
            ScreenshotsPushDebugScenes.view(for:),
            ExtrasPushDebugScenes.view(for:),
            ScreenshotsProposalsDebugScenes.view(for:),
            AssistantDebugScenes.view(for:),
            SuggestionsDebugScenes.view(for:),
            AssistDebugScenes.view(for:),
            EverythingDebugScenes.view(for:),
            NewLanguagesDebugScenes.view(for:),
            StudioDebugScenes.view(for:),
            ClaudeCodeDebugScenes.view(for:),
        ]
        return areas.lazy.compactMap { $0(id) }.first
    }

    private func services(_ change: (inout WorkspaceServices) -> Void) -> WorkspaceServices {
        var services = WorkspaceServices.debug
        change(&services)
        return services
    }
}
#endif
