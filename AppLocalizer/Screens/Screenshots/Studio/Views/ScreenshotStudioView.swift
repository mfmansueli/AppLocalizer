//
//  ScreenshotStudioView.swift
//  AppLocalizer
//

import SwiftUI

/// Screenshots → Preview: the header, the Autopilot strip, the App Store
/// preview, search results, the Live set / New set card and the new set's
/// header and search artwork in detail, with the Autopilot and Connect a
/// Design Project sheets and the full-size viewer.
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
                        content: studio.guidedStrip(assistant: assistant),
                        assistant: assistant,
                        designProject: studio.designProject,
                        perform: perform
                    ) {
                        studio.isDesignProjectPresented = true
                    }
                }
                StoreProductPreviewCard(app: screenshots.app, preview: preview, appearance: $studio.appearance, image: studio.image(for:), studio: studio)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Spacing.large) { bottomCards(preview) }
                    VStack(alignment: .leading, spacing: Spacing.large) { bottomCards(preview) }
                }
                // The new set's header and search artwork, in detail.
                if let details = studio.artworkDetails {
                    StudioArtworkDetailsCard(studio: studio, details: details)
                }
            }
            .padding(Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Inside the scroll view: the section's identifier takes the
            // scroll view itself.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("studio.root")
        }
        .overlay {
            // Over the sheet instead, while it's open.
            if let viewer = studio.viewer, !studio.isAutopilotPresented {
                FullSizeViewer(studio: studio, viewer: viewer)
            }
        }
        .task(id: preview) { studio.loadImages(for: preview) }
        .task { studio.resumeInterruptedWork() }
        .onChange(of: studio.run?.stage) { old, new in studio.runDidChange(from: old, to: new) }
        .sheet(isPresented: $studio.isAutopilotPresented) {
            GuidedAutopilotSheet(studio: studio, assistant: assistant)
        }
        .sheet(isPresented: $studio.isDesignProjectPresented) {
            ConnectDesignProjectSheet(studio: studio)
        }
    }

    @ViewBuilder
    private func bottomCards(_ preview: StudioPreview) -> some View {
        StudioSearchCard(app: screenshots.app, preview: preview, appearance: studio.appearance, image: studio.image(for:), studio: studio)
            .frame(minWidth: 340)
        StudioSetCard(summary: studio.summary, canReview: studio.builder.effectiveChoice == .new) {
            studio.openSets()
        } onReview: {
            navigator?.isReviewPresented = true
        }
        .frame(minWidth: 340)
    }

    /// The assistant that can run Xcode, e.g. "Claude Code": connected, or
    /// one AppLocalizer starts.
    private var assistant: String? {
        assistants?.xcodeAssistant
    }

    private func perform(_ action: AutopilotStripAction) {
        switch action {
        case .runAutopilot:
            studio.runGuidedAutopilot()
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
