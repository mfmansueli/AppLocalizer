//
//  TileMapMetric.swift
//  AppLocalizer
//

import Foundation

/// What the tile map colors territories by.
enum TileMapMetric: String, CaseIterable, Hashable, Sendable, Identifiable {
    /// The price in US dollars against the base price: teal below, orange above.
    case percentVsBase
    /// The price in US dollars, lightest to darkest.
    case dollars
    /// What the price feels like locally against the base price.
    case feelsLike
    /// The strategy's index factor.
    case indexFactor

    var id: Self { self }

    var title: String {
        switch self {
        case .percentVsBase: String(localized: "% vs base")
        case .dollars: String(localized: "USD equivalent")
        case .feelsLike: String(localized: "Feels like")
        case .indexFactor: String(localized: "Index factor")
        }
    }

    /// Diverging metrics go both ways from the base price (teal and
    /// orange); the others run along one scale (the accent).
    var isDiverging: Bool {
        switch self {
        case .percentVsBase, .feelsLike: true
        case .dollars, .indexFactor: false
        }
    }
}
