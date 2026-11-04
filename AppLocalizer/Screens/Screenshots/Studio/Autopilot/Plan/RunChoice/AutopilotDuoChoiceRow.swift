//
//  AutopilotDuoChoiceRow.swift
//  AppLocalizer
//

import SwiftUI

/// The plan's iPhone Duo row: the inner display (unfolded, Apple's
/// requirement), the cover display, or both, side by side in each image or
/// as separate screenshots, with what that shows and costs.
struct AutopilotDuoChoiceRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text("iPhone Duo").font(.callout.weight(.medium)).frame(width: 76, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Spacing.small) {
                    StudioSegmentedControl(
                        label: String(localized: "iPhone Duo screens"),
                        options: AutopilotDuoScreens.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                        selection: Binding { plan.duoScreens } set: { studio.setDuoScreens($0) },
                        identifier: "autopilot.plan.duoScreens"
                    )
                    .fixedSize()
                    if plan.duoScreens == .both {
                        StudioSegmentedControl(
                            label: String(localized: "How both states appear"),
                            options: AutopilotDuoBoth.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                            selection: Binding { plan.duoBoth } set: { studio.setDuoBoth($0) },
                            identifier: "autopilot.plan.duoBoth"
                        )
                        .fixedSize()
                    }
                }
                Text(ScreenshotStudioModel.duoNote(plan))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.plan.duoNote")
            }
        }
    }
}
