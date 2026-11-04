//
//  AutopilotRun+StoreNames.swift
//  AppLocalizer
//

import Foundation

/// The app's name in each language, as the artwork writes it: the App
/// Store page's name there ("Alba: Motivação diária"), never the primary
/// language's in every image.
extension AutopilotRun {
    /// The name in `locale`'s App Store page, else the primary language's,
    /// else `fallback` (the account's name) before the page was read.
    func appName(in locale: String, fallback: String) -> String {
        let names = storeNames ?? [:]
        for code in [locale, plan.primaryLocale] {
            let name = names[code]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !name.isEmpty { return name }
        }
        return fallback
    }

    /// `names` without the blank ones, trimmed.
    static func storeNames(_ names: [String: String]) -> [String: String] {
        names.compactMapValues { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}
