//
//  AutopilotDesignCardsLayout.swift
//  AppLocalizer
//

import SwiftUI

/// Design's direction cards side by side, each an equal share of the width
/// it's offered. It reports that width, never its cards': a card sized
/// for a wider page can't push the page past the sheet while the stage
/// measures it again (the cards size their thumbnails from that
/// measurement).
struct AutopilotDesignCardsLayout: Layout {
    var spacing: CGFloat = Spacing.medium
    /// Every card as tall as the tallest, the way an `HStack` that's fixed
    /// vertically has them.
    var equalHeights = false

    /// One card's share of `width`.
    static func cardWidth(in width: CGFloat, count: Int, spacing: CGFloat = Spacing.medium) -> CGFloat {
        let count = CGFloat(max(count, 1))
        return max(0, (width - spacing * (count - 1)) / count)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout Void) -> CGSize {
        let width = proposal.width ?? idealWidth(subviews)
        let card = Self.cardWidth(in: width, count: subviews.count, spacing: spacing)
        let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: card, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        let card = Self.cardWidth(in: bounds.width, count: subviews.count, spacing: spacing)
        let height = equalHeights ? bounds.height : nil
        for (index, subview) in subviews.enumerated() {
            let x = bounds.minX + CGFloat(index) * (card + spacing)
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(width: card, height: height))
        }
    }

    private func idealWidth(_ subviews: Subviews) -> CGFloat {
        let widths = subviews.map { $0.sizeThatFits(.unspecified).width }
        return widths.reduce(0, +) + spacing * CGFloat(max(subviews.count - 1, 0))
    }
}
