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

    /// Up to `maximum` of `codes`, primary first.
    static func pick(from codes: [String], primary: String) -> [String] {
        var picked = codes.contains(primary) ? [primary] : []
        for group in groups {
            guard picked.count < maximum else { break }
            if let code = codes.first(where: { !picked.contains($0) && group.contains(language(of: $0)) }) {
                picked.append(code)
            }
        }
        for code in codes where picked.count < maximum && !picked.contains(code) {
            picked.append(code)
        }
        return codes.filter(picked.contains).sorted { first, second in
            (first == primary ? 0 : 1, codes.firstIndex(of: first) ?? 0) < (second == primary ? 0 : 1, codes.firstIndex(of: second) ?? 0)
        }
    }

    /// "de" for "de-DE", "zh" for "zh-Hans".
    static func language(of code: String) -> String {
        String(code.split(separator: "-").first ?? Substring(code)).lowercased()
    }
}
