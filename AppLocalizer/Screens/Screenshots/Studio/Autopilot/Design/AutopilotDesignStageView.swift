//
//  AutopilotDesignStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Design: how many directions arrived, who's working on them and what
/// it's doing now (or why nobody is, with Continue), the three directions
/// arriving one by one, and the log. A card only spins while someone works
/// on it (`AutopilotDirectionCard`). The cards share the width they have:
/// the thumbnails shrink to fit, and a click opens one full size.
struct AutopilotDesignStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The page's width inside its padding, measured; the cards size their
    /// thumbnails from it (`AutopilotDesignCardsLayout` keeps it honest).
    @State private var contentWidth: CGFloat = 0

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
                AutopilotDesignCardsLayout(spacing: Spacing.medium) {
                    let cards = AutopilotDirectionCard.cards(of: run, isWorking: studio.assistantIsWorking)
                    ForEach(cards.indices, id: \.self) { index in
                        card(cards[index], index: index)
                    }
                }
                AutopilotLogView(entries: Array(run.log.suffix(8)))
                if run.plan.alsoMakes.makesArtwork, run.designKind.usesDesignAI {
                    AutopilotArtworkBriefBox(run: run)
                }
            }
            .padding(Spacing.xLarge)
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { contentWidth = $0 - Spacing.xLarge * 2 })
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
                arrived(direction)
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
        .accessibilityElement(children: card.isArrived ? .contain : .combine)
        .accessibilityIdentifier("autopilot.design.direction.\(index)")
    }

    /// The width inside one of the three cards.
    private var cardWidth: CGFloat {
        Self.cardWidth(in: contentWidth, cards: AutopilotRun.directionCount)
    }

    static func cardWidth(in width: CGFloat, cards: Int) -> CGFloat {
        max(0, AutopilotDesignCardsLayout.cardWidth(in: width, count: cards) - Spacing.medium * 2)
    }

    /// The screenshots, then the header, search and App Preview poster when
    /// the run makes them, each opening full size.
    private func arrived(_ direction: AutopilotDirection) -> some View {
        let fit = AutopilotDirectionThumbnails.fit(
            in: cardWidth, screens: studio.layouts(for: direction).count,
            hasVision: studio.visionPreview(for: direction) != nil, hasWatch: studio.watchPreviewCapture != nil, maximum: 44
        )
        let plan = run.plan
        return VStack(alignment: .leading, spacing: Spacing.small) {
            AutopilotDirectionThumbnails(studio: studio, direction: direction, width: fit.thumbnail, stacksDevices: fit.stacks) { index in
                studio.openDirection(direction, at: index)
            }
            if !plan.alsoMakes.isEmpty {
                AutopilotDirectionExtras(
                    studio: studio, run: run, direction: direction,
                    height: AutopilotDirectionExtras.fittingHeight(
                        in: cardWidth, kinds: plan.artworkKinds, hasPreview: !plan.previewDisplays.isEmpty, maximum: 64
                    )
                )
            }
        }
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
