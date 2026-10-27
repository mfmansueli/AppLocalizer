//
//  ViewerSidePanel.swift
//  AppLocalizer
//

import SwiftUI

/// The viewer's right side: the locale and its state, the checks, the
/// caption with its fit, the capture, and every localized locale on this
/// slot.
struct ViewerSidePanel: View {
    let viewModel: ScreenshotsViewModel
    let target: ScreenshotViewerTarget
    let cell: ScreenshotCell?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                header
                if let cell {
                    ViewerSection(title: String(localized: "Checks")) {
                        ForEach(cell.checks) { check in
                            RenderCheckRow(check: check)
                        }
                    }
                    .accessibilityIdentifier("screenshots.viewer.checks")
                    ViewerCaptionSection(cell: cell, isRightToLeft: locale?.isRTL ?? false)
                    ViewerCaptureSection(cell: cell, primaryName: viewModel.context.primaryLocale.name)
                }
                ViewerLocaleList(viewModel: viewModel, target: target)
            }
            .padding(Spacing.large)
        }
        .background(Palette.content)
    }

    private var locale: StoreLocale? { viewModel.locale(code: target.locale) }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            FlagTile(regionCode: locale?.regionCode ?? "")
                .frame(width: 20)
            Text(locale?.name ?? target.locale)
                .font(.headline)
            Spacer(minLength: Spacing.small)
            if let cell {
                Pill(text: cell.state.title, style: pillStyle(cell.state))
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("screenshots.viewer.locale")
    }

    private func pillStyle(_ state: ScreenshotCellState) -> PillStyle {
        switch state {
        case .failed: .danger
        case .notPushed: .accent
        case .live, .uploadedByHand, .restored: .neutral
        default: .outline
        }
    }
}
