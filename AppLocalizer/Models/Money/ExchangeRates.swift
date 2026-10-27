//
//  ExchangeRates.swift
//  AppLocalizer
//

import Foundation

/// Market exchange rates as units of each currency per US dollar, for the
/// "USD equivalent" column and the tile map.
///
/// `approximate` holds the design prototype's illustrative rates, not live
/// quotes. App Store Connect doesn't publish exchange rates, so a live source
/// would have to come from elsewhere.
struct ExchangeRates: Hashable, Sendable {
    /// Units of the currency per US dollar, e.g. `"BRL": 5.5`.
    var unitsPerDollar: [String: Decimal]

    /// The prototype's illustrative rates (approximate, October 2026).
    static let approximate = ExchangeRates(unitsPerDollar: approximateRates.mapValues { Decimal(exactly: $0) })

    private static let approximateRates: [String: Double] = [
        "USD": 1,
        "CAD": 1.38,
        "MXN": 18.5,
        "BRL": 5.5,
        "CLP": 950,
        "COP": 4100,
        "PEN": 3.75,
        "EUR": 0.88,
        "GBP": 0.76,
        "CHF": 0.82,
        "NOK": 10.5,
        "SEK": 9.8,
        "DKK": 6.6,
        "PLN": 3.8,
        "CZK": 22,
        "HUF": 350,
        "RON": 4.4,
        "TRY": 42,
        "KZT": 520,
        "ILS": 3.5,
        "AED": 3.67,
        "SAR": 3.75,
        "QAR": 3.64,
        "EGP": 50,
        "ZAR": 18,
        "NGN": 1550,
        "TZS": 2600,
        "JPY": 150,
        "KRW": 1400,
        "CNY": 7.2,
        "HKD": 7.8,
        "TWD": 31,
        "SGD": 1.3,
        "MYR": 4.3,
        "THB": 33,
        "IDR": 16300,
        "VND": 26000,
        "PHP": 58,
        "INR": 87,
        "PKR": 282,
        "AUD": 1.53,
        "NZD": 1.7,
    ]

    /// `amount` in US dollars, or nil for an unknown currency.
    func dollars(_ amount: Decimal, currency code: String) -> Decimal? {
        guard let rate = unitsPerDollar[code.uppercased()], rate > 0 else { return nil }
        return amount / rate
    }
}
