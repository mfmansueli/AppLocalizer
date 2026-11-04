//
//  AutopilotShotStyleRow.swift
//  AppLocalizer
//

import SwiftUI

/// Screenshot style, on the plan: the design source's own three
/// directions, one per gallery template picked (up to three), or the
/// current template kept with nothing to choose.
struct AutopilotShotStyleRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        let design = studio.designProject?.kind.usesDesignAI == true ? studio.headerDesignerName : String(localized: "AppLocalizer")
        let brand = studio.designProject.flatMap { $0.kind.usesDesignAI ? $0.displayName : nil }
        let version = studio.keptTemplateVersion
        let style = plan.screenshotStyle
        let picks = plan.screenshotTemplates
        HStack(alignment: .top, spacing: Spacing.small) {
            Text("Screenshot style")
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 76, alignment: .leading)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 6) {
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
                    Text(style.note(design: design, brand: brand, picked: picks.count, version: version))
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 3)
                        .accessibilityIdentifier("autopilot.plan.shotStyle.note")
                }
                if style == .templates {
                    FlowLayout(spacing: 5) {
                        ForEach(ScreenshotStudioModel.shotTemplateNames, id: \.self) { name in
                            let isOn = picks.contains(name)
                            Button {
                                studio.toggleShotTemplate(name)
                            } label: {
                                Pill(text: name, style: isOn ? .accent : .outline)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isOn ? .isSelected : [])
                            .accessibilityIdentifier("autopilot.plan.shotTemplate.\(name)")
                        }
                    }
                }
            }
        }
    }
}
