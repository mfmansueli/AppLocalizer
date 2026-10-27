//
//  ScreenshotPushHooks.swift
//  AppLocalizer
//

import SwiftUI

/// What Review & Push tells an open Screenshots view: reload when a push,
/// a discard or a restore saved the app's document (so the view never
/// saves over it), and open Captions for Show in Captions.
struct ScreenshotPushHooks: ViewModifier {
    let viewModel: ScreenshotsViewModel

    @Environment(PushController.self) private var push

    func body(content: Content) -> some View {
        content
            .task(id: push.screenshots.revisions[viewModel.app.id] ?? 0) {
                await reloadIfSavedElsewhere()
            }
            .onChange(of: push.screenshots.captionsRequest, initial: true) {
                openCaptions()
            }
    }

    /// Reloads when the saved document differs from the one shown.
    private func reloadIfSavedElsewhere() async {
        guard viewModel.isLoaded, !viewModel.isLoading, (push.screenshots.revisions[viewModel.app.id] ?? 0) > 0,
              let saved = try? await viewModel.services.document(for: viewModel.app, primaryLocale: viewModel.context.primaryLocale),
              saved != viewModel.document else { return }
        await viewModel.load()
    }

    private func openCaptions() {
        guard let request = push.screenshots.captionsRequest, request.appID == viewModel.app.id else { return }
        viewModel.displayType = request.cell.displayType
        viewModel.tab = .captions
        push.screenshots.consumeCaptionsRequest()
    }
}
