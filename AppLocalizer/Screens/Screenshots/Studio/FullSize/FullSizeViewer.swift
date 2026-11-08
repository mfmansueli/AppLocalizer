//
//  FullSizeViewer.swift
//  AppLocalizer
//

import SwiftUI

/// The studio's full-size viewer over the app (`FullSizeViewerChrome`):
/// the item's name, size and language, its button (Use This Capture, Show
/// iPhone Area), "2 of 5", previous and next. An App Preview or a
/// recording plays in it; Space plays or pauses it, and closes the viewer
/// on anything else.
struct FullSizeViewer: View {
    @Bindable var studio: ScreenshotStudioModel
    let viewer: StudioViewer

    var body: some View {
        FullSizeViewerChrome(
            identifier: "studio.viewer",
            title: viewer.current.title,
            subtitle: viewer.current.subtitle,
            countTitle: viewer.countTitle,
            hasPrevious: viewer.hasPrevious,
            hasNext: viewer.hasNext,
            onStep: studio.stepViewer,
            onClose: studio.closeViewer,
            onSpace: space
        ) {
            if studio.viewerTemplate != nil, let plan = studio.run?.plan {
                languages(plan)
            } else if studio.viewerReviewDevice != nil {
                reviewLanguages
            }
            if let action = viewer.current.action {
                actionButton(action)
            }
        } content: { size in
            FullSizeViewerContentView(studio: studio, item: viewer.current, size: size)
                .id(viewer.current.id)
        }
    }

    private func space() {
        if viewer.current.content.isAppPreview {
            studio.previewPlayer.toggle()
        } else if viewer.current.content.isRecording {
            studio.recordingPlayer.toggle()
        } else if viewer.current.content.isMotion {
            studio.artworkLoop.toggle()
        } else {
            studio.closeViewer()
        }
    }

    /// A previewed template's languages: switching one keeps the screen.
    @ViewBuilder
    private func languages(_ plan: AutopilotPlan) -> some View {
        let locales = studio.templatePreviewLocales(plan)
        if locales.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Preview language"),
                options: locales.map { .init(value: $0, title: GuidedPreviewLocales.title(of: $0, among: locales), key: $0) },
                selection: Binding { studio.templatePreviewLocale(plan) } set: { studio.setViewerTemplateLocale($0) },
                identifier: "studio.viewer.language"
            )
        }
    }

    /// Review & push's screenshots: switching the language keeps the
    /// screen.
    @ViewBuilder
    private var reviewLanguages: some View {
        let locales = studio.viewerReviewLocales
        if locales.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Language"),
                options: locales.map { .init(value: $0, title: GuidedPreviewLocales.title(of: $0, among: locales), key: $0) },
                selection: Binding { studio.guidedReviewLocale } set: { studio.setViewerReviewLocale($0) },
                identifier: "studio.viewer.language"
            )
        }
    }

    @ViewBuilder
    private func actionButton(_ action: StudioViewerAction) -> some View {
        let title = action.title(showsGuide: studio.viewerShowsGuide)
        if action.isProminent {
            Button(title) { studio.performViewerAction(action) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("studio.viewer.action")
        } else {
            Button(title) { studio.performViewerAction(action) }
                .controlSize(.small)
                .disabled(!action.isEnabled)
                .accessibilityIdentifier("studio.viewer.action")
        }
    }
}
