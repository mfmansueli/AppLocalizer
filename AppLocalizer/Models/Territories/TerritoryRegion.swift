//
//  TerritoryRegion.swift
//  AppLocalizer
//

import Foundation

/// The four regions the pricing table filters by. Central Asia and the
/// Caucasus count as Europe, as in App Store Connect's own grouping.
enum TerritoryRegion: String, CaseIterable, Codable, Hashable, Sendable {
    case americas
    case europe
    case asiaPacific
    case africaMiddleEast

    /// The filter chip's title, e.g. "Asia Pacific".
    var title: String {
        switch self {
        case .americas: "Americas"
        case .europe: "Europe"
        case .asiaPacific: "Asia Pacific"
        case .africaMiddleEast: "Africa & Middle East"
        }
    }

    /// The one-letter code `TerritoryCatalog.table` uses: A, E, P or M.
    var code: String {
        switch self {
        case .americas: "A"
        case .europe: "E"
        case .asiaPacific: "P"
        case .africaMiddleEast: "M"
        }
    }

    init?(code: String) {
        guard let region = Self.allCases.first(where: { $0.code == code }) else { return nil }
        self = region
    }
}
