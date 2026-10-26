//
//  Territory.swift
//  AppLocalizer
//

import Foundation

/// An App Store territory: where a price applies, in which currency, and with
/// how much tax inside the customer price.
struct Territory: Identifiable, Hashable, Sendable {
    /// App Store Connect's territory ID: ISO 3166-1 alpha-3, e.g. `BRA`
    /// (Kosovo, which has no ISO code, is `XKS`).
    var id: String
    /// ISO 3166-1 alpha-2, e.g. `BR`. Also drives the flag.
    var alpha2: String
    /// English name, e.g. "Brazil".
    var name: String
    var region: TerritoryRegion
    /// ISO 4217 code of the currency the App Store charges in, e.g. `BRL`.
    var currencyCode: String
    /// Sales tax or VAT included in the customer price, as a fraction
    /// (0.19 = 19%). Proceeds are taken after it.
    var taxRate: Decimal
    /// Rough position, for the tile map.
    var latitude: Double
    var longitude: Double

    /// The regional-indicator flag, e.g. 🇧🇷.
    var flag: String {
        let base: UInt32 = 0x1F1E6 - 0x41
        let scalars = alpha2.uppercased().unicodeScalars.compactMap { Unicode.Scalar(base + $0.value) }
        return String(String.UnicodeScalarView(scalars))
    }

    /// The short name used in reason lines, e.g. "the US price".
    var referenceName: String {
        switch alpha2 {
        case "GB": "UK"
        default: alpha2
        }
    }
}
