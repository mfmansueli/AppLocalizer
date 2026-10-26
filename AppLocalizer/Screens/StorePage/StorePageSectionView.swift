//
//  StorePageSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The Store Page section of an app's workspace (⌘3). It makes the
/// `StorePageViewModel` from the environment's queue, summaries and push
/// controller, once per app, and keeps it in step with the workspace:
/// Refresh reloads, intents from menus and the overview are handled, and a
/// queue changed elsewhere (Review & Push) is laid back onto the listing.
struct StorePageSectionView: View {
    let app: StoreApp
    let services: any StorePageServices

    @Environment(ChangeQueue.self) private var queue
    @Environment(AppSummaryStore.self) private var summaries
    @Environment(PushController.self) private var push
    @Environment(WorkspaceNavigator.self) private var navigator
    @State private var viewModel: StorePageViewModel?

    var body: some View {
        Group {
            if let viewModel, viewModel.app.id == app.id {
                StorePageContentView(viewModel: viewModel)
            } else {
                StorePageSkeleton()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.storePage")
        .task(id: app.id) { await open() }
        .onChange(of: navigator.refreshCount) {
            Task { await viewModel?.load() }
        }
        .onChange(of: navigator.intent) { handleIntent() }
        .onChange(of: queue.changes) { viewModel?.queueDidChange() }
    }

    private func open() async {
        let model = StorePageViewModel(app: app, services: services, queue: queue, summaries: summaries, push: push)
        viewModel = model
        handleIntent()
        await model.load()
        #if DEBUG
        if let opening = (services as? DebugStorePageServices)?.opening {
            await opening.run(on: model)
        }
        #endif
    }

    /// Takes the Store Page's intents (Translate Missing…, Find and
    /// Replace, Import, Find); the view model runs them once loaded.
    private func handleIntent() {
        guard let intent = navigator.intent, StorePageViewModel.handles(intent), let viewModel else { return }
        viewModel.handle(intent)
        navigator.consume(intent)
    }
}
