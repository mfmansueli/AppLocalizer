//
//  ArtworkWebTextVersions.swift
//  AppLocalizer
//

import Foundation

/// Which of a `data-al="text"`'s versions a language shows: the child
/// whose `lang` is the locale's code ("pt-BR"), else its language part
/// ("pt"), case aside. `ArtworkWebScript.fill` picks the same way.
enum ArtworkWebTextVersions {
    /// One of `languages` is `locale`'s version.
    static func covers(_ languages: [String], locale: String) -> Bool {
        version(in: languages, for: locale) != nil
    }

    /// The `lang` of `locale`'s version among `languages`.
    static func version(in languages: [String], for locale: String) -> String? {
        let code = locale.lowercased()
        let language = code.split(separator: "-").first.map(String.init) ?? code
        let trimmed = languages.map { $0.trimmingCharacters(in: .whitespaces) }
        return trimmed.first { $0.lowercased() == code } ?? trimmed.first { $0.lowercased() == language }
    }
}
