//
//  AppInformationSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The App Information section of an app's workspace (⌘4): one view model
/// per app, reloaded by the toolbar's Refresh.
struct AppInformationSectionView: View {
    let app: StoreApp
    let services: any AppInformationServices

    @Environment(ChangeQueue.self) private var queue
    @Environment(AppSummaryStore.self) private var summaries
    @Environment(PushController.self) private var push
    @Environment(WorkspaceNavigator.self) private var navigator
    @State private var viewModel: AppInformationViewModel?

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
            Task { await viewModel?.load() }
        }
    }

    private func open() async {
        let model = AppInformationViewModel(app: app, services: services, queue: queue, summaries: summaries, push: push)
        if let request = AppInformationPageRequest.shared.take() {
            model.page = request.page
            if let tab = request.tab { model.privacy.tab = tab }
        }
        viewModel = model
        await model.load()
        #if DEBUG
        if let opening = (services as? DebugAppInformationServices)?.opening {
            await opening.run(on: model)
        }
        #endif
    }
}
