//
//  PricingDisplay.swift
//  AppLocalizer
//

import Foundation

/// How the Prices tab shows territories: the matrix, the tile map or the
/// histogram of distances from Apple's equalized price.
enum PricingDisplay: String, CaseIterable, Hashable, Sendable {
    case table
    case map
    case histogram

    var title: String {
        switch self {
        case .table: String(localized: "Table")
        case .map: String(localized: "Tile map")
        case .histogram: String(localized: "Histogram")
        }
    }

    var systemImage: String {
        switch self {
        case .table: "tablecells"
        case .map: "map"
        case .histogram: "chart.bar"
        }
    }
}
