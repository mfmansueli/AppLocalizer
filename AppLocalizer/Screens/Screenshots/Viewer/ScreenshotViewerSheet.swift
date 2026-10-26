//
//  ScreenshotViewerSheet.swift
//  AppLocalizer
//

import SwiftUI

/// The full-size viewer: one slot in one locale, stepping through the
/// localized sets with ◀ ▶, with its checks, caption, capture and the
/// other locales beside it.
struct ScreenshotViewerSheet: View {
    @Bindable var viewModel: ScreenshotsViewModel
    let target: ScreenshotViewerTarget

    var body: some View {
        let cell = viewModel.viewerCell(target)
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                ViewerStage(viewModel: viewModel, cell: cell)
                Divider()
                ViewerSidePanel(viewModel: viewModel, target: target, cell: cell)
                    .frame(width: 300)
            }
            Divider()
            footer
        }
        .frame(width: 960, height: 700)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.viewer")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.viewerTitle(target))
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("screenshots.viewer.title")
                Text(viewModel.viewerSubtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            Spacer()
            Button {
                viewModel.stepViewer(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonBorderShape(.capsule)
            .keyboardShortcut(.leftArrow, modifiers: [])
            .accessibilityLabel(Text("Previous locale"))
            .accessibilityIdentifier("screenshots.viewer.previous")
            Text(viewModel.viewerPosition(target))
                .font(.callout.monospacedDigit())
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("screenshots.viewer.position")
            Button {
                viewModel.stepViewer(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonBorderShape(.capsule)
            .keyboardShortcut(.rightArrow, modifiers: [])
            .accessibilityLabel(Text("Next locale"))
            .accessibilityIdentifier("screenshots.viewer.next")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            Button("Edit Caption") { viewModel.editCaption() }
                .accessibilityIdentifier("screenshots.viewer.editCaption")
            Button("Open in Template Editor") { viewModel.openTemplateEditor() }
                .accessibilityIdentifier("screenshots.viewer.openTemplate")
            Spacer()
            Button("Done") { viewModel.viewer = nil }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("screenshots.viewer.done")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }
}
