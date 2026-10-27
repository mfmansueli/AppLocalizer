//
//  PriceEnding+Currencies.swift
//  AppLocalizer
//

import Foundation

extension PriceEnding {
    /// Each currency's usual ending ("Auto" rounding).
    static let preferredByCurrency: [String: PriceEnding] = [
        "USD": .ninetyNine,
        "CAD": .ninetyNine,
        "MXN": .nineAfterTwoDigits,
        "BRL": .ninety,
        "CLP": .nineAfterTwoDigits,
        "COP": .nineAfterThreeDigits,
        "PEN": .ninety,
        "EUR": .ninetyNine,
        "GBP": .ninetyNine,
        "CHF": .wholeUnits,
        "NOK": .nineAfterTwoDigits,
        "SEK": .nineAfterTwoDigits,
        "DKK": .nineAfterTwoDigits,
        "PLN": .ninetyNine,
        "CZK": .nineAfterTwoDigits,
        "HUF": .nineAfterThreeDigits,
        "RON": .ninetyNine,
        "TRY": .ninetyNine,
        "KZT": .nineAfterThreeDigits,
        "ILS": .ninety,
        "AED": .ninetyNine,
        "SAR": .ninetyNine,
        "QAR": .ninetyNine,
        "EGP": .ninetyNine,
        "ZAR": .ninetyNine,
        "NGN": .nineAfterTwoDigits,
        "TZS": .nineAfterTwoDigits,
        "JPY": .round,
        "KRW": .round,
        "CNY": .eight,
        "HKD": .eight,
        "TWD": .nineAfterTwoDigits,
        "SGD": .ninetyEight,
        "MYR": .ninety,
        "THB": .round,
        "IDR": .nineAfterTwoDigits,
        "VND": .nineAfterTwoDigits,
        "PHP": .nineAfterTwoDigits,
        "INR": .nineAfterThreeDigits,
        "PKR": .nineAfterTwoDigits,
        "AUD": .ninetyNine,
        "NZD": .ninetyNine,
    ]

    /// The usual ending for a currency. Unknown ones get .99, or round
    /// numbers when they have no decimals.
    static func preferred(forCurrency code: String) -> PriceEnding {
        preferredByCurrency[code.uppercased()]
            ?? (CurrencyFormat.forCurrency(code).decimals == 0 ? .round : .ninetyNine)
    }
}
