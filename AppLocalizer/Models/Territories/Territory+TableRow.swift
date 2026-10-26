//
//  Territory+TableRow.swift
//  AppLocalizer
//

import Foundation

extension Territory {
    /// Parses one line of `TerritoryCatalog.table`:
    /// `alpha-3|alpha-2|name|region|currency|tax rate|latitude|longitude`.
    init?(tableRow: some StringProtocol) {
        let fields = tableRow.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard fields.count == 8,
              let region = TerritoryRegion(code: fields[3]),
              let taxRate = Decimal(string: fields[5], locale: Locale(identifier: "en_US_POSIX")),
              let latitude = Double(fields[6]),
              let longitude = Double(fields[7])
        else { return nil }
        self.init(
            id: fields[0],
            alpha2: fields[1],
            name: fields[2],
            region: region,
            currencyCode: fields[4],
            taxRate: taxRate,
            latitude: latitude,
            longitude: longitude
        )
    }
}
