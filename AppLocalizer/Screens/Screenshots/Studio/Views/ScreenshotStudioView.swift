//
//  ScreenshotStudioView.swift
//  AppLocalizer
//

import SwiftUI

/// Screenshots → Preview: the header, the Autopilot strip, the App Store
/// preview, search results and the Live set / New set card, with the
/// Autopilot and Connect a Design Project sheets.
struct ScreenshotStudioView: View {
    @Bindable var screenshots: ScreenshotsViewModel
    @Environment(MCPServerController.self) private var assistants: MCPServerController?
    @Environment(WorkspaceNavigator.self) private var navigator: WorkspaceNavigator?

    private var studio: ScreenshotStudioModel { screenshots.studio }

    var body: some View {
        @Bindable var studio = studio
        let preview = studio.preview
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                StudioHeader(studio: studio, screenshots: screenshots)
                if studio.autopilot != nil {
                    AutopilotStripView(
                        content: studio.strip(assistant: assistant),
                        assistant: assistant,
                        designProject: studio.designProject,
                        perform: perform
                    ) {
                        studio.isDesignProjectPresented = true
                    }
                }
                StoreProductPreviewCard(app: screenshots.app, preview: preview, appearance: $studio.appearance, image: studio.image(for:))
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Spacing.large) { bottomCards(preview) }
                    VStack(alignment: .leading, spacing: Spacing.large) { bottomCards(preview) }
                }
            }
            .padding(Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Inside the scroll view: the section's identifier takes the
            // scroll view itself.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("studio.root")
        }
        .task(id: preview) { studio.loadImages(for: preview) }
        .onChange(of: studio.run?.stage) { old, new in studio.runDidChange(from: old, to: new) }
        .sheet(isPresented: $studio.isAutopilotPresented) {
            AutopilotSheet(studio: studio, assistant: assistant)
        }
        .sheet(isPresented: $studio.isDesignProjectPresented) {
            ConnectDesignProjectSheet(studio: studio)
        }
    }

    @ViewBuilder
    private func bottomCards(_ preview: StudioPreview) -> some View {
        StudioSearchCard(app: screenshots.app, preview: preview, appearance: studio.appearance, image: studio.image(for:))
            .frame(minWidth: 340)
        StudioSetCard(summary: studio.summary, canReview: studio.builder.effectiveChoice == .new) {
            studio.openSets()
        } onReview: {
            navigator?.isReviewPresented = true
        }
        .frame(minWidth: 340)
    }

    /// The connected assistant that can run Xcode, e.g. "Claude Code".
    private var assistant: String? {
        assistants?.connectedClients.first { $0.kind.canRunXcode }?.name
    }

    private func perform(_ action: AutopilotStripAction) {
        switch action {
        case .runAutopilot:
            studio.runAutopilot()
        case .open:
            studio.openAutopilot()
        case .setUpAssistant:
            navigator?.assistantSetupMethod = .assistant
            navigator?.isAssistantSetupPresented = true
        case .importCaptures:
            screenshots.tab = .captures
            screenshots.captures.isImporterPresented = true
        case .reviewPush:
            navigator?.isReviewPresented = true
        }
    }
}
