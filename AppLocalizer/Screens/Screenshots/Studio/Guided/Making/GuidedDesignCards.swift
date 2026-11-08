//
//  GuidedDesignCards.swift
//  AppLocalizer
//

import SwiftUI

/// Making it while the looks are designed: a card per look, its
/// screenshots once it arrives, "Designing…" while someone works on it,
/// "Waiting" until then.
struct GuidedDesignCards: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The row's width, measured: the thumbnails are sized from it. It
    /// starts at 0 and the row reports the width it's offered, so rigid
    /// thumbnails can't lock in a wider page (see `AutopilotDesignCardsLayout`).
    @State private var width: CGFloat = 0

    /// A thumbnail's widest; Bruma's nine screens at this size made three
    /// cards wider than the sheet, and the page slid off its left edge.
    static let largestThumbnail: CGFloat = 40
    static let cardPadding: CGFloat = 10

    var body: some View {
        let cards = AutopilotDirectionCard.cards(of: run, isWorking: studio.assistantIsWorking)
        AutopilotDesignCardsLayout(spacing: Spacing.medium, equalHeights: true) {
            ForEach(cards.indices, id: \.self) { index in
                card(cards[index], index: index, count: cards.count)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { width = $0 })
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.making.looks")
    }

    /// How wide a look's thumbnails are in a card of the row's `count` in
    /// `width`: the largest, or what fits its screens (Apple Vision Pro and
    /// Apple Watch on a line of their own when that fits them better).
    static func thumbnails(in width: CGFloat, count: Int, screens: Int, hasVision: Bool, hasWatch: Bool) -> (thumbnail: CGFloat, stacks: Bool) {
        let card = AutopilotDesignCardsLayout.cardWidth(in: width, count: count) - cardPadding * 2
        return AutopilotDirectionThumbnails.fit(
            in: card, screens: screens, hasVision: hasVision, hasWatch: hasWatch, maximum: largestThumbnail
        )
    }

    private func card(_ card: AutopilotDirectionCard, index: Int, count: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            switch card {
            case let .arrived(direction):
                Text(direction.name).font(.callout.weight(.semibold)).lineLimit(1)
                if run.plan.makesScreenshots {
                    let fit = Self.thumbnails(
                        in: width, count: count, screens: studio.layouts(for: direction).count,
                        hasVision: studio.visionPreview(for: direction) != nil, hasWatch: studio.watchPreviewCapture != nil
                    )
                    AutopilotDirectionThumbnails(studio: studio, direction: direction, width: fit.thumbnail, stacksDevices: fit.stacks) { slot in
                        studio.openDirection(direction, at: slot)
                    }
                } else {
                    Text(direction.rationale).font(.caption).foregroundStyle(Palette.label2).lineLimit(3)
                }
            case .designing:
                HStack(spacing: Spacing.xSmall) {
                    ProgressView().controlSize(.small)
                    Text("Designing…")
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(Palette.label2)
                placeholder
            case .upNext, .waiting:
                Text("Waiting").font(.callout.weight(.semibold)).foregroundStyle(Palette.label3)
                placeholder
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(GuidedSelectableCard(padding: Self.cardPadding))
        .accessibilityElement(children: card.isArrived ? .contain : .combine)
        .accessibilityIdentifier("autopilot.guided.making.look.\(index)")
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Spacing.small, style: .continuous)
            .fill(Palette.fill1)
            .frame(height: 96)
    }
}
