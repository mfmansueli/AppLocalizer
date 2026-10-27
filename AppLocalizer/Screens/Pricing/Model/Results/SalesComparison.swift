//
//  SalesComparison.swift
//  AppLocalizer
//

import Foundation

/// One territory's sales in the 28 days before a price change and the 28
/// days after it.
struct SalesComparison: Hashable, Sendable {
    var before: SalesWindow
    var after: SalesWindow
}
