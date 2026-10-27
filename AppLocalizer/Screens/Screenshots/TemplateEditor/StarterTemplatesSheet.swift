//
//  StarterTemplatesSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Starter Templates…: the three starters previewed with the app's own
/// captions and captures. Switching starts a new version; captions and
/// captures stay.
struct StarterTemplatesSheet: View {
    let viewModel: ScreenshotsViewModel
    @Environment(\.dismiss) private var dismiss

    private var model: TemplateEditorViewModel { viewModel.templateEditor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Starter templates")
                    .font(.title2.weight(.semibold))
                Text(model.starterSheetNote)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            HStack(alignment: .top, spacing: Spacing.medium) {
                ForEach(TemplateStarter.allCases) { starter in
                    StarterCard(
                        starter: starter,
                        images: images(for: starter),
                        thumbnailHeight: thumbnailHeight,
                        buttonTitle: model.starterButtonTitle(starter)
                    ) {
                        Task { await model.switchStarter(starter) }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.bottom, Spacing.large)
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
        .frame(width: 860)
        .task { await viewModel.renderStarterPreviews() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.starterSheet")
    }

    private var thumbnailHeight: CGFloat {
        let size = ScreenshotDisplayType.iPhone.portraitPixelSize
        return (CGFloat(StarterPreview.pixelWidth / 2) * CGFloat(size.height) / CGFloat(size.width)).rounded()
    }

    private func images(for starter: TemplateStarter) -> [CGImage?] {
        guard let preview = viewModel.starterPreviews.first(where: { $0.starter == starter }) else { return [nil, nil, nil] }
        return preview.jobs.map { viewModel.renderQueue.images[$0.key] }
    }
}
