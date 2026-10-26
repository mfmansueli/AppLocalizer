//
//  PriceProvenance.swift
//  AppLocalizer
//

import Foundation

/// Where a territory's factor came from: the provenance badge in each row
/// (filled for the chosen index, outlined when a fallback filled the gap).
struct PriceProvenance: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case index(PriceIndexSource)
        /// The chosen index's median in the territory's region.
        case regionMedian(PriceIndexSource)
        /// No data anywhere in the chain (or Apple equalization chosen).
        case equalized
        case regionalTier(TerritoryRegion)
        case excluded
    }

    var kind: Kind
    /// True when something other than the chosen index filled the factor.
    var isFallback: Bool
    /// The index edition, for `.index`.
    var edition: PriceIndexEdition?

    /// The row badge: "Big Mac Jan 26", "WB 2024", "Region median",
    /// "Equalized", "Region tier", "Excluded".
    var badge: String {
        switch kind {
        case let .index(source): edition?.badge ?? source.name
        case .regionMedian: "Region median"
        case .equalized: "Equalized"
        case .regionalTier: "Region tier"
        case .excluded: "Excluded"
        }
    }

    /// The source as breakdown lines name it: "World Bank 2024",
    /// "region median", "no data, equalized".
    var label: String {
        switch kind {
        case let .index(source): edition?.provenanceLabel ?? source.name
        case .regionMedian: "region median"
        case .equalized: "no data, equalized"
        case .regionalTier: "regional tier"
        case .excluded: "excluded"
        }
    }

    /// The index behind the factor, if any.
    var source: PriceIndexSource? {
        switch kind {
        case let .index(source), let .regionMedian(source): source
        default: nil
        }
    }
}
