//
//  AutopilotDesignStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Design: how many directions arrived, who's working on them and what
/// it's doing now (or why nobody is, with Continue), the three directions
/// arriving one by one, and the log. A card only spins while someone works
/// on it (`AutopilotDirectionCard`).
struct AutopilotDesignStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Design").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        Spacer()
                        if run.revision == nil {
                            Text("\(run.directions.count) of \(AutopilotRun.directionCount)")
                                .monospacedDigit()
                                .foregroundStyle(Palette.label2)
                                .accessibilityIdentifier("autopilot.design.count")
                        }
                    }
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.design.subtitle")
                }
                if run.revision == nil {
                    ProgressView(value: Double(run.directions.count), total: Double(AutopilotRun.directionCount))
                        .accessibilityLabel(Text("\(run.directions.count) of \(AutopilotRun.directionCount) directions arrived"))
                }
                if let revision = run.revision {
                    Label("Asked for changes: “\(revision.note)”", systemImage: "arrow.uturn.backward")
                        .font(.callout)
                        .accessibilityIdentifier("autopilot.design.revision")
                }
                AutopilotAssistantStatus(studio: studio, run: run, launchNote: launchNote)
                HStack(alignment: .top, spacing: Spacing.medium) {
                    let cards = AutopilotDirectionCard.cards(of: run, isWorking: studio.assistantIsWorking)
                    ForEach(cards.indices, id: \.self) { index in
                        card(cards[index], index: index)
                    }
                }
                AutopilotLogView(entries: Array(run.log.suffix(8)))
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.design")
    }

    /// Who designs, from what. Claude Code that AppLocalizer started can't
    /// open Claude Design or Figma, so it designs from the brief.
    private var subtitle: String {
        guard run.designKind.usesDesignAI else {
            return String(localized: "AppLocalizer’s three starters, colored from the app icon.")
        }
        let name = run.designName ?? run.designKind.title
        guard run.startsClaudeCode == true else {
            return String(localized: "\(run.designKind.title) designs in \(name); each direction is an AppLocalizer template.")
        }
        return studio.designProject?.summary == nil
            ? String(localized: "Claude Code designs from AppLocalizer’s brief; each direction is an AppLocalizer template.")
            : String(localized: "Claude Code designs from AppLocalizer’s brief and what it read in \(name); each direction is an AppLocalizer template.")
    }

    private var client: String { run.client ?? String(localized: "Claude Code") }

    private var launchNote: String {
        String(localized: """
        It designs from AppLocalizer’s brief and sends each direction here. Started from AppLocalizer, it can’t open \
        Claude Design or Figma.
        """)
    }

    private func card(_ card: AutopilotDirectionCard, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            switch card {
            case let .arrived(direction):
                AutopilotDirectionThumbnails(studio: studio, direction: direction, width: 44)
                Text(direction.name).font(.headline)
                Text(direction.rationale).font(.caption).foregroundStyle(Palette.label2).lineLimit(3)
            case let .designing(since):
                placeholder {
                    HStack(spacing: Spacing.small) {
                        ProgressView().controlSize(.small)
                        Text("Direction \(index + 1) · designing…")
                    }
                } detail: {
                    if let since {
                        TimelineView(.periodic(from: since, by: 30)) { context in
                            Text("For \(Self.minutes(from: since, to: context.date))")
                        }
                    } else {
                        Text("\(client) reads the brief first")
                    }
                }
            case .upNext:
                placeholder {
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "hourglass").accessibilityHidden(true)
                        Text("Direction \(index + 1) · up next")
                    }
                } detail: {
                    Text("After direction \(index)")
                }
            case .waiting:
                placeholder {
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "pause.circle").accessibilityHidden(true)
                        Text("Direction \(index + 1)")
                    }
                } detail: {
                    Text("Waits for \(client)")
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.design.direction.\(index)")
    }

    private func placeholder(
        @ViewBuilder title: () -> some View,
        @ViewBuilder detail: () -> some View
    ) -> some View {
        VStack(spacing: Spacing.xSmall) {
            title()
                .foregroundStyle(Palette.label2)
            detail()
                .font(.caption)
                .foregroundStyle(Palette.label3)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    /// "less than a minute", "4 min".
    private static func minutes(from start: Date, to end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        return minutes < 1 ? String(localized: "less than a minute") : String(localized: "\(minutes) min")
    }
}
