//
//  ListingJSONCoder.swift
//  AppLocalizer
//

import Foundation

/// JSON for scripts and AI tools:
///
/// ```json
/// { "app": "Lumen Journal", "version": "1.4", "sourceLocale": "en-US",
///   "locales": { "de-DE": { "name": "Lumen: Tagebuch", "subtitle": "…" } } }
/// ```
///
/// Every field of every locale is written, empty ones as "". Keys are
/// sorted so exports diff cleanly.
enum ListingJSONCoder {
    private struct Payload: Codable {
        var app: String?
        var version: String?
        var sourceLocale: String?
        var locales: [String: [String: String]]
    }

    static func encode(_ listing: StoreListing) -> Data {
        var locales: [String: [String: String]] = [:]
        for locale in listing.locales {
            locales[locale.code] = Dictionary(uniqueKeysWithValues: listing.fields.map { ($0.rawValue, listing.value($0, in: locale)) })
        }
        let payload = Payload(
            app: listing.appName,
            version: listing.version.versionString,
            sourceLocale: listing.primaryLocale.code,
            locales: locales
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(payload)) ?? Data()
    }

    /// Entries come out sorted by locale code, then in column order, since
    /// JSON objects have no order.
    static func decode(_ data: Data) throws -> ListingTransferDocument {
        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            throw ListingTransferError.unreadable(detail: error.localizedDescription)
        }
        let entries = payload.locales.keys.sorted().flatMap { code in
            (payload.locales[code] ?? [:]).sorted { order($0.key) < order($1.key) }.map { name, value in
                ListingTransferEntry(localeCode: code, fieldName: name, value: value)
            }
        }
        return ListingTransferDocument(
            format: .json,
            appName: payload.app,
            version: payload.version,
            sourceLocaleCode: payload.sourceLocale,
            entries: entries
        )
    }

    /// Known fields in column order, unknown names after them alphabetically.
    private static func order(_ name: String) -> String {
        guard let field = ListingField(transferName: name), let index = ListingField.allCases.firstIndex(of: field) else {
            return "z" + name
        }
        return "a\(index)"
    }
}
