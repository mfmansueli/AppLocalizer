//
//  GuidedTemplateNotInRun.swift
//  AppLocalizer
//

import SwiftUI

/// Over the screenshots, on a device the run doesn't make yet: that it's
/// only a preview, and Add … to the Run.
struct GuidedTemplateNotInRun: View {
    @Bindable var studio: ScreenshotStudioModel
    let preview: GuidedTemplatePreview

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(preview.notInRunText)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("autopilot.guided.look.template.notInRun")
            Button(preview.addTitle) { studio.addTemplatePreviewDevice(preview.device) }
                .controlSize(.small)
                .fixedSize()
                .accessibilityIdentifier("autopilot.guided.look.template.addDevice")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
