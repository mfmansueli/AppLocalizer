//
//  StudioViewer.swift
//  AppLocalizer
//

import Foundation

/// The full-size viewer over the app: the items it moves through
/// (a screenshot's neighbours, the header and search artwork, a
/// direction's set) and the one shown.
struct StudioViewer: Hashable {
    var items: [StudioViewerItem]
    var index: Int

    /// Nil without items.
    init?(items: [StudioViewerItem], index: Int = 0) {
        guard !items.isEmpty else { return nil }
        self.items = items
        self.index = min(max(index, 0), items.count - 1)
    }

    var current: StudioViewerItem { items[index] }
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
