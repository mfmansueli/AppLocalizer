//
//  ScreenshotsView.swift
//  AppLocalizer
//

import SwiftUI

/// Store Page → Screenshots: the banner, the bar, and the chosen view —
/// the Sets matrix, the template editor or the captions table, or what
/// comes before them (no captures, no template) — plus the full-size
/// viewer and the Locale Scope sheet.
struct ScreenshotsView: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        VStack(spacing: 0) {
            banners
            ScreenshotsBar(viewModel: viewModel)
            Divider()
            content
        }
        .background(Palette.content)
        .sheet(item: $viewModel.viewer) { target in
            ScreenshotViewerSheet(viewModel: viewModel, target: target)
        }
        .sheet(isPresented: isScopePresented) {
            LocaleScopeSheet(viewModel: viewModel)
        }
        .task {
            if !viewModel.isLoaded, !viewModel.isLoading { await viewModel.load() }
            #if DEBUG
            await (viewModel.services as? DebugScreenshotsServices)?.opening?.run(on: viewModel)
            #endif
        }
        .modifier(ScreenshotPushHooks(viewModel: viewModel))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.root")
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isLoaded {
            if let message = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t load the screenshots", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                }
                .accessibilityIdentifier("screenshots.loadError")
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            switch viewModel.tab {
            case .sets: prerequisites { SetsMatrixView(viewModel: viewModel) }
            case .template: prerequisites { TemplateEditorView(viewModel: viewModel) }
            case .captions: CaptionsView(viewModel: viewModel)
            case .captures:
                ScreenshotsTabPlaceholder(tab: viewModel.tab) { viewModel.tab = .sets }
            }
        }
    }

    /// Captures, then a template, before the matrix or the editor.
    @ViewBuilder
    private func prerequisites(@ViewBuilder _ content: () -> some View) -> some View {
        if !viewModel.hasCaptures {
            NoCapturesView(appName: viewModel.app.name) {
                viewModel.tab = .captures
            } onUseLive: {
                viewModel.tab = .captures
            }
        } else if !viewModel.hasTemplate {
            StarterPickerView(viewModel: viewModel)
        } else {
            content()
        }
    }

    @ViewBuilder
    private var banners: some View {
        switch viewModel.banner {
        case let .noVersion(title, message):
            Banner(kind: .warning, title: title, message: message, isInline: true) {
                Link(destination: NoVersionView.appStoreConnectURL(appID: viewModel.app.id)) {
                    Text("Open App Store Connect")
                }
                .buttonStyle(.bordered)
            }
            .accessibilityIdentifier("screenshots.banner.noVersion")
        case let .failedChecks(title, message, first):
            Banner(kind: .partialFailure, title: title, message: message, isInline: true) {
                Button("Show") { viewModel.openViewer(first) }
                    .accessibilityIdentifier("screenshots.banner.show")
            }
            .accessibilityIdentifier("screenshots.banner.failedChecks")
        case nil:
            EmptyView()
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
            .accessibilityIdentifier("screenshots.notice")
        }
        if viewModel.isLoaded, let message = viewModel.errorMessage {
            Banner(kind: .apiError, title: String(localized: "Couldn’t load the live screenshots"), message: message) {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
            .accessibilityIdentifier("screenshots.error")
        }
    }

    private var isScopePresented: Binding<Bool> {
        Binding {
            viewModel.scopeDraft != nil
        } set: { isPresented in
            if !isPresented { viewModel.scopeDraft = nil }
        }
    }
}
