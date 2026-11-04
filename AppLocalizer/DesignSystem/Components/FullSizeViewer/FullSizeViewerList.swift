//
//  FullSizeViewerList.swift
//  AppLocalizer
//

import Foundation

/// What a full-size viewer moves through (a screenshot's neighbours, the
/// header and search artwork, a set's slots) and the one shown.
struct FullSizeViewerList<Item: Hashable>: Hashable {
    var items: [Item]
    var index: Int

    /// Nil without items.
    init?(items: [Item], index: Int = 0) {
        guard !items.isEmpty else { return nil }
        self.items = items
        self.index = min(max(index, 0), items.count - 1)
    }

    var current: Item { items[index] }
    var hasPrevious: Bool { index > 0 }
    var hasNext: Bool { index < items.count - 1 }

    /// "2 of 5"; nil for one item.
    var countTitle: String? {
        items.count > 1 ? String(localized: "\(index + 1) of \(items.count)") : nil
    }

    /// The previous (-1) or next (1) item; stays at either end.
    mutating func step(_ offset: Int) {
        index = min(max(index + offset, 0), items.count - 1)
    }
}
