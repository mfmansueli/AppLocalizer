//
//  GuidedTemplateStrip.swift
//  AppLocalizer
//

import SwiftUI

/// The previewed template's screenshots side by side, scrolling sideways
/// when they don't fit.
struct GuidedTemplateStrip: View {
    let studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let preview: GuidedTemplatePreview

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(preview.items) { item in
                    GuidedTemplateShot(
                        studio: studio, plan: plan, preview: preview, item: item,
                        width: GuidedTemplateShot.width(for: item, on: preview.device)
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.automatic)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier("autopilot.guided.look.template.strip")
    }

    /// "Arcade on iPad in German".
    private var label: String {
        String(localized: "\(preview.starter.title) on \(GuidedTemplatePreviewDevices.title(preview.device)) in \(preview.locale.shortName)")
    }
}
