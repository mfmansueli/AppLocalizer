//
//  TemplateGallerySheet.swift
//  AppLocalizer
//

import SwiftUI

/// Templates…: every gallery template previewed with the app's own
/// captions and captures, filtered by style. Switching starts a new
/// version; captions and captures stay.
struct TemplateGallerySheet: View {
    @Bindable var viewModel: ScreenshotsViewModel
    @Environment(\.dismiss) private var dismiss

    private var model: TemplateEditorViewModel { viewModel.templateEditor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Templates")
                    .font(.title2.weight(.semibold))
                Text(model.starterSheetNote)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            HStack(spacing: Spacing.small) {
                TemplateStyleFilter(style: $viewModel.galleryStyle)
                Spacer(minLength: Spacing.small)
                Text(viewModel.galleryCount)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .accessibilityIdentifier("screenshots.gallery.count")
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            ScrollView {
                TemplateGalleryGrid(viewModel: viewModel, isFirstRun: false) { starter in
                    Task { await model.switchStarter(starter) }
                }
                .padding(.horizontal, Spacing.xLarge)
                .padding(.bottom, Spacing.large)
            }
            Divider()
            HStack {
                Text("Switching starts a new template version. Captions and captures stay as they are.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(Spacing.large)
        }
        .frame(minWidth: 640, idealWidth: 940, maxWidth: 940, minHeight: 480, idealHeight: 760, maxHeight: 900)
        .task { await viewModel.renderStarterPreviews() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.templateGallery")
    }
}
