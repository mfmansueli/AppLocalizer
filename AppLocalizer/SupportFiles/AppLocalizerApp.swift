//
//  AppLocalizerApp.swift
//  AppLocalizer
//

import SwiftUI

@main
struct AppLocalizerApp: App {
    @State private var session = AppSession(store: Self.credentialsStore)

    var body: some Scene {
        // One window: every app is a sidebar row, so a second window would
        // only duplicate the library and its requests.
        Window("AppLocalizer", id: "main") {
            RootView()
                .environment(session)
                .frame(minWidth: 860, minHeight: 560)
        }
        .defaultSize(width: 1200, height: 780)

        Settings {
            SettingsView()
                .environment(session)
        }
    }

    /// DEBUG scenes (and so UI tests) keep the key in memory, so they never
    /// read or overwrite the real one in the Keychain.
    private static var credentialsStore: any CredentialsStore {
        #if DEBUG
        if DebugScene.requestedID != nil { return DebugCredentialsStore() }
        #endif
        return KeychainCredentialsStore()
    }
}
