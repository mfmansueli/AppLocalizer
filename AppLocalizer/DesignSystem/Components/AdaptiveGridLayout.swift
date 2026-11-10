//
//  AdaptiveGridLayout.swift
//  AppLocalizer
//

import SwiftUI

/// Cards in as many equal columns as fit at `minimumWidth` each, rows as
/// tall as their tallest card: a `LazyVGrid` with an adaptive column, except
/// every card is made at once, so the ones below the fold are there for
/// VoiceOver and UI tests. For a handful of cards, not long lists.
struct AdaptiveGridLayout: Layout {
    var minimumWidth: CGFloat
    var spacing: CGFloat

    /// How many columns of at least `minimumWidth` fit in `width`; one at
    /// least.
    static func columnCount(width: CGFloat, minimumWidth: CGFloat, spacing: CGFloat) -> Int {
        guard minimumWidth + spacing > 0 else { return 1 }
        return max(1, Int(((width + spacing) / (minimumWidth + spacing)).rounded(.down)))
    }

    /// Each column's share of `width`.
    static func columnWidth(width: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
        let columns = max(columns, 1)
        return max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout Void) -> CGSize {
        let width = proposal.width ?? minimumWidth
        let heights = rowHeights(width: width, subviews: subviews)
        let height = heights.reduce(0, +) + spacing * CGFloat(max(heights.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        let columns = Self.columnCount(width: bounds.width, minimumWidth: minimumWidth, spacing: spacing)
        let column = Self.columnWidth(width: bounds.width, columns: columns, spacing: spacing)
        let heights = rowHeights(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for (row, height) in heights.enumerated() {
            for index in row * columns..<min((row + 1) * columns, subviews.count) {
                let x = bounds.minX + CGFloat(index - row * columns) * (column + spacing)
                subviews[index].place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: column, height: nil))
            }
            y += height + spacing
        }
    }

    private func rowHeights(width: CGFloat, subviews: Subviews) -> [CGFloat] {
        let columns = Self.columnCount(width: width, minimumWidth: minimumWidth, spacing: spacing)
        let column = Self.columnWidth(width: width, columns: columns, spacing: spacing)
        return stride(from: 0, to: subviews.count, by: columns).map { start in
            subviews[start..<min(start + columns, subviews.count)]
                .map { $0.sizeThatFits(ProposedViewSize(width: column, height: nil)).height }
                .max() ?? 0
        }
    }
}
