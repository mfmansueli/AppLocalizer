//
//  PricingSampleData+Tables.swift
//  AppLocalizer
//

import Foundation

// The design prototype's sample tables, keyed by alpha-2 code as there.
// Illustrative values, not real sales or rates.
extension PricingSampleData {
    /// Apple's equalization multiplier per currency (local units per US
    /// dollar, tax handling included), simulated.
    static let equalizationMultipliers: [String: Double] = [
        "USD": 1,
        "CAD": 1.4,
        "MXN": 18.5,
        "BRL": 5.5,
        "CLP": 950,
        "COP": 4100,
        "PEN": 3.75,
        "EUR": 1,
        "GBP": 0.9,
        "CHF": 1,
        "NOK": 11,
        "SEK": 11,
        "DKK": 7,
        "PLN": 4,
        "CZK": 25,
        "HUF": 380,
        "RON": 4.9,
        "TRY": 40,
        "KZT": 520,
        "ILS": 3.8,
        "AED": 3.67,
        "SAR": 3.75,
        "QAR": 3.64,
        "EGP": 50,
        "ZAR": 18.5,
        "NGN": 1600,
        "TZS": 2700,
        "JPY": 150,
        "KRW": 1400,
        "CNY": 7.2,
        "HKD": 7.8,
        "TWD": 30,
        "SGD": 1.35,
        "MYR": 4.5,
        "THB": 34,
        "IDR": 16000,
        "VND": 25500,
        "PHP": 58,
        "INR": 85,
        "PKR": 280,
        "AUD": 1.55,
        "NZD": 1.7,
    ]

    /// Annual prices that differ from equalized today; every other price is
    /// equalized.
    static let customAnnualPrices: [String: Decimal] = [
        "MX": 549,
        "TR": Decimal(119_999) / 100,
        "IN": 2499,
    ]

    /// Product page views and subscription starts, last 28 days (Annual).
    static let sales: [String: SalesSignal] = [
        "US": .init(pageViews: 21400, starts: 512), "IN": .init(pageViews: 6200, starts: 19),
        "BR": .init(pageViews: 4800, starts: 31), "DE": .init(pageViews: 4600, starts: 92),
        "GB": .init(pageViews: 3900, starts: 88), "FR": .init(pageViews: 2800, starts: 51),
        "CA": .init(pageViews: 2600, starts: 61), "MX": .init(pageViews: 2100, starts: 22),
        "JP": .init(pageViews: 1900, starts: 37), "AU": .init(pageViews: 1800, starts: 44),
        "ES": .init(pageViews: 1700, starts: 27), "ID": .init(pageViews: 1600, starts: 6),
        "IT": .init(pageViews: 1500, starts: 21), "TR": .init(pageViews: 1200, starts: 7),
        "AR": .init(pageViews: 1100, starts: 5), "KR": .init(pageViews: 900, starts: 15),
        "NL": .init(pageViews: 900, starts: 21), "PL": .init(pageViews: 800, starts: 12),
        "PH": .init(pageViews: 700, starts: 4), "CO": .init(pageViews: 650, starts: 5),
        "SE": .init(pageViews: 600, starts: 14), "CH": .init(pageViews: 500, starts: 16),
        "ZA": .init(pageViews: 500, starts: 6), "CL": .init(pageViews: 420, starts: 4),
        "EG": .init(pageViews: 400, starts: 1), "PT": .init(pageViews: 380, starts: 5),
        "VN": .init(pageViews: 300, starts: 1),
    ]

    /// Existing subscribers, for the schedule sheet's consent warnings.
    static let subscribers: [String: Int] = [
        "US": 2140, "GB": 380, "DE": 410, "FR": 220, "CA": 250, "AU": 190, "JP": 160, "CH": 41,
        "NO": 28, "DK": 22, "SE": 57, "IS": 3, "LU": 6, "BM": 2, "IL": 24, "KY": 1,
        "BB": 2, "BS": 3, "NL": 64, "IE": 31, "FI": 18, "AT": 27, "BE": 33,
    ]

    /// Starts multiplier four weeks after the push, per territory.
    static let resultMultipliers: [String: Double] = [
        "BR": 2.2, "IN": 4.2, "ID": 2.1, "TR": 0.86, "MX": 1.12, "PH": 1.6, "CO": 2.6, "AR": 1.3, "EG": 2,
        "VN": 1.5, "ZA": 1.3, "PL": 2.1, "CL": 1.9, "DE": 1.06, "FR": 1.05, "ES": 1.25, "IT": 1.4, "KR": 1.6,
        "JP": 0.92, "PT": 1.2, "CA": 1.1, "AU": 1.05, "GB": 1.08, "NL": 1.02, "SE": 0.95, "CH": 1,
    ]

    /// The custom index's factors ("Regional reference prices.csv").
    static let customFactors: [String: Double] = [
        "BR": 0.55, "MX": 0.7, "AR": 0.5, "CO": 0.45, "CL": 0.6, "PE": 0.5,
        "IN": 0.3, "ID": 0.35, "PH": 0.4, "VN": 0.38, "TR": 0.45, "EG": 0.25,
    ]

    /// The custom index file as imported: 12 matches, plus UK and EL, which
    /// don't match.
    static let customIndexCSV = """
    code,factor
    BR,0.55
    MX,0.70
    AR,0.50
    CO,0.45
    CL,0.60
    PE,0.50
    IN,0.30
    ID,0.35
    PH,0.40
    VN,0.38
    TR,0.45
    EG,0.25
    UK,0.88
    EL,0.62
    """
}
