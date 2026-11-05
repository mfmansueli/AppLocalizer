//
//  AutopilotShotTemplateAddTile.swift
//  AppLocalizer
//

import SwiftUI

/// The empty place after the picked templates, while fewer than three are:
/// opens the template picker. As tall as a picked template's card.
struct AutopilotShotTemplateAddTile: View {
    /// Nothing is picked yet.
    let isFirst: Bool
    let action: () -> Void

    var body: some View {
        let title = isFirst ? String(localized: "Pick a template") : String(localized: "Add a template")
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "plus")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: StarterPreview.thumbnailHeight + 2 * Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.field)
                            .strokeBorder(Palette.label3, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                    Text("From the 12 templates")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .contentShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityIdentifier("autopilot.plan.shotTemplate.add")
    }
}
