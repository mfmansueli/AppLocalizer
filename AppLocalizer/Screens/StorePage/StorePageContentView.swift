//
//  StorePageContentView.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// The loaded Store Page: the header, then the no-version page or banners
/// and the chosen view, plus every sheet and file panel the section opens
/// and the toast after accepting suggestions.
struct StorePageContentView: View {
    @Bindable var viewModel: StorePageViewModel

    @Environment(AppPreferences.self) private var preferences
    @Environment(WorkspaceNavigator.self) private var navigator

    var body: some View {
        VStack(spacing: 0) {
            StorePageHeader(viewModel: viewModel)
                .padding(.horizontal, 20)
                .padding(.top, Spacing.small)
                .padding(.bottom, 10)
            content
        }
        .background(Palette.content)
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                ActionToast(message: toast) {
                    viewModel.undoToast()
                } onAction: {
                    viewModel.toast = nil
                    navigator.isReviewPresented = true
                } onDismiss: {
                    if viewModel.toast == toast { viewModel.toast = nil }
                }
                .padding(.bottom, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.toast)
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .translate: TranslateMissingSheet(viewModel: viewModel)
            case .findReplace: FindReplaceSheet(viewModel: viewModel)
            case .importPreview: ImportPreviewSheet(viewModel: viewModel)
            case .newLanguages: NewLanguagesSheet(viewModel: viewModel)
            case .acceptAll: acceptAllSheet
            }
        }
        .fileImporter(isPresented: $viewModel.isImporterPresented, allowedContentTypes: ListingTransferFormat.importableContentTypes) { result in
            switch result {
            case let .success(url): viewModel.importFile(at: url)
            case let .failure(error): viewModel.notice = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: isExporting,
            document: viewModel.exportFormat.flatMap(viewModel.exportDocument(as:)),
            contentType: viewModel.exportFormat?.contentType ?? .commaSeparatedText,
            defaultFilename: viewModel.exportFormat.map(viewModel.exportFileName(as:))
        ) { result in
            viewModel.exportDidFinish(result)
        }
    }

    private var acceptAllSheet: some View {
        AcceptAllSheet(selection: viewModel.acceptAllSelection()) {
            viewModel.sheet = nil
        } onAccept: { ids, dontAskAgain in
            viewModel.sheet = nil
            if dontAskAgain { preferences.acceptsAllWithoutAsking = true }
            viewModel.acceptSuggestions(ids: ids, turnedOffAsking: dontAskAgain)
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isLoaded {
            if let message = viewModel.errorMessage {
                StorePageErrorView(message: message) {
                    Task { await viewModel.load() }
                }
            } else {
                StorePageSkeleton(showsContextBar: false)
            }
        } else if viewModel.showsNoVersionPage {
            NoVersionView(viewModel: viewModel)
        } else {
            if viewModel.isVersionEditable, viewModel.mode != .editor {
                StorePageActionBar(viewModel: viewModel)
            }
            banners
            modeContent
        }
    }

    @ViewBuilder
    private var banners: some View {
        if let message = viewModel.errorMessage {
            Banner(kind: .apiError, title: String(localized: "Couldn’t refresh the store page"), message: message) {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
            .accessibilityIdentifier("storePage.error")
        }
        if let notice = viewModel.notice {
            Banner(kind: .info, title: notice) {
                Button {
                    viewModel.notice = nil
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Dismiss"))
            }
            .accessibilityIdentifier("storePage.notice")
            .task(id: notice) {
                try? await Task.sleep(for: .seconds(6))
                if viewModel.notice == notice { viewModel.notice = nil }
            }
        }
        if viewModel.translation.phase == .running {
            TranslationProgressBanner(translation: viewModel.translation)
        }
    }

    @ViewBuilder
    private var modeContent: some View {
        if viewModel.translation.phase == .reviewing {
            TranslationSuggestionsView(viewModel: viewModel)
        } else {
            switch viewModel.mode {
            case .coverage: CoverageGridView(viewModel: viewModel)
            case .editor: LocaleEditorView(viewModel: viewModel)
            case .inAppTexts: InAppTextsView(viewModel: viewModel)
            }
        }
    }

    private var isExporting: Binding<Bool> {
        Binding {
            viewModel.exportFormat != nil
        } set: { isPresented in
            if !isPresented { viewModel.exportFormat = nil }
        }
    }
}
