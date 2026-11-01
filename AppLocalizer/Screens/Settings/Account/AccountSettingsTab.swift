//
//  AccountSettingsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Account: every saved key with its role check, Test
/// Connection, Remove… and Add Another Key…. Right-click a key to use it
/// or rename it; the API doesn't share team names, so each key is named
/// here.
struct AccountSettingsTab: View {
    @State private var viewModel: AccountSettingsViewModel
    @State private var removing: AppStoreConnectCredentials?
    @State private var renaming: AppStoreConnectCredentials?
    @State private var draftName = ""
    @State private var isAddingKey = false

    init(viewModel: AccountSettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                if viewModel.keys.isEmpty {
                    Text("No keys yet. Connect one from the main window, or add one here.")
                        .foregroundStyle(Palette.label2)
                }
                ForEach(viewModel.keys, id: \.keyID) { credentials in
                    row(credentials)
                }
            } header: {
                Text("Saved keys")
            } footer: {
                footer
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(removalTitle, isPresented: isRemoving, presenting: removing) { credentials in
            Button("Remove Key", role: .destructive) { viewModel.remove(keyID: credentials.keyID) }
        } message: { _ in
            Text("Its apps leave the library; their pending changes stay until you push or discard them. The key itself stays valid in App Store Connect.")
        }
        .alert("Rename Key", isPresented: isRenaming, presenting: renaming) { credentials in
            TextField(viewModel.teamNameFromAppStoreConnect(for: credentials.keyID) ?? String(localized: "Team name"), text: $draftName)
            Button("Rename") { viewModel.rename(keyID: credentials.keyID, to: draftName) }
            Button("Cancel", role: .cancel) {}
        } message: { credentials in
            Text(renameMessage(for: credentials.keyID))
        }
        .sheet(isPresented: $isAddingKey) {
            AddKeySheet()
        }
    }

    private func row(_ credentials: AppStoreConnectCredentials) -> some View {
        let keyID = credentials.keyID
        return SavedKeyRow(
            credentials: credentials,
            account: viewModel.account(for: credentials),
            isInUse: viewModel.isInUse(keyID),
            isTesting: viewModel.isTesting(keyID),
            check: viewModel.check(for: keyID),
            failure: viewModel.failure(for: keyID),
            onTest: { Task { await viewModel.test(keyID: keyID) } },
            onRemove: { removing = credentials }
        )
        .contextMenu {
            Button("Use This Key") { viewModel.use(keyID: keyID) }
                .disabled(viewModel.isInUse(keyID))
            Button("Rename…") {
                draftName = credentials.teamName ?? ""
                renaming = credentials
            }
            Divider()
            Button("Remove…", role: .destructive) { removing = credentials }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Button {
                isAddingKey = true
            } label: {
                Label("Add Another Key…", systemImage: "plus")
            }
            .accessibilityIdentifier("settings.addKey")
            if let message = viewModel.errorMessage {
                InlineMessage.error(message)
            }
            footnote
                .font(.footnote)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footnote: Text {
        Text("Keys live in this Mac’s Keychain. Removing a key removes its apps from the library; their pending changes stay until you push or discard them.")
    }

    private func renameMessage(for keyID: String) -> String {
        guard let name = viewModel.teamNameFromAppStoreConnect(for: keyID) else {
            return String(localized: "App Store Connect didn’t give this team’s name, so give this key the name you know it by.")
        }
        return String(localized: "Leave it empty to use “\(name)”, the team’s name in App Store Connect.")
    }

    private var removalTitle: String {
        guard let removing else { return "" }
        return String(localized: "Remove \(viewModel.account(for: removing).name)’s key from this Mac?")
    }

    private var isRemoving: Binding<Bool> {
        Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }
}
