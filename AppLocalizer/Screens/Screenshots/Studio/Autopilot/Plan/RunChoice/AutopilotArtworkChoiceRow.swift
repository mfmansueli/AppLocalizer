//
//  AutopilotArtworkChoiceRow.swift
//  AppLocalizer
//

import SwiftUI

/// The plan's Header and search row: a still image or a 20-second motion
/// loop, what the search artwork shows (a phone with the app, the app
/// without a device, or a scene) with small sketches of each, each choice's
/// note under it, and the expected result.
struct AutopilotArtworkChoiceRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        let extras = plan.alsoMakes
        HStack(alignment: .top, spacing: Spacing.small) {
            Text("Header and search")
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 76, alignment: .leading)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Each note sits under its choice, across the row: beside
                // the fixed-width choice it was squeezed into a narrow
                // column.
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    StudioSegmentedControl(
                        label: String(localized: "Still or motion"),
                        options: AutopilotArtworkMotion.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                        selection: Binding { extras.makesMotion ? .loop : .still } set: { studio.setArtworkMotion($0) },
                        identifier: "autopilot.plan.artworkMotion"
                    )
                    .fixedSize()
                    note(ScreenshotStudioModel.artworkMotionNote(extras), identifier: "autopilot.plan.artworkMotionNote")
                }
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    HStack(alignment: .center, spacing: Spacing.small) {
                        StudioSegmentedControl(
                            label: String(localized: "What the search artwork shows"),
                            options: AutopilotArtworkShow.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                            selection: Binding { extras.artworkShows } set: { studio.setArtworkShows($0) },
                            identifier: "autopilot.plan.artworkShows"
                        )
                        .fixedSize()
                        Spacer(minLength: Spacing.small)
                        HStack(spacing: 6) {
                            ArtworkSketch(kind: extras.artworkSize == .wide ? .wide : .header, shows: extras.artworkShows, width: 70)
                            if extras.artworkSize != .wide {
                                ArtworkSketch(kind: .search, shows: extras.artworkShows, width: 45)
                            }
                        }
                        .accessibilityHidden(true)
                    }
                    note(extras.artworkShows.note, identifier: "autopilot.plan.artworkShowsNote")
                }
                AutopilotArtworkDirectionBox(studio: studio, direction: extras.artworkDirection)
            }
        }
    }

    private func note(_ text: String, identifier: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(identifier)
    }
}
