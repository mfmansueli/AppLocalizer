//
//  ConnectDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Connect DEBUG scenes (`-AppLocalizerDebugScene <id>`), as the design's
/// "Connect" board shows them:
///
/// - `connect`: the empty form; any well-formed key connects, then the first
///   sync runs and the library opens.
/// - `connect-key`: the same with a `.p8` already imported (a UI test can't
///   drive the file panel).
/// - `connect-hover`: a file hovering over the drop zone.
/// - `connect-hints`: malformed IDs and a file that isn't a key.
/// - `connect-help`: key imported, "Where do I find these?" open.
/// - `connect-checking`: the check never answers.
/// - `connect-401` (also `connect-rejected`), `connect-403`, `connect-offline`:
///   the check fails that way after Connect.
/// - `sync`: "Loading your apps…" halfway through.
enum ConnectDebugScenes {
    static let ids = [
        "connect", "connect-key", "connect-hover", "connect-hints", "connect-help", "connect-checking",
        "connect-401", "connect-rejected", "connect-403", "connect-offline", "sync",
    ]

    /// The key check every scene uses, in the main window and Settings.
    static func keyChecker(for id: String) -> any KeyChecker {
        switch id {
        case "connect-401", "connect-rejected": DebugKeyChecker(error: AppStoreConnectError.unauthorized)
        case "connect-403": DebugKeyChecker(error: AppStoreConnectError.forbidden(detail: nil))
        case "connect-offline": DebugKeyChecker(error: URLError(.notConnectedToInternet))
        case "connect-checking": DebugKeyChecker(delay: .seconds(3600))
        default: DebugKeyChecker()
        }
    }

    @MainActor
    static func view(for id: String) -> AnyView? {
        guard ids.contains(id) else { return nil }
        if id == "sync" {
            return AnyView(FirstSyncView(progress: FirstSyncProgress(appCount: DebugFixtures.apps.count, syncedCount: 2)))
        }
        return AnyView(Scene(id: id))
    }

    /// One connect scene: the form in its state, and the library (after the
    /// first sync) once a key connects.
    private struct Scene: View {
        let id: String
        @State private var connection: Connection
        @State private var model: ConnectViewModel

        init(id: String) {
            self.id = id
            let connection = Connection()
            _connection = State(initialValue: connection)
            _model = State(initialValue: ConnectDebugScenes.model(for: id) { _, _ in connection.isConnected = true })
        }

        var body: some View {
            if connection.isConnected {
                DebugMainScene(isFirstSync: true)
            } else {
                ConnectView(viewModel: model, showsHelp: id == "connect-help", showsDropHover: id == "connect-hover")
                    .navigationTitle("AppLocalizer")
                    .navigationSubtitle("Not connected")
                    .task {
                        if Self.connectsOnLaunch.contains(id) { await model.connect() }
                    }
            }
        }

        private static let connectsOnLaunch: Set = ["connect-checking", "connect-401", "connect-403", "connect-offline"]
    }

    /// Whether a scene's key connected; a class, so the model's `onConnect`
    /// can flip it.
    @MainActor
    @Observable
    final class Connection {
        var isConnected = false
    }

    @MainActor
    private static func model(
        for id: String,
        onConnect: @escaping (AppStoreConnectCredentials, KeyAccessCheck) throws -> Void
    ) -> ConnectViewModel {
        let model = ConnectViewModel(checker: keyChecker(for: id), onConnect: onConnect)
        switch id {
        case "connect":
            break
        case "connect-key":
            model.importKey(DebugFixtures.privateKey)
        case "connect-hover":
            model.issuerID = DebugFixtures.issuerID
            model.keyID = DebugFixtures.keyID
        case "connect-hints":
            model.issuerID = "69a6de7f-3c2e-47e3"
            model.keyID = "2X9R4H"
            model.leave(.issuerID)
            model.leave(.keyID)
            model.importKey(ImportedPrivateKey(fileName: "notes.txt", pem: "Remember to rotate the keys."))
        default:
            model.issuerID = DebugFixtures.issuerID
            model.importKey(DebugFixtures.privateKey)
        }
        return model
    }
}
#endif
