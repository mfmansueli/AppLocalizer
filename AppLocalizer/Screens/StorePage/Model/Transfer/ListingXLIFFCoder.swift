//
//  ListingXLIFFCoder.swift
//  AppLocalizer
//

import Foundation

/// XLIFF 1.2 for translation tools: the primary locale is the source, and
/// each other locale gets its own `<file>` with one `<trans-unit>` per
/// field (`id` is the field's API name). Units carry `maxwidth` and
/// `size-unit` so tools can enforce App Store limits, and `state` tells
/// translators what's missing (`needs-translation`) or machine-translated
/// (`needs-review-translation`).
///
/// Importing reads only `<target>` text: sources are never imported back,
/// so an old file can't revert the primary locale.
enum ListingXLIFFCoder {
    static let namespace = "urn:oasis:names:tc:xliff:document:1.2"

    static func encode(_ listing: StoreListing) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xliff xmlns="\(namespace)" version="1.2">

        """
        let original = escaped("\(listing.appName) \(listing.version.versionString)")
        for locale in listing.displayLocales where locale != listing.primaryLocale {
            xml += """
              <file original="\(original)" source-language="\(listing.primaryLocale.code)" \
            target-language="\(locale.code)" datatype="plaintext">
                <body>

            """
            for field in listing.fields {
                xml += unit(field, in: locale, of: listing)
            }
            xml += "    </body>\n  </file>\n"
        }
        return xml + "</xliff>\n"
    }

    static func decode(_ data: Data) throws -> ListingTransferDocument {
        let reader = Reader()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = reader
        guard parser.parse() else {
            throw ListingTransferError.unreadable(detail: parser.parserError?.localizedDescription)
        }
        return ListingTransferDocument(
            format: .xliff,
            appName: nil,
            version: nil,
            sourceLocaleCode: reader.sourceLanguage,
            entries: reader.entries
        )
    }

    /// One field's unit, or nothing when neither side has text.
    private static func unit(_ field: ListingField, in locale: StoreLocale, of listing: StoreListing) -> String {
        let source = listing.value(field, in: listing.primaryLocale)
        let draft = listing.draft(field, in: locale)
        guard !source.isEmpty || !draft.local.isEmpty else { return "" }
        var attributes = "id=\"\(field.rawValue)\" xml:space=\"preserve\""
        if let limit = field.limit {
            attributes += " maxwidth=\"\(limit.maximum)\" size-unit=\"\(limit.unit == .bytes ? "byte" : "char")\""
        }
        let state = draft.local.isEmpty ? "needs-translation" : draft.isMachineTranslated ? "needs-review-translation" : "translated"
        return """
              <trans-unit \(attributes)>
                <source>\(escaped(source))</source>
                <target state="\(state)">\(escaped(draft.local))</target>
                <note>\(escaped(field.translatorNote))</note>
              </trans-unit>

        """
    }

    /// Escapes markup characters, keeps carriage returns as `&#13;` so they
    /// survive XML line-end normalization, and drops characters XML 1.0
    /// doesn't allow.
    static func escaped(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "\r": result += "&#13;"
            case "\t", "\n": result.unicodeScalars.append(scalar)
            default:
                if scalar.value >= 0x20, scalar.value != 0xFFFE, scalar.value != 0xFFFF { result.unicodeScalars.append(scalar) }
            }
        }
        return result
    }

    /// Collects `<target>` text per file and unit.
    private final class Reader: NSObject, XMLParserDelegate {
        private(set) var entries: [ListingTransferEntry] = []
        private(set) var sourceLanguage: String?
        private var targetLanguage = ""
        private var unitID: String?
        private var target: String?
        private var capturedText: String?

        func parser(
            _: XMLParser,
            didStartElement elementName: String,
            namespaceURI _: String?,
            qualifiedName _: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            switch elementName {
            case "file":
                targetLanguage = attributeDict["target-language"] ?? ""
                sourceLanguage = sourceLanguage ?? attributeDict["source-language"]
            case "trans-unit":
                unitID = attributeDict["id"] ?? attributeDict["resname"]
                target = nil
            case "target" where unitID != nil:
                capturedText = ""
            default:
                break
            }
        }

        func parser(_: XMLParser, foundCharacters string: String) {
            capturedText?.append(string)
        }

        func parser(_: XMLParser, foundCDATA block: Data) {
            capturedText?.append(String(bytes: block, encoding: .utf8) ?? "")
        }

        func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
            switch elementName {
            case "target":
                target = capturedText
                capturedText = nil
            case "trans-unit":
                if let unitID, let target {
                    entries.append(ListingTransferEntry(localeCode: targetLanguage, fieldName: unitID, value: target))
                }
                unitID = nil
                target = nil
            default:
                break
            }
        }
    }
}
