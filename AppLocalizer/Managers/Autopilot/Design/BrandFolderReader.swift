//
//  BrandFolderReader.swift
//  AppLocalizer
//

import Foundation

/// Reads a brand folder: colors from `tokens.json` (any nesting; values
/// like "#5B5BD6", or `{ "value": "#5B5BD6" }`), the font files and an SVG
/// logo.
enum BrandFolderReader {
    static func summary(of folder: URL, now: Date = .now) throws -> DesignSourceSummary {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        var summary = DesignSourceSummary(title: String(localized: "\(folder.lastPathComponent) · brand folder"), readBy: "AppLocalizer")
        if let tokens = files.first(where: { $0.lastPathComponent.lowercased() == "tokens.json" }) {
            let data = try Data(contentsOf: tokens)
            summary.colors = colors(in: data)
        }
        let fonts = files.filter { ["ttf", "otf", "ttc"].contains($0.pathExtension.lowercased()) }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
        if !fonts.isEmpty { summary.typefaces = fonts.prefix(4).joined(separator: " · ") }
        if let logo = files.first(where: { $0.pathExtension.lowercased() == "svg" }) {
            summary.logo = logo.lastPathComponent
        }
        guard !summary.colors.isEmpty || summary.typefaces != nil || summary.logo != nil else {
            throw AutopilotError(String(localized: "No tokens.json, fonts or SVG logo in \(folder.lastPathComponent)."))
        }
        summary.updated = (try? folder.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? now
        return summary
    }

    /// Up to six named colors, in the file's order of keys (sorted for
    /// stability).
    static func colors(in data: Data) -> [DesignSwatch] {
        guard let object = try? JSONSerialization.jsonObject(with: data) else { return [] }
        var swatches: [DesignSwatch] = []
        collect(object, name: nil, into: &swatches)
        return Array(swatches.prefix(6))
    }

    private static func collect(_ value: Any, name: String?, into swatches: inout [DesignSwatch]) {
        if let text = value as? String, let name, isHex(text) {
            if !swatches.contains(where: { $0.name == name }) { swatches.append(DesignSwatch(name: name, hex: text.uppercased())) }
        } else if let dictionary = value as? [String: Any] {
            if let inner = dictionary["value"] ?? dictionary["$value"], let name {
                collect(inner, name: name, into: &swatches)
                return
            }
            for key in dictionary.keys.sorted() {
                collect(dictionary[key] as Any, name: key.capitalized, into: &swatches)
            }
        }
    }

    private static func isHex(_ text: String) -> Bool {
        let body = text.hasPrefix("#") ? text.dropFirst() : Substring(text)
        return text.hasPrefix("#") && (body.count == 6 || body.count == 8) && body.allSatisfy(\.isHexDigit)
    }
}
