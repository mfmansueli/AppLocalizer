//
//  ProjectLanguage.swift
//  AppLocalizer
//

import Foundation

/// A language the app's own strings are translated into (its string
/// catalogs, e.g. `Localizable.xcstrings`), as the assistant read it from
/// the Xcode project, with how much of it is translated.
struct ProjectLanguage: Codable, Hashable, Sendable, Identifiable {
    /// The catalog's code, e.g. `pl`, `pt-BR` or `zh-Hans`.
    var code: String
    /// Strings translated, e.g. 412.
    var translated: Int?
    /// Strings in the catalog, e.g. 418.
    var total: Int?
    /// e.g. "Right to left; tested in LumenUITests".
    var note: String?

    var id: String { code }

    /// The App Store locale it becomes: `pl` → Polish, `de` → German,
    /// `es` → Spanish (Spain), `en` → English (U.S.).
    var storeLocale: StoreLocale? {
        Self.storeLocale(for: code)
    }

    /// "412 of 418 strings (98%)", or "418 of 418 strings".
    var coverage: String? {
        guard let total, total > 0 else { return nil }
        let done = min(translated ?? total, total)
        if done == total { return String(localized: "\(done) of \(total) strings") }
        let percent = Int((Double(done) / Double(total) * 100).rounded(.down))
        return String(localized: "\(done) of \(total) strings (\(percent)%)")
    }

    /// "Localizable.xcstrings: 412 of 418 strings (98%) · Right to left".
    func evidence(source: String?) -> String {
        let head = [source, coverage].compactMap(\.self).joined(separator: ": ")
        return [head, note].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
    }

    /// A catalog code as an App Store locale. A bare language with several
    /// App Store locales picks the one named after the language itself
    /// (`es` → `es-ES`, `fr` → `fr-FR`, `pt` → `pt-PT`), and English is
    /// English (U.S.).
    static func storeLocale(for code: String) -> StoreLocale? {
        switch StoreLocaleCatalog.resolve(code) {
        case let .exact(locale), let .inferred(locale):
            return locale
        case let .ambiguous(candidates):
            let language = code.prefix { $0 != "-" && $0 != "_" }.lowercased()
            if language == "en" { return candidates.first { $0.code == "en-US" } ?? candidates.first }
            return candidates.first { $0.code.lowercased() == "\(language)-\(language)" } ?? candidates.first
        case .unknown:
            return nil
        }
    }
}
