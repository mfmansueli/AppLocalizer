//
//  SegmentBadgeLayout.swift
//  AppLocalizer
//

import CoreGraphics

/// Where badges go on a segmented control, which has no badges of its own
/// and doesn't say where its segments are. A badged segment's label gets
/// blank space after its title for the badge to sit in. Segments fit their
/// labels with the same padding, so the control's width gives each one's
/// place.
struct SegmentBadgeLayout {
    static let gap: CGFloat = 5
    /// No-break spaces: a trailing normal space may be trimmed when drawn.
    static let space = "\u{00A0}"

    let titles: [String]
    /// One per title; nil where there's no badge.
    let badgeWidths: [CGFloat?]
    /// How wide a label's text is in the control's font.
    let measure: (String) -> CGFloat

    /// What each segment should display: its title and any blank space.
    var labels: [String] {
        zip(titles, badgeWidths).map { title, width in
            guard let width else { return title }
            let spaces = Int(((Self.gap + width) / measure(Self.space)).rounded(.up))
            return title + String(repeating: Self.space, count: spaces)
        }
    }

    /// The horizontal center of the badge at `index` in a control
    /// `totalWidth` wide; nil without a badge.
    func badgeCenterX(at index: Int, totalWidth: CGFloat) -> CGFloat? {
        guard titles.indices.contains(index), let badgeWidth = badgeWidths[index] else { return nil }
        let widths = labels.map(measure)
        let padding = (totalWidth - widths.reduce(0, +)) / CGFloat(titles.count)
        let segmentStart = widths[..<index].reduce(0) { $0 + $1 + padding }
        return segmentStart + padding / 2 + measure(titles[index]) + Self.gap + badgeWidth / 2
    }
}
