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
                        Task { await model?.load() }
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
            Task { await model?.load() }
        }
        .onChange(of: navigator.intent) { handleIntent() }
    }

    private func open() async {
        let model = ScreenshotsSectionModel(app: app, services: services, push: push)
        self.model = model
        handleIntent()
        await model.load()
    }

    /// Show Screenshots (Review & Push's Show in Captions): the section
    /// is already open; the push hooks open Captions on the render.
    private func handleIntent() {
        guard let intent = navigator.intent, intent == .showScreenshots,
              navigator.requestedAppID.map({ $0 == app.id }) ?? true else { return }
        navigator.consume(intent)
    }
}
