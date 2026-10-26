//
//  ConnectView.swift
//  AppLocalizer
//

import SwiftUI

/// First launch (and after removing the key): asks for the team API key —
/// Issuer ID, Key ID and the `.p8` private key — checks it with one request
/// to App Store Connect and hands it to `AppSession`, which saves it in the
/// Keychain.
struct ConnectView: View {
    @State private var viewModel: ConnectViewModel
    @State private var isImportingKey = false
    @State private var isShowingHelp = false
    /// Shown above the form, e.g. why the saved key couldn't be loaded.
    private let notice: String?

    init(notice: String? = nil, onConnect: @escaping (AppStoreConnectCredentials) throws -> Void) {
        self.init(viewModel: ConnectViewModel(services: LiveConnectServices(), onConnect: onConnect), notice: notice)
    }

    /// With an existing model — DEBUG scenes and previews.
    init(viewModel: ConnectViewModel, notice: String? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.notice = notice
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                if let notice {
                    InlineMessage.warning(notice)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                form
                connectBar
                Text("Your private key never leaves this Mac. It's kept in the login Keychain, and requests to Apple are signed with it locally.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 32)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity)
        }
        .fileImporter(isPresented: $isImportingKey, allowedContentTypes: [.appStoreConnectPrivateKey]) { result in
            switch result {
            case let .success(url): importKey(at: url)
            case let .failure(error): viewModel.importFailed(error)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "globe.badge.chevron.backward")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text("Connect to App Store Connect")
                .font(.largeTitle.bold())
            Text("AppLocalizer uses a team API key to read and update your subscription prices and App Store listings.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 18) {
            field("Issuer ID", issue: viewModel.issuerIDIssue, issueIdentifier: "connect.issuerIDIssue") {
                TextField("Issuer ID", text: $viewModel.issuerID, prompt: Text("57246542-96fe-1a63-e053-0824d011072a"))
                    .accessibilityIdentifier("connect.issuerIDField")
            }
            field("Key ID", issue: viewModel.keyIDIssue, issueIdentifier: "connect.keyIDIssue") {
                TextField("Key ID", text: $viewModel.keyID, prompt: Text("2X9R4HXF34"))
                    .accessibilityIdentifier("connect.keyIDField")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Private key")
                    .font(.headline)
                PrivateKeyDropZone(
                    key: viewModel.privateKey,
                    onChoose: { isImportingKey = true },
                    onRemove: { viewModel.removeKey() },
                    onDrop: importKey(at:)
                )
                if let message = viewModel.importErrorMessage {
                    InlineMessage.error(message)
                        .accessibilityIdentifier("connect.importError")
                }
            }
            DisclosureGroup("Where do I find these?", isExpanded: $isShowingHelp) {
                ConnectHelpSteps()
            }
            .accessibilityIdentifier("connect.helpDisclosure")
        }
    }

    private var connectBar: some View {
        VStack(spacing: 12) {
            if let message = viewModel.errorMessage {
                InlineMessage.error(message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("connect.error")
            }
            Button {
                Task { await viewModel.connect() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isVerifying {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(viewModel.isVerifying ? "Checking key…" : "Connect")
                }
                .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(!viewModel.canConnect)
            .accessibilityIdentifier("connect.connectButton")
        }
    }

    private func field(
        _ title: LocalizedStringKey,
        issue: CredentialsIssue?,
        issueIdentifier: String,
        @ViewBuilder input: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            input()
                .textFieldStyle(.roundedBorder)
                .font(.body.monospaced())
                .autocorrectionDisabled()
            if let issue {
                InlineMessage.warning(issue.message)
                    .accessibilityIdentifier(issueIdentifier)
            }
        }
    }

    private func importKey(at url: URL) {
        do {
            try viewModel.importKey(PrivateKeyFileReader.read(url))
        } catch {
            viewModel.importFailed(error)
        }
    }
}

#Preview {
    ConnectView { _ in }
        .frame(width: 900, height: 760)
}
