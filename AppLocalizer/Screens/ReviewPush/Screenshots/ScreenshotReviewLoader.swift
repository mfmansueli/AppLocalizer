//
//  ScreenshotReviewLoader.swift
//  AppLocalizer
//

import SwiftUI

/// Plans the apps in scope whenever review opens, the scope changes or
/// Refresh (⌘R) runs. The main window attaches its account to screenshot
/// pushing (`MainView.configurePush`).
struct ScreenshotReviewLoader: ViewModifier {
    let viewModel: ReviewPushViewModel

    @Environment(WorkspaceNavigator.self) private var navigator

    func body(content: Content) -> some View {
        content
            .task(id: "\(viewModel.scope)|\(navigator.refreshCount)|\(viewModel.screenshots.workspace?.teamName ?? "")") {
                guard viewModel.push.phase == .idle, viewModel.screenshots.run == nil else { return }
                await viewModel.loadScreenshotPlans(refreshCount: navigator.refreshCount)
            }
    }
}
