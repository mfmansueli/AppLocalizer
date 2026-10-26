//
//  PriceIndexSnapshot+Loading.swift
//  AppLocalizer
//

import Foundation

extension PriceIndexSnapshot {
    /// `PriceIndexSnapshot.json` in `Screens/Pricing/Resources`.
    static let resourceName = "PriceIndexSnapshot"

    enum LoadingError: Error, Equatable {
        case missingResource
    }

    /// No index data at all: every territory falls back to equalized.
    static let empty = PriceIndexSnapshot(
        isApproximate: true,
        note: "",
        snapshotDate: .distantPast,
        referenceTerritoryID: "USA",
        indices: [:]
    )

    /// The snapshot bundled with the app.
    static func bundled(in bundle: Bundle = .main) throws -> PriceIndexSnapshot {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoadingError.missingResource
        }
        return try PriceIndexSnapshot(jsonData: Data(contentsOf: url))
    }

    /// Decodes the JSON format of `PriceIndexSnapshot.json`. Factors are read
    /// through their shortest decimal form, so 0.85 stays exactly 0.85.
    init(jsonData: Data) throws {
        let file = try JSONDecoder().decode(File.self, from: jsonData)
        var indices: [PriceIndexSource: PriceIndex] = [:]
        for (key, entry) in file.sources {
            guard let source = PriceIndexSource(rawValue: key) else { continue }
            var levels = entry.factors.mapValues { Decimal(exactly: $0) }
            for shared in entry.shared ?? [] {
                for territoryID in shared.territories {
                    levels[territoryID] = Decimal(exactly: shared.factor)
                }
            }
            indices[source] = PriceIndex(source: source, edition: entry.edition, levels: levels)
        }
        try self.init(
            isApproximate: file.approximate,
            note: file.note,
            snapshotDate: PriceIndexEdition.parseDay(file.snapshotDate),
            referenceTerritoryID: file.referenceTerritory,
            indices: indices
        )
    }

    private struct File: Decodable {
        var approximate: Bool
        var note: String
        var snapshotDate: String
        var referenceTerritory: String
        var sources: [String: Source]
    }

    private struct Source: Decodable {
        var edition: PriceIndexEdition
        var factors: [String: Double]
        /// One value shared by several territories, e.g. the Big Mac Index's
        /// single euro-area entry.
        var shared: [SharedEntry]?
    }

    private struct SharedEntry: Decodable {
        var name: String
        var factor: Double
        var territories: [String]
    }
}
