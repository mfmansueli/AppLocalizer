//
//  TemplateEmphasis.swift
//  AppLocalizer
//

import Foundation

/// `caption.headline.emph`: one line of the headline styled differently,
/// after wrapping, so it follows each language's own line breaks. `first`
/// needs two or more lines; `last` also styles a one-line caption.
struct TemplateEmphasis: Codable, Hashable, Sendable {
    /// `on` in JSON.
    var line: Line
    /// CSS-style weight, 100–900; the headline's when left out.
    var weight: Int?
    /// Another font for the line, e.g. Archivo under Archivo Black. Used
    /// only where it draws every character; otherwise the line keeps the
    /// headline's font.
    var font: String?
    var italic: Bool?
    /// A color for the line; the caption's ink when left out.
    var color: String?

    enum Line: String, Codable, Hashable, Sendable, CaseIterable {
        case first
        case last
    }

    enum CodingKeys: String, CodingKey {
        case line = "on"
        case weight, font, italic, color
    }

    /// Whether line `index` of `count` wrapped lines is the emphasized one.
    func applies(toLine index: Int, of count: Int) -> Bool {
        switch line {
        case .first: index == 0 && count > 1
        case .last: index == count - 1
        }
    }
}
