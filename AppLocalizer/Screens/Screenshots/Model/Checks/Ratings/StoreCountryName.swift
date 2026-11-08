//
//  StoreCountryName.swift
//  AppLocalizer
//

import Foundation

/// A storefront's country as a sentence names it: "the United States",
/// "Germany".
enum StoreCountryName {
    /// Countries English writes with "the".
    private static let withArticle: Set = ["US", "GB", "NL", "AE", "PH", "DO", "CZ", "BS", "CF", "KM", "MV", "MH", "SB", "VA", "GM"]

    static func phrase(_ regionCode: String, locale: Locale = .current) -> String {
        let code = regionCode.uppercased()
        let name = locale.localizedString(forRegionCode: code) ?? code
        guard locale.language.languageCode == .english, withArticle.contains(code) else { return name }
        return "the " + name
    }
}
