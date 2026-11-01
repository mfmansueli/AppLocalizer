//
//  TemplateShadow.swift
//  AppLocalizer
//

import Foundation

/// A shadow as a template writes it, CSS-style: `x y [blur] color`, lengths
/// in em of the text's size so it scales with the caption, e.g.
/// "0 0.05em 0 rgba(18,10,70,0.5)" or "0.07em 0.07em 0 #4B10A8".
struct TemplateShadow: Hashable, Sendable {
    /// Right, in em.
    var x: Double
    /// Down, in em.
    var y: Double
    /// Blur radius, in em; 0 is a hard copy.
    var blur: Double
    var color: TemplateColor

    init(x: Double, y: Double, blur: Double, color: TemplateColor) {
        self.x = x
        self.y = y
        self.blur = blur
        self.color = color
    }

    /// Parses the template's text, or nil when it isn't a shadow in em.
    init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let colorText: String
        let rest: String
        if let start = trimmed.range(of: "rgb", options: .caseInsensitive), let end = trimmed[start.lowerBound...].firstIndex(of: ")") {
            colorText = String(trimmed[start.lowerBound...end])
            rest = String(trimmed[..<start.lowerBound]) + " " + String(trimmed[trimmed.index(after: end)...])
        } else if let hash = trimmed.split(separator: " ").first(where: { $0.hasPrefix("#") }) {
            colorText = String(hash)
            rest = trimmed.split(separator: " ").filter { $0 != hash }.joined(separator: " ")
        } else {
            return nil
        }
        guard let color = TemplateColor(colorText) else { return nil }
        let lengths = rest.split(separator: " ").map { Self.length(String($0)) }
        guard (2...3).contains(lengths.count), lengths.allSatisfy({ $0 != nil }) else { return nil }
        let values = lengths.compactMap(\.self)
        self.init(x: values[0], y: values[1], blur: values.count == 3 ? max(0, values[2]) : 0, color: color)
    }

    /// "0.05em" → 0.05; a bare 0 is fine, other units aren't.
    private static func length(_ text: String) -> Double? {
        if text.hasSuffix("em") { return Double(text.dropLast(2)) }
        guard let number = Double(text), number == 0 else { return nil }
        return 0
    }
}
