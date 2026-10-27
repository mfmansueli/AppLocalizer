//
//  CaptureLocaleHint.swift
//  AppLocalizer
//

import Foundation

/// Finds the locale a name means: a folder (`de-DE`, `pt`), an Xcode test
/// configuration ("German", "de-DE") or a result bundle
/// (`Lumen-de-DE.xcresult`). Returns the code as written, so an ambiguous
/// one ("pt") still reaches the matcher, which asks.
enum CaptureLocaleHint {
    static func code(in name: String) -> String? {
        let base = name.hasSuffix(".xcresult") ? String(name.dropLast(".xcresult".count)) : name
        if StoreLocaleCatalog.resolve(base) != .unknown, base.count <= 10 { return base }
        if let locale = StoreLocaleCatalog.all.first(where: { $0.name.caseInsensitiveCompare(base) == .orderedSame }) {
            return locale.code
        }
        let tokens = base.split(whereSeparator: { "-_ .".contains($0) }).map(String.init)
        // Region pairs first ("de-DE", "zh-Hans"), then languages alone.
        for index in tokens.indices.dropLast() {
            let pair = "\(tokens[index])-\(tokens[index + 1])"
            if case .exact = StoreLocaleCatalog.resolve(pair) { return pair }
        }
        for token in tokens.reversed() where (2...3).contains(token.count) && token == token.lowercased() {
            if StoreLocaleCatalog.resolve(token) != .unknown { return token }
        }
        return nil
    }
}
