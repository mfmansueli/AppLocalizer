//
//  RootView.swift
//  AppLocalizer
//

import SwiftUI

/// The main window's content: the connect screen until an API key is saved,
/// the app library of the key in use after, and the "Add Another Key…"
/// sheet. A DEBUG launch with `-AppLocalizerDebugScene <id>` shows a canned
/// scene instead (`DebugScene`).
struct RootView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.keyChecker) private var keyChecker

    var body: some View {
        @Bindable var session = session
        Group {
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
        .sheet(isPresented: $session.isAddingKey) {
            AddKeySheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let credentials = session.credentials {
            MainView(
                credentials: credentials,
                accounts: session.accounts,
                isFirstSync: session.firstSyncKeyID == credentials.keyID,
                onSelectAccount: { session.select(keyID: $0.keyID) },
                onAddKey: { session.isAddingKey = true },
                onFirstSyncFinished: session.finishFirstSync
            )
            // A different key is a different account: start over.
            .id(credentials)
        } else {
            ConnectView(checker: keyChecker, notice: session.loadErrorMessage) { try session.connect($0, check: $1) }
                .navigationTitle("AppLocalizer")
                .navigationSubtitle("Not connected")
        }
    }
}
