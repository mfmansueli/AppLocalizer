//
//  CustomIndexCSV.swift
//  AppLocalizer
//

import Foundation

/// Reads a custom index: one territory per line, its code then a value.
///
/// - Codes: alpha-2 or alpha-3 (`BR`, `bra`), any case. Unknown codes are
///   listed as unmatched, with a suggestion for common mistakes (`UK` → GB,
///   `EL` → GR).
/// - Separators: comma, semicolon or tab, decided by the first line. With
///   semicolons or tabs a decimal comma (`0,55`) is accepted.
/// - Blank lines and lines starting with `#` are skipped. A first line whose
///   value isn't a number is a header.
/// - Values are factors (price level ÷ the base territory's), unless the
///   header's value column mentions "price" or "reference". Reference prices
///   are local prices of a comparable product: factor = local price ÷ (base
///   territory's price × the territory's equalization multiplier), i.e. the
///   local price over what Apple's equalization would make of the base
///   price. They need a row for the base territory.
enum CustomIndexCSV {
    /// Common codes that aren't ISO 3166, and the alpha-2 they mean.
    static let aliases = ["UK": "GB", "EL": "GR", "KS": "XK", "KOS": "XK"]

    static func parse(
        _ text: String,
        catalog: TerritoryCatalog = .standard,
        baseTerritoryID: String = "USA",
        equalizationMultiplier: (Territory) -> Decimal? = { _ in nil }
    ) -> CustomIndexImport {
        let lines = text.components(separatedBy: .newlines).enumerated().map { (number: $0.offset + 1, text: $0.element) }
        let content = lines.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty && !$0.text.hasPrefix("#") }
        guard let first = content.first else {
            return CustomIndexImport(kind: .factor, rows: [], unmatched: [], errors: [.init(line: 0, message: "The file is empty.")])
        }
        let separator = separator(for: first.text)
        let header = fields(first.text, separator: separator)
        let hasHeader = header.count < 2 || number(header[1]) == nil
        let kind: CustomIndexImport.ValueKind = hasHeader && header.count > 1 && mentionsPrice(header[1]) ? .referencePrice : .factor
        var reader = Reader(catalog: catalog)
        for line in content.dropFirst(hasHeader ? 1 : 0) {
            reader.read(line.text, number: line.number, separator: separator)
        }
        let result = CustomIndexImport(kind: .factor, rows: reader.rows, unmatched: reader.unmatched, errors: reader.errors)
        guard kind == .referencePrice else { return result }
        return referencePrices(result, catalog: catalog, baseTerritoryID: baseTerritoryID, equalizationMultiplier: equalizationMultiplier)
    }

    // MARK: - Private

    /// Collects rows, unmatched codes and errors line by line.
    private struct Reader {
        let catalog: TerritoryCatalog
        var rows: [CustomIndexImport.Row] = []
        var unmatched: [CustomIndexImport.UnmatchedCode] = []
        var errors: [CustomIndexImport.LineError] = []

        mutating func read(_ text: String, number line: Int, separator: Character) {
            let values = CustomIndexCSV.fields(text, separator: separator)
            guard values.count >= 2, !values[0].isEmpty else {
                errors.append(.init(line: line, message: "Line \(line) needs a territory code and a value."))
                return
            }
            let code = values[0]
            guard let territory = catalog.territory(code: code) else {
                let suggestion = CustomIndexCSV.aliases[code.uppercased()].flatMap { catalog.territory(alpha2: $0) }
                unmatched.append(.init(line: line, code: code, suggestion: suggestion))
                return
            }
            guard let value = CustomIndexCSV.number(values[1]), value > 0 else {
                errors.append(.init(line: line, message: "Line \(line): “\(values[1])” isn’t a positive number."))
                return
            }
            guard !rows.contains(where: { $0.territory.id == territory.id }) else {
                errors.append(.init(line: line, message: "Line \(line): \(territory.name) appears twice; the first value is kept."))
                return
            }
            rows.append(.init(line: line, code: code, territory: territory, value: value, factor: value))
        }
    }

    private static func referencePrices(
        _ parsed: CustomIndexImport,
        catalog: TerritoryCatalog,
        baseTerritoryID: String,
        equalizationMultiplier: (Territory) -> Decimal?
    ) -> CustomIndexImport {
        var result = parsed
        result.kind = .referencePrice
        guard let base = parsed.rows.first(where: { $0.territory.id == baseTerritoryID }) else {
            let name = catalog.territory(alpha3: baseTerritoryID)?.name ?? baseTerritoryID
            result.rows = []
            result.errors.insert(.init(line: 0, message: "Reference prices need a row for \(name), the base territory."), at: 0)
            return result
        }
        result.rows = parsed.rows.compactMap { row in
            if row.territory.id == baseTerritoryID { return withFactor(row, 1) }
            guard let multiplier = equalizationMultiplier(row.territory), multiplier > 0 else {
                result.errors.append(.init(line: row.line, message: "Line \(row.line): no equalized price to compare \(row.territory.name) with."))
                return nil
            }
            return withFactor(row, (row.value / (base.value * multiplier)).rounded(scale: 2))
        }
        return result
    }

    private static func withFactor(_ row: CustomIndexImport.Row, _ factor: Decimal) -> CustomIndexImport.Row {
        var row = row
        row.factor = factor
        return row
    }

    private static func separator(for line: String) -> Character {
        if line.contains("\t") { return "\t" }
        if line.contains(";") { return ";" }
        return ","
    }

    fileprivate static func fields(_ line: String, separator: Character) -> [String] {
        line.split(separator: separator, omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
    }

    fileprivate static func number(_ text: String) -> Decimal? {
        var text = text.replacingOccurrences(of: " ", with: "")
        if !text.contains("."), text.contains(",") { text = text.replacingOccurrences(of: ",", with: ".") }
        guard !text.isEmpty, text.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" }) else { return nil }
        return Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func mentionsPrice(_ header: String) -> Bool {
        let lower = header.lowercased()
        return lower.contains("price") || lower.contains("reference")
    }
}
