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
                            Text("\(arrived) of \(expected)")
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
                    ProgressView(value: Double(arrived), total: Double(max(expected, 1)))
                        .accessibilityLabel(Text(run.usesConcepts ? "\(arrived) of \(expected) arrived" : "\(arrived) of \(expected) directions arrived"))
                }
                // What comes next, before anything arrives.
                if let next = run.nextChoiceLine {
                    Text(next)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                        .accessibilityAddTraits(.isStaticText)
                        .accessibilityIdentifier("autopilot.design.next")
                }
                if let revision = run.revision {
                    Label("Asked for changes: “\(revision.note)”", systemImage: "arrow.uturn.backward")
                        .font(.callout)
                        .accessibilityIdentifier("autopilot.design.revision")
                }
                AutopilotAssistantStatus(studio: studio, run: run, launchNote: launchNote)
                if run.usesConcepts {
                    AutopilotConceptsBox(studio: studio, run: run)
                }
                if run.hasDirections {
                    AutopilotDesignCardsLayout(spacing: Spacing.medium) {
                        let cards = AutopilotDirectionCard.cards(of: run, isWorking: studio.assistantIsWorking)
                        ForEach(cards.indices, id: \.self) { index in
                            card(cards[index], index: index)
                        }
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
        let each = Self.eachDirection(run.plan)
        guard run.startsClaudeCode == true else {
            return String(localized: "\(run.designKind.title) designs in \(name); \(each).")
        }
        return studio.designProject?.summary == nil
            ? String(localized: "Claude Code designs from AppLocalizer’s brief; \(each).")
            : String(localized: "Claude Code designs from AppLocalizer’s brief and what it read in \(name); \(each).")
    }

    /// What each direction is: an AppLocalizer template, or, without
    /// screenshots, only what the run makes.
    static func eachDirection(_ plan: AutopilotPlan) -> String {
        if plan.makesScreenshots { return String(localized: "each direction is an AppLocalizer template") }
        guard plan.alsoMakes.makesArtwork else {
            return String(localized: "each direction is a look for the App Preview, and the live screenshots stay as they are")
        }
        return String(localized: "each direction is its own header and search images, and the live screenshots stay as they are")
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

    /// What arrived of what Design waits for: the directions, and the
    /// concepts with their pages.
    private var arrived: Int { run.directions.count + run.designedConcepts.count }
    private var expected: Int { run.expectedDirections + run.expectedConcepts }

    /// The width inside one of the cards.
    private var cardWidth: CGFloat {
        Self.cardWidth(in: contentWidth, cards: max(run.expectedDirections, 1))
    }

    static func cardWidth(in width: CGFloat, cards: Int) -> CGFloat {
        max(0, AutopilotDesignCardsLayout.cardWidth(in: width, count: cards) - Spacing.medium * 2)
    }

    /// The screenshots, then the header, search and App Preview poster when
    /// the run makes them, each opening full size. A run without
    /// screenshots shows only what it makes, bigger.
    private func arrived(_ direction: AutopilotDirection) -> some View {
        let plan = run.plan
        return VStack(alignment: .leading, spacing: Spacing.small) {
            if plan.makesScreenshots {
                let fit = AutopilotDirectionThumbnails.fit(
                    in: cardWidth, screens: studio.layouts(for: direction).count,
                    hasVision: studio.visionPreview(for: direction) != nil, hasWatch: studio.watchPreviewCapture != nil, maximum: 44
                )
                AutopilotDirectionThumbnails(studio: studio, direction: direction, width: fit.thumbnail, stacksDevices: fit.stacks) { index in
                    studio.openDirection(direction, at: index)
                }
            }
            if !plan.alsoMakes.isEmpty, !run.usesConcepts || !plan.previewDisplays.isEmpty {
                AutopilotDirectionExtras(studio: studio, run: run, direction: direction, fit: Self.extrasFit(run, cardWidth: cardWidth))
            }
        }
    }

    /// The extras under the screenshots, at most 64 pt tall; without
    /// screenshots they're the whole direction, up to 96 pt, the header on
    /// a line of its own when the card is narrow.
    static func extrasFit(_ run: AutopilotRun, cardWidth: CGFloat) -> AutopilotDirectionExtras.Fit {
        let plan = run.plan
        return AutopilotDirectionExtras.fit(
            in: cardWidth, kinds: run.directionArtworkKinds, hasPreview: !plan.previewDisplays.isEmpty,
            maximum: plan.makesScreenshots ? 64 : 96, stacking: !plan.makesScreenshots
        )
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
