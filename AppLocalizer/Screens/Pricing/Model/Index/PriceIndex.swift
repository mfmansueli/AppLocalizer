//
//  PriceIndex.swift
//  AppLocalizer
//

import Foundation

/// One source's price levels for the territories it covers.
struct PriceIndex: Hashable, Sendable {
    var source: PriceIndexSource
    var edition: PriceIndexEdition
    /// Price level per territory (alpha-3 ID), relative to the snapshot's
    /// reference territory (the United States = 1.0). Missing = no data.
    var levels: [String: Decimal]
    /// For a custom index, the imported file's name, shown as its publisher.
    var fileName: String?

    var publisher: String { fileName ?? source.publisher }

    /// How many territories have a value.
    var coverage: Int { levels.count }

    func level(for territoryID: String) -> Decimal? {
        levels[territoryID]
    }

    /// "74 of 175 territories".
    func coverageLabel(of total: Int) -> String {
        "\(coverage) of \(total) territories"
    }
}
