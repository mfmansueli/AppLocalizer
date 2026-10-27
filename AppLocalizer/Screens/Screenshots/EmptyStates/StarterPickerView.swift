//
//  StarterPickerView.swift
//  AppLocalizer
//

import SwiftUI

/// Sets with captures but no template: three starters previewed with the
/// app's own captures. One template renders every locale the same way.
struct StarterPickerView: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("Pick a starter template")
                        .font(.title3.weight(.semibold))
                    Text(intro)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .top, spacing: Spacing.large) {
                    ForEach(TemplateStarter.allCases) { starter in
                        StarterCard(
                            starter: starter,
                            images: images(for: starter),
                            thumbnailHeight: thumbnailHeight
                        ) {
                            Task { await viewModel.chooseStarter(starter) }
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.xxLarge)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.starters")
    }

    private var intro: String {
        let summary = viewModel.captureSummary
        let rest = String(localized: "One template renders every locale the same way; you can change everything afterwards. Previewed with sample captions.")
        return summary.isEmpty ? rest : summary + " " + rest
    }

    private var thumbnailHeight: CGFloat {
        let size = ScreenshotDisplayType.iPhone.portraitPixelSize
        return (CGFloat(StarterPreview.pixelWidth / 2) * CGFloat(size.height) / CGFloat(size.width)).rounded()
    }

    private func images(for starter: TemplateStarter) -> [CGImage?] {
        guard let preview = viewModel.starterPreviews.first(where: { $0.starter == starter }) else {
            return [nil, nil, nil]
        }
        return preview.jobs.map { viewModel.renderQueue.images[$0.key] }
    }
}
