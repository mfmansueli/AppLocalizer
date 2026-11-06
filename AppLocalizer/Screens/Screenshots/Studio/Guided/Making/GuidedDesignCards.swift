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

    var body: some View {
        let cards = AutopilotDirectionCard.cards(of: run, isWorking: studio.assistantIsWorking)
        HStack(alignment: .top, spacing: Spacing.medium) {
            ForEach(cards.indices, id: \.self) { index in
                card(cards[index], index: index)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.making.looks")
    }

    private func card(_ card: AutopilotDirectionCard, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            switch card {
            case let .arrived(direction):
                Text(direction.name).font(.callout.weight(.semibold)).lineLimit(1)
                if run.plan.makesScreenshots {
                    AutopilotDirectionThumbnails(studio: studio, direction: direction, width: 40) { slot in
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
        .modifier(GuidedSelectableCard(padding: 10))
        .accessibilityElement(children: card.isArrived ? .contain : .combine)
        .accessibilityIdentifier("autopilot.guided.making.look.\(index)")
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Spacing.small, style: .continuous)
            .fill(Palette.fill1)
            .frame(height: 96)
    }
}
