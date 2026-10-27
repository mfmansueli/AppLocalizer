//
//  CaptionProposalDetailView.swift
//  AppLocalizer
//

import SwiftUI

/// A caption proposal: each caption ticked or not, the one it replaces
/// struck through, both measured, and the render accepting it makes.
struct CaptionProposalDetailView: View {
    @Bindable var viewModel: ScreenshotProposalsViewModel
    let proposal: ScreenshotProposal

    var body: some View {
        let rows = viewModel.rows(of: proposal)
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Divider() }
                CaptionProposalRowView(
                    row: row,
                    isSelected: viewModel.isSelected(row.id, in: proposal),
                    isEnabled: proposal.isWaiting,
                    image: viewModel.captureImages.image(for: row.proposedPreview.job.capture, width: ScreenshotProposalsViewModel.captureImageWidth)
                ) {
                    viewModel.toggle(row.id, in: proposal)
                }
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .onAppear { viewModel.loadImages(for: rows) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proposals.captions")
    }
}
