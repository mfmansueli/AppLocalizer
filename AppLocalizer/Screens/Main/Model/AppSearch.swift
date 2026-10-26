//
//  AppSearch.swift
//  AppLocalizer
//

import Foundation

/// The sidebar's search: every word typed has to appear in the app's name,
/// bundle ID or SKU, ignoring case and diacritics. Order is kept.
enum AppSearch {
    static func filter(_ apps: [StoreApp], matching query: String) -> [StoreApp] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return apps }
        return apps.filter { app in
            let haystack = [app.name, app.bundleID, app.sku ?? ""].joined(separator: " ")
            return words.allSatisfy { haystack.localizedStandardContains($0) }
        }
    }
}
