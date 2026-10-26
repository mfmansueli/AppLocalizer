//
//  SalesWindow.swift
//  AppLocalizer
//

import Foundation

/// One territory's 28 days on one side of a price change.
struct SalesWindow: Hashable, Sendable {
    var pageViews: Int
    var starts: Int
    /// After commission and tax, in US dollars.
    var proceeds: Decimal

    /// Page view → start conversion, or nil without views.
    var conversion: Double? {
        pageViews > 0 ? Double(starts) / Double(pageViews) : nil
    }

    /// "1.38%", or "—" without views.
    var conversionText: String {
        conversion.map { PricingText.percent($0) } ?? "—"
    }
}
