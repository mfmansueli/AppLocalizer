//
//  DebugSceneView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Renders a `DebugScene` id with canned services:
///
/// - `connect`: empty connect form; any well-formed key connects, then shows
///   the `apps` scene.
/// - `connect-key`: the same, with a `.p8` already imported (the file panel
///   can't be driven from a UI test).
/// - `connect-rejected`: key imported and fields filled; Apple answers 401.
/// - `apps`, `apps-empty`, `apps-error`, `lib-loading`: the main window with
///   the sample apps (Lumen Journal selected), none, a failed load, or the
///   first sync still running.
/// - `overview`, `overview-keep`: Lumen Journal's overview, or Tempo
///   Metronome's with Keep my prices.
///
/// Ids it doesn't know go to each section's own list (`PricingDebugScenes`,
/// `StorePageDebugScenes`, `AppInformationDebugScenes`).
struct DebugSceneView: View {
    let id: String
    @State private var isConnected = false

    var body: some View {
        switch id {
        case "connect", "connect-key":
            if isConnected {
                DebugMainScene()
            } else {
                ConnectView(viewModel: ConnectViewModel(
                    services: DebugConnectServices(),
                    privateKey: id == "connect-key" ? DebugFixtures.privateKey : nil
                ) { _ in isConnected = true })
            }
        case "connect-rejected":
            ConnectView(viewModel: rejectedConnectModel)
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
            if let scene = PricingDebugScenes.view(for: id)
                ?? StorePageDebugScenes.view(for: id)
                ?? AppInformationDebugScenes.view(for: id)
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

    private var rejectedConnectModel: ConnectViewModel {
        let model = ConnectViewModel(services: DebugConnectServices(error: .unauthorized), privateKey: DebugFixtures.privateKey) { _ in }
        model.issuerID = DebugFixtures.issuerID
        return model
    }
}
#endif
