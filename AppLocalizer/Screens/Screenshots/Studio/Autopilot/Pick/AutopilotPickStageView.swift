//
//  AutopilotPickStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Pick captures: the assistant's best of each screen, selected, and the
/// others with why they lost. A pick applies to every language and device.
struct AutopilotPickStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool
    /// The width the columns share.
    @State private var rowWidth: CGFloat = 680

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Pick the best captures").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("Ranked by \(client): filled with content, no keyboard or alerts, matches the caption.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
                AutopilotCapturesToCheck(run: run)
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: Spacing.large) {
                        ForEach(Array(run.plan.screens.enumerated()), id: \.element.id) { index, screen in
                            AutopilotPickColumn(
                                studio: studio, run: run, screen: screen, index: index, width: columnWidth, isEditable: isEditable
                            )
                        }
                    }
                }
                .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { rowWidth = $0 })
                if run.plan.displayTypes.contains(.watch), !run.plan.screens(on: .watch).isEmpty {
                    AutopilotWatchPicksRow(studio: studio, run: run, isEditable: isEditable)
                }
                Text(note)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.pick.note")
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.pick")
    }

    private var client: String { run.client ?? String(localized: "the assistant") }

    /// Picks apply to every language, and to each device that shows the
    /// iPhone screens' moments.
    private var note: String {
        let followers = run.plan.displayTypes.filter { $0 != .iPhone && $0 != .watch }.map(\.shortTitle)
        if followers.isEmpty {
            return String(localized: "Picks apply to every language: \(client) captured the same moment in each.")
        }
        let devices = followers.formatted(.list(type: .and))
        return followers.count == 1
            ? String(localized: "Picks apply to every language. \(devices) uses the same moments as iPhone: \(client) captured the same moment in each.")
            : String(localized: "Picks apply to every language. \(devices) use the same moments as iPhone: \(client) captured the same moment in each.")
    }

    /// Every screen fits side by side down to 104 pt a column; beyond
    /// that the row scrolls.
    private var columnWidth: CGFloat {
        Self.columnWidth(for: rowWidth, screens: run.plan.screens.count, spacing: Spacing.large)
    }

    static func columnWidth(for rowWidth: CGFloat, screens: Int, spacing: CGFloat) -> CGFloat {
        let count = CGFloat(max(screens, 1))
        let shared = ((rowWidth - spacing * (count - 1)) / count).rounded(.down)
        return min(max(shared, 104), 168)
    }
}
