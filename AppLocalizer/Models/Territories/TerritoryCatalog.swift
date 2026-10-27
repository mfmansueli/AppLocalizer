//
//  TerritoryCatalog.swift
//  AppLocalizer
//

import Foundation

/// The App Store's 175 territories, in a stable order (by region, then as
/// App Store Connect lists them), with lookup by alpha-2 or alpha-3 code.
struct TerritoryCatalog: Sendable {
    /// All 175 territories from `TerritoryCatalog.table`.
    static let standard = TerritoryCatalog(
        territories: table.split(separator: "\n").compactMap { Territory(tableRow: $0) }
    )

    let territories: [Territory]
    private let byAlpha3: [String: Territory]
    private let byAlpha2: [String: Territory]

    init(territories: [Territory]) {
        self.territories = territories
        byAlpha3 = Dictionary(territories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        byAlpha2 = Dictionary(territories.map { ($0.alpha2, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var count: Int { territories.count }

    /// Looks up App Store Connect's ID, e.g. `BRA`.
    func territory(alpha3: String) -> Territory? {
        byAlpha3[alpha3.uppercased()]
    }

    func territory(alpha2: String) -> Territory? {
        byAlpha2[alpha2.uppercased()]
    }

    /// Either code, in any case: `br`, `BR` and `bra` all find Brazil.
    func territory(code: String) -> Territory? {
        let code = code.trimmingCharacters(in: .whitespaces)
        switch code.count {
        case 2: return territory(alpha2: code)
        case 3: return territory(alpha3: code)
        default: return nil
        }
    }

    func territories(in region: TerritoryRegion) -> [Territory] {
        territories.filter { $0.region == region }
    }
}
