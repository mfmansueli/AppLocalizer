//
//  CaptionProposalRowView.swift
//  AppLocalizer
//

import SwiftUI

/// "German · slot 2 · Week": a tick, the old caption struck through, the
/// new one, a fit meter for each, and the proposed render.
struct CaptionProposalRowView: View {
    let row: CaptionProposalRow
    let isSelected: Bool
    let isEnabled: Bool
    let image: CGImage?
    var onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Toggle(isOn: Binding(get: { isSelected }, set: { _ in onToggle() })) {
                Text(row.title)
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(!isEnabled)
            .accessibilityIdentifier("proposals.caption.toggle")
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                HStack(spacing: Spacing.xSmall) {
                    Text(row.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                    if let decision = row.item.decision {
                        let accepted = decision == .accepted
                        Pill(text: accepted ? String(localized: "Accepted") : String(localized: "Rejected"), style: accepted ? .neutral : .outline)
                    }
                }
                if let current = row.currentHeadline {
                    Text(current)
                        .font(.callout)
                        .strikethrough()
                        .foregroundStyle(Palette.label3)
                }
                Text(row.item.headline)
                    .font(.callout.weight(.semibold))
                HStack(spacing: Spacing.large) {
                    meter(row.currentFit, text: row.currentFitText)
                    meter(row.proposedFit, text: row.proposedFitText)
                }
                .padding(.top, Spacing.xxSmall)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            SlotPreviewImage(preview: row.proposedPreview, capture: image, width: 60)
        }
        .padding(Spacing.medium)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proposals.caption.\(row.item.locale).\(row.item.slot)")
    }

    private func meter(_ fit: CaptionFit?, text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if let fit {
                FitMeter(value: FitMeterValue(fit: fit))
            } else {
                Capsule().fill(Palette.fill2).frame(height: 4)
            }
            Text(text)
                .font(.caption)
                .foregroundStyle(fit.map { !$0.fits } == true ? Palette.danger : Palette.label2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
