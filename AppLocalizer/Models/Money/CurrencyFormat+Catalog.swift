//
//  CurrencyFormat+Catalog.swift
//  AppLocalizer
//

import Foundation

extension CurrencyFormat {
    /// US dollars, for base prices and "feels like" values: `$39.99`, `$80`.
    static let usd = CurrencyFormat(code: "USD", prefix: "$", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: ".")

    /// The currencies App Store territories charge in, as the App Store writes them.
    static let all: [CurrencyFormat] = [
        CurrencyFormat(code: "USD", prefix: "$", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "CAD", prefix: "CA$ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "MXN", prefix: "MX$ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "BRL", prefix: "R$ ", suffix: "", decimals: 2, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "CLP", prefix: "CLP ", suffix: "", decimals: 0, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "COP", prefix: "COP ", suffix: "", decimals: 0, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "PEN", prefix: "S/ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "EUR", prefix: "", suffix: " €", decimals: 2, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "GBP", prefix: "£", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "CHF", prefix: "CHF ", suffix: "", decimals: 2, groupingSeparator: "’", decimalSeparator: "."),
        CurrencyFormat(code: "NOK", prefix: "", suffix: " kr", decimals: 2, groupingSeparator: " ", decimalSeparator: ","),
        CurrencyFormat(code: "SEK", prefix: "", suffix: " kr", decimals: 2, groupingSeparator: " ", decimalSeparator: ","),
        CurrencyFormat(code: "DKK", prefix: "", suffix: " kr.", decimals: 2, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "PLN", prefix: "", suffix: " zł", decimals: 2, groupingSeparator: " ", decimalSeparator: ","),
        CurrencyFormat(code: "CZK", prefix: "", suffix: " Kč", decimals: 0, groupingSeparator: " ", decimalSeparator: ","),
        CurrencyFormat(code: "HUF", prefix: "", suffix: " Ft", decimals: 0, groupingSeparator: " ", decimalSeparator: ","),
        CurrencyFormat(code: "RON", prefix: "", suffix: " lei", decimals: 2, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "TRY", prefix: "₺", suffix: "", decimals: 2, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "KZT", prefix: "", suffix: " ₸", decimals: 0, groupingSeparator: " ", decimalSeparator: ","),
        CurrencyFormat(code: "ILS", prefix: "₪", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "AED", prefix: "AED ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "SAR", prefix: "SAR ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "QAR", prefix: "QAR ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "EGP", prefix: "EGP ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "ZAR", prefix: "R ", suffix: "", decimals: 2, groupingSeparator: " ", decimalSeparator: "."),
        CurrencyFormat(code: "NGN", prefix: "₦", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "TZS", prefix: "TSh ", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "JPY", prefix: "¥", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "KRW", prefix: "₩", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "CNY", prefix: "CN¥", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "HKD", prefix: "HK$ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "TWD", prefix: "NT$ ", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "SGD", prefix: "S$ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "MYR", prefix: "RM ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "THB", prefix: "฿", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "IDR", prefix: "Rp ", suffix: "", decimals: 0, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "VND", prefix: "₫ ", suffix: "", decimals: 0, groupingSeparator: ".", decimalSeparator: ","),
        CurrencyFormat(code: "PHP", prefix: "₱", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "INR", prefix: "₹", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "PKR", prefix: "Rs ", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "AUD", prefix: "A$ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
        CurrencyFormat(code: "NZD", prefix: "NZ$ ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: "."),
    ]

    private static let byCode = Dictionary(all.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })

    /// The format for an ISO 4217 code. Unknown codes fall back to
    /// `CODE 1,234.56`, so nothing renders blank.
    static func forCurrency(_ code: String) -> CurrencyFormat {
        byCode[code.uppercased()]
            ?? CurrencyFormat(code: code, prefix: code + " ", suffix: "", decimals: 2, groupingSeparator: ",", decimalSeparator: ".")
    }

    /// Shorthand for `forCurrency(code).format(amount)`.
    static func format(_ amount: Decimal, currency code: String) -> String {
        forCurrency(code).format(amount)
    }
}
