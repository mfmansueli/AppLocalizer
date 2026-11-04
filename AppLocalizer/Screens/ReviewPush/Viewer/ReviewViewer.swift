//
//  ReviewViewer.swift
//  AppLocalizer
//

import Foundation

/// Review & Push's full-size viewer: what it moves through (a set's slots,
/// a card's languages), the one shown, and for a screenshot which side,
/// live or new.
struct ReviewViewer: Hashable {
    var list: FullSizeViewerList<ReviewViewerItem>
    /// Kept while stepping, so ← → compare the new (or live) images in
    /// order; an item without a live side shows its one side.
    var side: ReviewViewerSide

    /// Nil without items.
    init?(items: [ReviewViewerItem], index: Int = 0, side: ReviewViewerSide = .new) {
        guard let list = FullSizeViewerList(items: items, index: index) else { return nil }
        self.list = list
        self.side = side
    }

    var current: ReviewViewerItem { list.current }

    /// The side shown: `side`, or new for an item with one side.
    var shownSide: ReviewViewerSide { current.comparesSides ? side : .new }

    var subtitle: String { current.subtitle(shownSide) }

    /// Changes with the item and the side, so the large image loads again.
    var contentID: String { "\(current.id).\(shownSide.rawValue)" }

    mutating func step(_ offset: Int) {
        list.step(offset)
    }

    /// Live Now or New, on a screenshot.
    mutating func show(_ side: ReviewViewerSide) {
        guard current.comparesSides else { return }
        self.side = side
    }

    /// ↑ ↓: the other side, on a screenshot.
    mutating func flipSide() {
        show(shownSide.other)
    }
}
