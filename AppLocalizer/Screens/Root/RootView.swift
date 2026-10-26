//
//  RootView.swift
//  AppLocalizer
//

import SwiftUI

/// The main window's content: the connect screen until an API key is saved,
/// the app library after. A DEBUG launch with `-AppLocalizerDebugScene <id>`
/// shows a canned scene instead (`DebugScene`).
struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        #if DEBUG
        if let id = DebugScene.requestedID {
            DebugSceneView(id: id)
        } else {
            content
        }
        #else
        content
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if let credentials = session.credentials {
            MainView(credentials: credentials, accounts: session.accounts)
                // A different key is a different account: start over.
                .id(credentials)
        } else {
            ConnectView(notice: session.loadErrorMessage) { try session.connect($0) }
        }
    }
}
