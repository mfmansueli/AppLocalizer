//
//  AppInformationSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The App Information section of an app's workspace (⌘5): one view model
/// per app, kept by the window while other sections show and reloaded by
/// the toolbar's Refresh.
struct AppInformationSectionView: View {
    let app: StoreApp
    let services: any AppInformationServices

    @Environment(ChangeQueue.self) private var queue
    @Environment(AppSummaryStore.self) private var summaries
    @Environment(PushController.self) private var push
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(FieldSuggestionStore.self) private var suggestions
    @State private var viewModel: AppInformationViewModel?
    /// The window's kept models; nil in previews without the main window.
    @Environment(WorkspaceSectionModels.self) private var sectionModels: WorkspaceSectionModels?

    var body: some View {
        Group {
            if let viewModel, viewModel.app.id == app.id {
                AppInformationContentView(viewModel: viewModel)
            } else {
                AppInformationPageSkeleton()
                    .padding(Spacing.xxLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.appInformation")
        .task(id: app.id) { await open() }
        .onChange(of: navigator.refreshCount) {
            Task {
                if let viewModel { await load(viewModel) }
            }
        }
        .onChange(of: navigator.intent) { handleIntent() }
    }

    /// Opens the page another part of the window asked for.
    private func handleIntent() {
        guard let viewModel, let intent = navigator.intent else { return }
        if viewModel.handle(intent) { navigator.consume(intent) }
    }

    private func open() async {
        let kept = sectionModels?.models(for: app.id)
        if let model = kept?.appInformation, model.isLoaded {
            viewModel = model
            handleIntent()
            if kept?.needsLoad(.appInformation, refreshCount: navigator.refreshCount) == true { await load(model) }
            return
        }
        let model = AppInformationViewModel(
            app: app,
            services: services,
            queue: queue,
            suggestions: suggestions,
            summaries: summaries,
            push: push
        )
        kept?.appInformation = model
        viewModel = model
        handleIntent()
        await load(model)
        #if DEBUG
        if let opening = (services as? DebugAppInformationServices)?.opening {
            await opening.run(on: model)
        }
        #endif
    }

    /// Reads the pages and notes when, so the kept model isn't read again
    /// until Refresh, a push or its age asks for it.
    private func load(_ model: AppInformationViewModel) async {
        let refreshCount = navigator.refreshCount
        await model.load()
        guard !Task.isCancelled, model.isLoaded, model.errorMessage == nil else { return }
        sectionModels?.models(for: app.id).didLoad(.appInformation, refreshCount: refreshCount)
    }
}
