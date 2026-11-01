//
//  TemplateEditorView.swift
//  AppLocalizer
//

import SwiftUI

/// The Template tab: the header, the slot and locale controls, the canvas
/// with the stress strip on the stage, and the inspector.
struct TemplateEditorView: View {
    let viewModel: ScreenshotsViewModel

    private var model: TemplateEditorViewModel { viewModel.templateEditor }

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                TemplateEditorHeader(model: model)
                TemplateEditorControls(model: model)
                TemplateEditorBanners(viewModel: viewModel, model: model)
                TemplateStage(model: model)
            }
            .frame(maxWidth: .infinity)
            Divider()
            TemplateInspector(model: model)
                .frame(width: Metrics.inspectorWidth)
        }
        .task(id: model.previewInputs) {
            // Lets a slider settle before laying the slot out again.
            try? await Task.sleep(for: .milliseconds(40))
            guard !Task.isCancelled else { return }
            model.refreshPreviews()
        }
        .sheet(isPresented: $model.isStarterSheetPresented) {
            TemplateGallerySheet(viewModel: viewModel)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.template")
    }
}
