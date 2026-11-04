//
//  ExtrasPushFailureGroup.swift
//  AppLocalizer
//

import Foundation

/// Items of a push that failed for the same reason, listed once under the
/// cards: "9 failed · Couldn’t place it (…)", then which ones.
struct ExtrasPushFailureGroup: Hashable, Identifiable {
    var reason: String
    var items: [ExtrasPushItem]

    var id: String { reason }

    /// "English (U.S.) · Header 21:9, English (U.K.) · Header 21:9 and 2
    /// more"; every title when there are three or fewer.
    var itemsTitle: String {
        let titles = items.map(\.title)
        guard titles.count > 3 else { return titles.formatted(.list(type: .and)) }
        return String(localized: "\(titles.prefix(2).joined(separator: ", ")) and \(titles.count - 2) more")
    }
}
