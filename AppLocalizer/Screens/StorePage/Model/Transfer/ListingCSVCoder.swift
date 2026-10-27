//
//  ListingCSVCoder.swift
//  AppLocalizer
//

import Foundation

/// CSV for spreadsheets: a header row `field,limit,en-US,de-DE,…`, then one
/// row per field with each locale's text. RFC 4180 quoting, so commas,
/// quotes and line breaks survive; CRLF rows and a UTF-8 byte order mark so
/// Excel opens accents and CJK correctly.
enum ListingCSVCoder {
    static let fieldColumn = "field"
    static let limitColumn = "limit"

    static func encode(_ listing: StoreListing) -> String {
        let locales = listing.displayLocales
        var rows = [[fieldColumn, limitColumn] + locales.map(\.code)]
        for field in listing.fields {
            rows.append([field.rawValue, field.limitDescription] + locales.map { listing.value(field, in: $0) })
        }
        return "\u{FEFF}" + rows.map { $0.map(quoted).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    /// Reads the field column and every locale column; other columns named
    /// "limit" are ignored. Any column order works.
    static func decode(_ text: String) throws -> ListingTransferDocument {
        var scalars = text.unicodeScalars[...]
        if scalars.first == "\u{FEFF}" { scalars = scalars.dropFirst() }
        let rows = rows(in: String(scalars))
        guard let header = rows.first,
              let fieldIndex = header.firstIndex(where: { normalized($0) == fieldColumn })
        else { throw ListingTransferError.missingFieldColumn }
        let localeColumns = header.indices.filter { index in
            index != fieldIndex && !normalized(header[index]).isEmpty && normalized(header[index]) != limitColumn
        }
        var entries: [ListingTransferEntry] = []
        for row in rows.dropFirst() where row.indices.contains(fieldIndex) {
            let fieldName = row[fieldIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fieldName.isEmpty else { continue }
            for column in localeColumns {
                let value = row.indices.contains(column) ? row[column] : ""
                entries.append(ListingTransferEntry(localeCode: header[column].trimmingCharacters(in: .whitespaces), fieldName: fieldName, value: value))
            }
        }
        return ListingTransferDocument(format: .csv, entries: entries)
    }

    /// Quotes a cell when it has a comma, quote, line break or edge spaces.
    static func quoted(_ cell: String) -> String {
        let needsQuotes = cell.contains { $0 == "," || $0 == "\"" || $0.isNewline }
            || cell.first?.isWhitespace == true || cell.last?.isWhitespace == true
        guard needsQuotes else { return cell }
        return "\"" + cell.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Splits CSV text into rows of cells. Line breaks inside quotes are
    /// part of the cell; blank lines are skipped.
    static func rows(in text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var cell = ""
        var isQuoted = false
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            index = text.index(after: index)
            if isQuoted {
                guard character == "\"" else {
                    cell.append(character)
                    continue
                }
                if index < text.endIndex, text[index] == "\"" {
                    cell.append("\"")
                    index = text.index(after: index)
                } else {
                    isQuoted = false
                }
            } else if character == "\"" {
                isQuoted = true
            } else if character == "," {
                row.append(cell)
                cell = ""
            } else if character.isNewline {
                row.append(cell)
                rows.append(row)
                row = []
                cell = ""
            } else {
                cell.append(character)
            }
        }
        if !cell.isEmpty || !row.isEmpty {
            row.append(cell)
            rows.append(row)
        }
        return rows.filter { $0.contains { !$0.isEmpty } }
    }

    private static func normalized(_ header: String) -> String {
        header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
