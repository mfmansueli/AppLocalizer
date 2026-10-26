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
/// - `apps`, `apps-empty`, `apps-error`: the main window with canned apps,
///   none, or a failed load.
struct DebugSceneView: View {
    let id: String
    @State private var isConnected = false

    var body: some View {
        switch id {
        case "connect", "connect-key":
            if isConnected {
                MainView(viewModel: AppListViewModel(services: DebugAppListServices()))
            } else {
                ConnectView(viewModel: ConnectViewModel(
                    services: DebugConnectServices(),
                    privateKey: id == "connect-key" ? DebugFixtures.privateKey : nil
                ) { _ in isConnected = true })
            }
        case "connect-rejected":
            ConnectView(viewModel: rejectedConnectModel)
        case "apps":
            MainView(viewModel: AppListViewModel(services: DebugAppListServices()))
        case "apps-empty":
            MainView(viewModel: AppListViewModel(services: DebugAppListServices(apps: [])))
        case "apps-error":
            MainView(viewModel: AppListViewModel(services: DebugAppListServices(error: .unauthorized)))
        default:
            ContentUnavailableView("Unknown debug scene", systemImage: "questionmark.square.dashed", description: Text(id))
        }
    }

    private var rejectedConnectModel: ConnectViewModel {
        let model = ConnectViewModel(services: DebugConnectServices(error: .unauthorized), privateKey: DebugFixtures.privateKey) { _ in }
        model.issuerID = DebugFixtures.issuerID
        return model
    }
}
#endif
