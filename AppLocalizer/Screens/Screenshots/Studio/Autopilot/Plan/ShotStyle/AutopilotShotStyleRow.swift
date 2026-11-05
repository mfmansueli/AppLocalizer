//
//  AutopilotShotStyleRow.swift
//  AppLocalizer
//

import SwiftUI

/// Screenshot style, on the plan: the design source's own three
/// directions, one per gallery template picked (up to three, each shown
/// as a preview with the app's captions and captures, chosen in Choose
/// Templates…), or the current template kept with nothing to choose.
struct AutopilotShotStyleRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    @State private var choosesTemplates = false

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: Spacing.small, alignment: .top),
        count: AutopilotShotStyle.maximumTemplates
    )

    var body: some View {
        let design = studio.shotStyleDesigner
        let version = studio.keptTemplateVersion
        let style = plan.screenshotStyle
        HStack(alignment: .top, spacing: Spacing.small) {
            Text("Screenshot style")
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 76, alignment: .leading)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(alignment: .top, spacing: Spacing.small) {
                    StudioSegmentedControl(
                        label: String(localized: "Screenshot style"),
                        options: AutopilotShotStyle.allCases.map { option in
                            .init(
                                value: option, title: option.title(design: design, version: version),
                                isEnabled: option != .keep || version != nil, key: option.rawValue
                            )
                        },
                        selection: Binding { style } set: { studio.setShotStyle($0) },
                        identifier: "autopilot.plan.shotStyle"
                    )
                    .fixedSize()
                    Text(style.note(design: design, brand: studio.shotStyleBrand, picked: plan.screenshotTemplates.count, version: version))
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 3)
                        .accessibilityIdentifier("autopilot.plan.shotStyle.note")
                }
                if style == .templates {
                    picks
                }
            }
        }
        .task(id: style == .templates) {
            guard plan.screenshotStyle == .templates else { return }
            await studio.screenshots.renderStarterPreviews()
        }
        .sheet(isPresented: $choosesTemplates) {
            AutopilotShotTemplatePicker(studio: studio)
        }
    }

    /// The picked templates' previews, the place for another, and Choose
    /// Templates….
    private var picks: some View {
        let picks = studio.shotTemplatePicks
        return VStack(alignment: .leading, spacing: Spacing.small) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.small) {
                ForEach(Array(picks.enumerated()), id: \.element) { index, starter in
                    AutopilotShotTemplateCard(starter: starter, number: index + 1, images: studio.screenshots.starterImages(starter)) {
                        studio.toggleShotTemplate(starter)
                    }
                }
                if picks.count < AutopilotShotStyle.maximumTemplates {
                    AutopilotShotTemplateAddTile(isFirst: picks.isEmpty) { choosesTemplates = true }
                }
            }
            Button(String(localized: "Choose Templates…")) { choosesTemplates = true }
                .controlSize(.small)
                .help(Text("See the 12 templates with \(studio.app.name)’s captions and captures, and pick up to 3"))
                .accessibilityIdentifier("autopilot.plan.shotTemplate.choose")
        }
    }
}
