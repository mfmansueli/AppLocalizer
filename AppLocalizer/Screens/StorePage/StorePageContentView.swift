//
//  StorePageContentView.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// The loaded Store Page: the context bar, then the no-version page or the
/// action bar, banners and the chosen view, plus every sheet and file panel
/// the section opens.
struct StorePageContentView: View {
    @Bindable var viewModel: StorePageViewModel

    var body: some View {
        VStack(spacing: 0) {
            StorePageContextBar(viewModel: viewModel)
            content
        }
        .background(Palette.content)
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .translate: TranslateMissingSheet(viewModel: viewModel)
            case .findReplace: FindReplaceSheet(viewModel: viewModel)
            case .importPreview: ImportPreviewSheet(viewModel: viewModel)
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
        } else if viewModel.mode == .screenshots, let screenshots = viewModel.screenshots {
            ScreenshotsView(viewModel: screenshots)
        } else if viewModel.showsNoVersionPage {
            NoVersionView(viewModel: viewModel)
        } else {
            if viewModel.isVersionEditable {
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
            case .screenshots: viewModel.screenshots.map { ScreenshotsView(viewModel: $0) }
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
