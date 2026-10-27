//
//  ProposalStressStripView.swift
//  AppLocalizer
//

import SwiftUI

/// "Before and after · stress strip": the primary, longest,
/// right-to-left and CJK locales on one slot, from the current template
/// and from the proposed one, each with its fit.
struct ProposalStressStripView: View {
    @Bindable var viewModel: ScreenshotProposalsViewModel
    let proposal: ScreenshotProposal

    static let previewWidth: CGFloat = 92

    var body: some View {
        let columns = viewModel.stressColumns(for: proposal)
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Before and after · stress strip")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.label2)
                Spacer()
                Picker("Slot", selection: $viewModel.stressSlot) {
                    ForEach(0..<(viewModel.document?.slotCount ?? 5), id: \.self) { slot in
                        Text(verbatim: "\(slot + 1)").tag(slot)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("proposals.stressSlot")
            }
            Grid(alignment: .topLeading, horizontalSpacing: Spacing.large, verticalSpacing: Spacing.small) {
                GridRow {
                    Color.clear.frame(width: 50, height: 1)
                    ForEach(columns) { column in
                        Text(column.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.label2)
                            .lineLimit(1)
                            .frame(width: Self.previewWidth + 40, alignment: .leading)
                    }
                }
                row(title: String(localized: "Before"), previews: columns.map(\.before))
                row(title: String(localized: "After"), previews: columns.map(\.after))
            }
        }
        .onAppear { viewModel.loadImages(for: columns) }
        .onChange(of: viewModel.stressSlot) { viewModel.loadImages(for: viewModel.stressColumns(for: proposal)) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proposals.stressStrip")
    }

    private func row(title: String, previews: [SlotPreview?]) -> some View {
        GridRow {
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .frame(width: 50, alignment: .leading)
                .gridCellAnchor(.leading)
            ForEach(Array(previews.enumerated()), id: \.offset) { _, preview in
                if let preview {
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        SlotPreviewImage(preview: preview, capture: image(for: preview), width: Self.previewWidth)
                        Text(preview.fit.label)
                            .font(.caption)
                            .foregroundStyle(preview.hasCaptionProblem ? Palette.danger : Palette.label2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    Text("Can’t apply")
                        .font(.caption)
                        .foregroundStyle(Palette.label3)
                }
            }
        }
    }

    private func image(for preview: SlotPreview) -> CGImage? {
        viewModel.captureImages.image(for: preview.job.capture, width: ScreenshotProposalsViewModel.captureImageWidth)
    }
}
