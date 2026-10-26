//
//  AccountSettingsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Account: which API key is connected, and removing it from the
/// Keychain (the main window goes back to the connect screen).
struct AccountSettingsTab: View {
    @Environment(AppSession.self) private var session
    @State private var isConfirmingRemoval = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            if let credentials = session.credentials {
                Section("App Store Connect API key") {
                    LabeledContent("Issuer ID") {
                        Text(credentials.issuerID)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                    }
                    LabeledContent("Key ID") {
                        Text(credentials.keyID)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                    }
                    LabeledContent("Private key", value: String(localized: "Stored in the login Keychain"))
                }
                Section {
                    Button("Remove API Key…", role: .destructive) { isConfirmingRemoval = true }
                        .accessibilityIdentifier("settings.removeKeyButton")
                    if let errorMessage {
                        InlineMessage.error(errorMessage)
                    }
                }
            } else {
                Text("No API key is connected. Connect one from the main window.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Remove the API key from this Mac?", isPresented: $isConfirmingRemoval) {
            Button("Remove", role: .destructive, action: removeKey)
        } message: {
            Text("You'll need the Issuer ID, Key ID and the .p8 file to connect again. The key itself stays valid in App Store Connect.")
        }
    }

    private func removeKey() {
        do {
            try session.disconnect()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
