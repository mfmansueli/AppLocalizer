//
//  GuidedPreviewLocales.swift
//  AppLocalizer
//

import Foundation

/// The languages a guided preview offers side by side: the primary one,
/// then one that runs long (German), one in another script (Japanese) and
/// one that reads right to left (Arabic), when the run has them; the rest
/// go in a menu.
enum GuidedPreviewLocales {
    /// The most shown as segments.
    static let maximum = 4

    /// Long words, other scripts, right to left: the languages most likely
    /// to show a problem.
    private static let groups: [[String]] = [
        ["de", "fi", "nl", "ru", "pl", "hu", "el"],
        ["ja", "zh", "ko", "th", "hi", "vi"],
        ["ar", "he", "fa", "ur"],
    ]

    /// Up to `maximum` of `codes`: the primary one, then each group's
    /// first language the run has, in the group's order (German before
    /// Dutch, Japanese before Chinese, however `codes` is sorted), then
    /// the rest in `codes`' order.
    static func pick(from codes: [String], primary: String) -> [String] {
        var picked = codes.contains(primary) ? [primary] : []
        for group in groups {
            guard picked.count < maximum else { break }
            let code = group.lazy.compactMap { wanted in
                codes.first { !picked.contains($0) && language(of: $0) == wanted }
            }.first
            if let code { picked.append(code) }
        }
        for code in codes where picked.count < maximum && !picked.contains(code) {
            picked.append(code)
        }
        return picked
    }

    /// What a language switch says: "English", "German", "Japanese";
    /// the whole name ("Spanish (Mexico)") where two of `codes` would read
    /// the same.
    static func titles(_ codes: [String]) -> [String: String] {
        let names = codes.map { code in
            (code, StoreLocaleCatalog.locale(code: code)?.shortName ?? code, StoreLocaleCatalog.locale(code: code)?.name ?? code)
        }
        let repeated = Dictionary(grouping: names) { $0.1 }.filter { $0.value.count > 1 }.keys
        return Dictionary(uniqueKeysWithValues: names.map { code, short, full in (code, repeated.contains(short) ? full : short) })
    }

    /// One language's title among `codes`.
    static func title(of code: String, among codes: [String]) -> String {
        titles(codes.contains(code) ? codes : codes + [code])[code] ?? code
    }

    /// "de" for "de-DE", "zh" for "zh-Hans".
    static func language(of code: String) -> String {
        String(code.split(separator: "-").first ?? Substring(code)).lowercased()
    }
}
