//
//  AutopilotDesignStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Design: the three directions arriving one by one, and the log.
struct AutopilotDesignStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Design").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(subtitle).font(.callout).foregroundStyle(Palette.label2)
                }
                if let revision = run.revision {
                    Label("Asked for changes: “\(revision.note)”", systemImage: "arrow.uturn.backward")
                        .font(.callout)
                        .accessibilityIdentifier("autopilot.design.revision")
                }
                HStack(alignment: .top, spacing: Spacing.medium) {
                    ForEach(0..<AutopilotRun.directionCount, id: \.self) { index in
                        card(index)
                    }
                }
                AutopilotLogView(entries: Array(run.log.suffix(8)))
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.design")
    }

    private var subtitle: String {
        run.designKind.usesDesignAI
            ? String(localized: "\(run.designKind.title) designs in \(run.designName ?? run.designKind.title); each direction is an AppLocalizer template.")
            : String(localized: "AppLocalizer’s three starters, colored from the app icon.")
    }

    private func card(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if run.directions.indices.contains(index) {
                let direction = run.directions[index]
                AutopilotDirectionThumbnails(studio: studio, direction: direction, width: 44)
                Text(direction.name).font(.headline)
                Text(direction.rationale).font(.caption).foregroundStyle(Palette.label2).lineLimit(3)
            } else {
                HStack(spacing: Spacing.small) {
                    ProgressView().controlSize(.small)
                    Text("Direction \(index + 1) · designing…").foregroundStyle(Palette.label2)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.design.direction.\(index)")
    }
}
