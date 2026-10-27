//
//  TemplateCanvasView.swift
//  AppLocalizer
//

import SwiftUI

/// The large render of the slot, with the guides, and its fit underneath:
/// "Japanese · Fits at 119 u · 2 lines".
struct TemplateCanvasView: View {
    let model: TemplateEditorViewModel
    let width: CGFloat

    var body: some View {
        VStack(spacing: Spacing.small) {
            if let preview = model.canvas {
                SlotPreviewImage(preview: preview, capture: model.captureImage(for: preview), width: width, showsGuides: model.showsGuides)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    .accessibilityElement()
                    .accessibilityLabel(Text("\(model.locale.name), slot \(model.slot + 1)"))
                    .accessibilityIdentifier("screenshots.template.canvas")
                Text(fitLine(preview))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(preview.firstFailure == nil ? Palette.label2 : Palette.danger)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: width)
                    .accessibilityIdentifier("screenshots.template.fit")
            } else {
                Palette.fill2
                    .frame(width: width, height: width * 2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    .overlay { ProgressView().controlSize(.small) }
            }
        }
    }

    private func fitLine(_ preview: SlotPreview) -> String {
        var parts = [model.locale.name, preview.fitLine]
        if let failure = preview.firstFailure?.shortReason { parts.append(failure) }
        return parts.joined(separator: " · ")
    }
}
