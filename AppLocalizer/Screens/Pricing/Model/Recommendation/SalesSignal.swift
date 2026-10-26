//
//  SalesSignal.swift
//  AppLocalizer
//

import Foundation

/// A territory's last 28 days from App Analytics and Sales and Trends.
struct SalesSignal: Hashable, Sendable, Codable {
    var pageViews: Int
    /// Subscription starts.
    var starts: Int

    /// Page view → start conversion, or nil without views.
    var conversion: Double? {
        pageViews > 0 ? Double(starts) / Double(pageViews) : nil
    }
}
