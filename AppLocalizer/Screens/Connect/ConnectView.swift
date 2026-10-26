//
//  ConnectView.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// First launch (and after the last key is removed): asks for a team API
/// key (Issuer ID, Key ID and the `.p8` private key), checks it with App
/// Store Connect and hands it to `AppSession`, which saves it in the
/// Keychain. "Add Another Key…" shows the same form in a sheet, with Cancel.
struct ConnectView: View {
    @State private var viewModel: ConnectViewModel
    @State private var isImportingKey = false
    @State private var isShowingHelp: Bool
    @FocusState private var focusedField: ConnectViewModel.Field?
    /// Shown above the form, e.g. why the saved keys couldn't be loaded.
    private let notice: String?
    /// Set in the "Add Another Key…" sheet.
    private let onCancel: (() -> Void)?
    private let startsWithDropHover: Bool

    init(
        checker: any KeyChecker,
        notice: String? = nil,
        onCancel: (() -> Void)? = nil,
        onConnect: @escaping (AppStoreConnectCredentials, KeyAccessCheck) throws -> Void
    ) {
        self.init(viewModel: ConnectViewModel(checker: checker, onConnect: onConnect), notice: notice, onCancel: onCancel)
    }

    /// With an existing model, for DEBUG scenes and previews, optionally
    /// with help open or a file hovering over the drop zone.
    init(
        viewModel: ConnectViewModel,
        notice: String? = nil,
        onCancel: (() -> Void)? = nil,
        showsHelp: Bool = false,
        showsDropHover: Bool = false
    ) {
        _viewModel = State(initialValue: viewModel)
        _isShowingHelp = State(initialValue: showsHelp)
        self.notice = notice
        self.onCancel = onCancel
        startsWithDropHover = showsDropHover
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.medium) {
                ConnectHeader(title: isSheet ? "Add Another Key" : "Connect to App Store Connect")
                    .padding(.bottom, Spacing.tiny)
                if let notice {
                    InlineMessage.warning(notice)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                form
                help
                if let failure = viewModel.failure {
                    ConnectFailureBanner(failure: failure) { Task { await viewModel.connect() } }
                }
                footer
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, Spacing.xxxLarge)
            .padding(.vertical, isSheet ? Spacing.xxLarge : Spacing.xxxLarge)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: focusedField) { oldValue, _ in
            if let oldValue { viewModel.leave(oldValue) }
        }
        // After the edit, not inside it: the field only picks up a change
        // made in a later update.
        .onChange(of: viewModel.keyID) { viewModel.uppercaseKeyID() }
        .fileImporter(isPresented: $isImportingKey, allowedContentTypes: [.appStoreConnectPrivateKey, .data]) { result in
            switch result {
            case let .success(url): importKey(at: url)
            case let .failure(error): viewModel.importFailed(error)
            }
        }
    }

    private var isSheet: Bool { onCancel != nil }

    private var form: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                ConnectFormField(
                    title: "Issuer ID",
                    text: $viewModel.issuerID,
                    prompt: "69a6de70-0000-0000-0000-000000000000",
                    issue: viewModel.issuerIDIssue,
                    identifier: "connect.issuerIDField"
                )
                .focused($focusedField, equals: .issuerID)
                ConnectFormField(
                    title: "Key ID",
                    text: $viewModel.keyID,
                    prompt: "2X9R4HXF34",
                    width: 160,
                    issue: viewModel.keyIDIssue,
                    identifier: "connect.keyIDField"
                )
                .focused($focusedField, equals: .keyID)
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Private key")
                        .font(.subheadline.weight(.semibold))
                    PrivateKeyDropZone(
                        key: viewModel.privateKey,
                        rejectedFileName: viewModel.rejectedFileName,
                        isTargeted: startsWithDropHover,
                        onChoose: { isImportingKey = true },
                        onRemove: { viewModel.removeKey() },
                        onDrop: importKey(at:)
                    )
                    if let message = viewModel.importErrorMessage {
                        InlineMessage.error(message)
                            .accessibilityIdentifier("connect.importError")
                    }
                }
            }
        }
    }

    /// "Where do I find these?": the whole row toggles the steps, not only
    /// the chevron.
    private var help: some View {
        Card(padding: Spacing.medium) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { isShowingHelp.toggle() }
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                        .rotationEffect(.degrees(isShowingHelp ? 90 : 0))
                        .accessibilityHidden(true)
                    Text("Where do I find these?")
                        .font(.callout.weight(.semibold))
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(Text(isShowingHelp ? "Expanded" : "Collapsed"))
            .accessibilityIdentifier("connect.helpDisclosure")
            if isShowingHelp {
                ConnectHelpSteps()
                    .padding(.leading, Spacing.xLarge)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.large) {
            ConnectTrustNote()
            Spacer(minLength: Spacing.small)
            if let onCancel {
                Button("Cancel", action: onCancel)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("connect.cancelButton")
            }
            Button {
                Task { await viewModel.connect() }
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    if viewModel.isVerifying {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(viewModel.isVerifying ? "Checking…" : "Connect")
                }
                .frame(minWidth: 84)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(!viewModel.canConnect)
            .accessibilityIdentifier("connect.connectButton")
        }
        .padding(.horizontal, Spacing.xSmall)
    }

    private func importKey(at url: URL) {
        do {
            try viewModel.importKey(PrivateKeyFileReader.read(url))
        } catch CocoaError.fileReadInapplicableStringEncoding {
            // Not text at all, so certainly not a PEM key.
            viewModel.importKey(ImportedPrivateKey(fileName: url.lastPathComponent, pem: ""))
        } catch {
            viewModel.importFailed(error)
        }
    }
}

#Preview {
    ConnectView(checker: LiveKeyChecker()) { _, _ in }
        .frame(width: 900, height: 760)
}
