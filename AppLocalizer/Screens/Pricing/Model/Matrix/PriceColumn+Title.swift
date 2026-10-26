//
//  PriceColumn+Title.swift
//  AppLocalizer
//

import Foundation

extension PriceColumn {
    /// The column's header, e.g. "Feels like".
    var title: String { Self.titles[self] ?? rawValue }

    private static let titles: [PriceColumn: String] = [
        .territory: String(localized: "Territory"),
        .region: String(localized: "Region"),
        .currency: String(localized: "Currency"),
        .current: String(localized: "Current"),
        .proceeds: String(localized: "Proceeds"),
        .dollars: String(localized: "USD equiv."),
        .equalized: String(localized: "Equalized"),
        .feelsLike: String(localized: "Feels like"),
        .suggested: String(localized: "Suggested"),
        .reason: String(localized: "Reason"),
        .factor: String(localized: "Factor"),
        .source: String(localized: "Source"),
        .proposed: String(localized: "Proposed"),
        .change: String(localized: "Change"),
        .status: String(localized: "Status"),
        .pricing: String(localized: "Pricing"),
    ]
}
