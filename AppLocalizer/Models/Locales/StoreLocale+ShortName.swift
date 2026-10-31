//
//  StoreLocale+ShortName.swift
//  AppLocalizer
//

import Foundation

extension StoreLocale {
    /// The language without its region: "English (U.S.)" → "English".
    var shortName: String {
        guard let index = name.range(of: " (")?.lowerBound else { return name }
        return String(name[..<index])
    }
}
