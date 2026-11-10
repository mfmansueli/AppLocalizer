//
//  ScreenshotsView.swift
//  AppLocalizer
//

import SwiftUI

/// The Screenshots section: the banner, then the language page (one
/// language's screenshots with their suggested captions, or All
/// Languages), the App Store preview with Autopilot (Preview), or the bar
/// and the chosen view — the Sets matrix, the template editor, the captions
/// table or the captures, or what comes before them (no captures, no
/// template) — plus the full-size viewer, the Locale Scope and Accept All
/// sheets and the captions' toast.
struct ScreenshotsView: View {
    @Bindable var viewModel: ScreenshotsViewModel
    /// Nil in previews and scenes without the main window.
    @Environment(WorkspaceNavigator.self) private var navigator: WorkspaceNavigator?
    @Environment(AppPreferences.self) private var preferences
    @State private var sidebarToken = UUID()

    var body: some View {
        VStack(spacing: 0) {
            banners
            if viewModel.showsLanguagePage, viewModel.isLoaded {
                ScreenshotsLanguagePage(viewModel: viewModel)
            } else {
                if viewModel.tab != .preview {
                    ScreenshotsBar(viewModel: viewModel)
                    Divider()
                } else if viewModel.isLoaded {
                    backBar
                }
                content
            }
        }
        .background(Palette.content)
        .overlay(alignment: .bottom) {
            if let toast = viewModel.captionToast {
                ActionToast(message: toast) {
                    Task { await viewModel.undoCaptionToast() }
                } onAction: {
                    viewModel.captionToast = nil
                    navigator?.isReviewPresented = true
                } onDismiss: {
                    if viewModel.captionToast == toast { viewModel.captionToast = nil }
                }
                .padding(.bottom, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.captionToast)
        .sheet(isPresented: $viewModel.isAcceptAllCaptionsPresented) {
            AcceptAllSheet(selection: viewModel.acceptAllCaptionsSelection()) {
                viewModel.isAcceptAllCaptionsPresented = false
            } onAccept: { ids, dontAsk in
                if dontAsk { preferences.acceptsAllWithoutAsking = true }
                Task { await viewModel.acceptCaptions(ids: ids, turnedOffAsking: dontAsk) }
            }
        }
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
        .onChange(of: viewModel.tab, initial: true) {
            navigator?.hideSidebar(viewModel.tab.hidesSidebar && !viewModel.showsLanguagePage, for: sidebarToken)
        }
        .onChange(of: viewModel.showsLanguagePage) {
            navigator?.hideSidebar(viewModel.tab.hidesSidebar && !viewModel.showsLanguagePage, for: sidebarToken)
        }
        .onDisappear { navigator?.hideSidebar(false, for: sidebarToken) }
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
            case .preview: ScreenshotStudioView(screenshots: viewModel)
            case .sets: prerequisites { SetsMatrixView(viewModel: viewModel) }
            case .template: prerequisites { TemplateEditorView(viewModel: viewModel) }
            case .captions: CaptionsView(viewModel: viewModel)
            case .captures: CapturesView(viewModel: viewModel)
            }
        }
    }

    /// Captures, then a template, before the matrix or the editor.
    @ViewBuilder
    private func prerequisites(@ViewBuilder _ content: () -> some View) -> some View {
        if !viewModel.hasCaptures {
            NoCapturesView(appName: viewModel.app.name) {
                viewModel.tab = .captures
                viewModel.captures.isImporterPresented = true
            } onUseLive: {
                viewModel.captures.useLiveScreenshots()
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

    /// Over the App Store preview: back to the language page.
    private var backBar: some View {
        HStack {
            backButton
            Spacer()
        }
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.small)
    }

    private var backButton: some View {
        Button {
            viewModel.showsLanguagePage = true
        } label: {
            Label("Screenshots", systemImage: "chevron.backward")
        }
        .buttonBorderShape(.capsule)
        .help("Each language's screenshots, with their suggested captions")
        .accessibilityIdentifier("screenshots.backToPage")
    }

    private var isScopePresented: Binding<Bool> {
        Binding {
            viewModel.scopeDraft != nil
        } set: { isPresented in
            if !isPresented { viewModel.scopeDraft = nil }
        }
    }
}
