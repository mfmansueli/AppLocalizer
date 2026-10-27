//
//  ScreenshotReviewLoader.swift
//  AppLocalizer
//

import SwiftUI

/// Points screenshot pushing at the window's account and plans the apps in
/// scope whenever review opens, the scope changes or Refresh (⌘R) runs.
/// The account comes from the assistants' workspace, which the main window
/// keeps current for every open account.
struct ScreenshotReviewLoader: ViewModifier {
    let viewModel: ReviewPushViewModel

    @Environment(MCPServerController.self) private var assistants
    @Environment(WorkspaceNavigator.self) private var navigator

    func body(content: Content) -> some View {
        content
            .task(id: "\(viewModel.scope)|\(navigator.refreshCount)|\(assistants.workspace?.teamName ?? "")") {
                ScreenshotPushWorkspace.attach(assistants.workspace, to: viewModel.screenshots)
                guard viewModel.push.phase == .idle, viewModel.screenshots.run == nil else { return }
                await viewModel.loadScreenshotPlans(refreshCount: navigator.refreshCount)
            }
    }
}
