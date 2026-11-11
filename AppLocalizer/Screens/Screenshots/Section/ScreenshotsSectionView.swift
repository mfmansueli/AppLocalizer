//
//  ScreenshotsSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The Screenshots section of an app's workspace (⌘4): the App Store
/// preview with Autopilot above it, and the sets, template, captions and
/// captures one click away.
struct ScreenshotsSectionView: View {
    let app: StoreApp
    let services: any StorePageServices

    @Environment(PushController.self) private var push
    @Environment(WorkspaceNavigator.self) private var navigator
    @State private var model: ScreenshotsSectionModel?
    /// The window's kept models; nil in previews without the main window.
    @Environment(WorkspaceSectionModels.self) private var sectionModels: WorkspaceSectionModels?

    var body: some View {
        Group {
            if let model, model.app.id == app.id, let screenshots = model.screenshots {
                ScreenshotsView(viewModel: screenshots)
            } else if let message = model?.errorMessage, model?.app.id == app.id {
                ContentUnavailableView {
                    Label("Couldn’t load the screenshots", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task {
                            if let model { await load(model) }
                        }
                    }
                }
                .accessibilityIdentifier("screenshots.sectionError")
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.content)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.screenshots")
        .task(id: app.id) { await open() }
        .onChange(of: navigator.refreshCount) {
            Task {
                if let model { await load(model) }
            }
        }
        .onChange(of: navigator.intent) { handleIntent() }
    }

    private func open() async {
        let kept = sectionModels?.models(for: app.id)
        // The window keeps the model while other sections show: the sets,
        // renders and captures are there when the person comes back.
        if let model = kept?.screenshots, model.screenshots != nil {
            self.model = model
            handleIntent()
            if kept?.needsLoad(.screenshots, refreshCount: navigator.refreshCount) == true { await load(model) }
            return
        }
        let model = ScreenshotsSectionModel(app: app, services: services, push: push)
        kept?.screenshots = model
        self.model = model
        handleIntent()
        await load(model)
    }

    /// Reads the version and notes when, so the kept model isn't read
    /// again until Refresh, a push or its age asks for it.
    private func load(_ model: ScreenshotsSectionModel) async {
        let refreshCount = navigator.refreshCount
        await model.load()
        guard !Task.isCancelled, model.screenshots != nil, model.errorMessage == nil else { return }
        sectionModels?.models(for: app.id).didLoad(.screenshots, refreshCount: refreshCount)
    }

    /// Show Screenshots (Review & Push's Show in Captions): the section
    /// is already open; the push hooks open Captions on the render.
    private func handleIntent() {
        guard let intent = navigator.intent, intent == .showScreenshots,
              navigator.requestedAppID.map({ $0 == app.id }) ?? true else { return }
        navigator.consume(intent)
    }
}
