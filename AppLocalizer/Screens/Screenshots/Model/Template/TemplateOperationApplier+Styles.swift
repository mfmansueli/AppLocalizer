//
//  TemplateOperationApplier+Styles.swift
//  AppLocalizer
//

import Foundation

// The checks for the fields that take an object or a list: the device's
// angle, the emphasized line, highlight bars, shadows, decorations and a
// slot's own background. Each refusal names the field to fix.
extension TemplateOperationApplier {
    /// The most decorations one slot (or the template) may have.
    static let maximumDecorations = 12

    /// A number field of an object, with what it accepts.
    private struct NumberField {
        let name: String
        let value: Double?
        let range: ClosedRange<Double>
        var unit = ""
    }

    func checkStyle(_ value: JSONValue, against rule: TemplateFieldRule, path: String) -> TemplateRefusal? {
        switch rule {
        case .tilt: checkTilt(value, path: path)
        case .emphasis: checkEmphasis(value, path: path)
        case .highlight: checkHighlight(value, path: path)
        case .shadow: checkShadow(value, path: path)
        case .decorations: checkDecorations(value, path: path)
        case .background: checkBackground(value, path: path)
        default: nil
        }
    }

    func checkTilt(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard value.objectValue != nil, let tilt = Self.decode(TemplateTilt.self, from: value) else {
            return wrongType(path, String(localized: "an object like {\"rz\": 5, \"ry\": -16, \"rx\": 6}, in degrees"))
        }
        return checkNumbers([
            NumberField(name: "rz", value: tilt.rotate, range: TemplateTilt.schemaRotateRange, unit: "°"),
            NumberField(name: "ry", value: tilt.turn, range: TemplateTilt.schemaTurnRange, unit: "°"),
            NumberField(name: "rx", value: tilt.lean, range: TemplateTilt.schemaLeanRange, unit: "°"),
        ], path: path)
    }

    func checkEmphasis(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let emphasis = Self.decode(TemplateEmphasis.self, from: value) else {
            return wrongType(path, String(localized: "an object like {\"on\": \"last\", \"weight\": 800}; on is first or last"))
        }
        if let weight = emphasis.weight, let refusal = checkInteger(.int(weight), range: 100...900, path: "\(path).weight") { return refusal }
        if let font = emphasis.font, let refusal = checkFont(.string(font), path: "\(path).font") { return refusal }
        if let color = emphasis.color, TemplateColor(color) == nil { return wrongColor("\(path).color") }
        return nil
    }

    func checkHighlight(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let mark = Self.decode(TemplateHighlight.self, from: value) else {
            return wrongType(path, String(localized: "an object like {\"color\": \"#CFAEFF\", \"pad\": 0.2, \"rot\": -2}"))
        }
        if TemplateColor(mark.color) == nil { return wrongColor("\(path).color") }
        if let refusal = checkNumbers([
            NumberField(name: "pad", value: mark.padding, range: 0...1, unit: "em"),
            NumberField(name: "rot", value: mark.rotation, range: -15...15, unit: "°"),
            NumberField(name: "radius", value: mark.radius, range: 0...1, unit: "em"),
        ], path: path) { return refusal }
        if let shadow = mark.shadow, TemplateShadow(shadow) == nil { return wrongShadow("\(path).shadow") }
        return nil
    }

    func checkShadow(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let text = value.stringValue, TemplateShadow(text) != nil else { return wrongShadow(path) }
        return nil
    }

    func checkDecorations(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let items = value.arrayValue else {
            return wrongType(path, String(localized: "a list of decorations"))
        }
        guard items.count <= Self.maximumDecorations else {
            return outOfRange(path, "\(items.count)", range: "0 and \(Self.maximumDecorations) decorations")
        }
        for (index, item) in items.enumerated() {
            if let refusal = checkDecoration(item, path: "\(path).\(index)") { return refusal }
        }
        return nil
    }

    func checkBackground(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let background = Self.decode(TemplateBackground.self, from: value) else {
            return wrongType(path, String(localized: "a background like {\"kind\": \"solid\", \"stops\": [\"#2B2648\"]}"))
        }
        guard background.kind == .solid || background.kind == .linear else {
            return TemplateRefusal(path: "\(path).kind", kind: .outOfRange, reason: String(localized: "A slot’s own background is solid or linear; a panorama spans every slot."))
        }
        if let refusal = checkColors(.array(background.stops.map(JSONValue.string)), count: 1...6, path: "\(path).stops") { return refusal }
        if background.kind == .linear {
            guard let angle = background.angle else { return inconsistent("\(path).angle", String(localized: "A linear background needs an angle in degrees.")) }
            if let refusal = checkNumber(.double(angle), range: 0...360, unit: "°", path: "\(path).angle") { return refusal }
            if background.stops.count < 2 { return inconsistent("\(path).stops", String(localized: "A linear background needs at least two colors.")) }
        }
        return nil
    }

    // MARK: - One decoration

    private func checkDecoration(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let decoration = Self.decode(TemplateDecoration.self, from: value) else {
            let shapes = TemplateDecoration.Shape.allCases.map(\.rawValue).joined(separator: ", ")
            return wrongType(path, String(localized: "a decoration with type (shape, laurel or badge), x, y, w, color and z (back or front); shapes are \(shapes)"))
        }
        if decoration.type == .shape, decoration.shape == nil {
            let shapes = TemplateDecoration.Shape.allCases.map(\.rawValue).joined(separator: ", ")
            return TemplateRefusal(path: "\(path).shape", kind: .wrongType, reason: String(localized: "A shape decoration names its shape: \(shapes)."))
        }
        if let refusal = checkNumbers([
            NumberField(name: "x", value: decoration.x, range: -0.5...1.5), NumberField(name: "y", value: decoration.y, range: -0.5...1.5),
            NumberField(name: "w", value: decoration.width, range: 0.02...1.6), NumberField(name: "h", value: decoration.height, range: 0.02...1.6),
            NumberField(name: "rot", value: decoration.rotation, range: -180...180, unit: "°"),
            NumberField(name: "op", value: decoration.opacity, range: 0...1),
        ], path: path) { return refusal }
        for (name, color) in [("color", decoration.color), ("ink", decoration.ink), ("star", decoration.star)] {
            if let color, TemplateColor(color) == nil { return wrongColor("\(path).\(name)") }
        }
        guard decoration.isRating else { return nil }
        let text = (decoration.value ?? "").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, text.count <= 8, text.rangeOfCharacter(from: .letters) == nil else {
            return TemplateRefusal(
                path: "\(path).value", kind: .wrongType,
                reason: String(localized: "A laurel or badge shows numbers and symbols only, up to 8, like 4.8 or 4.8 ★, so it never needs translating.")
            )
        }
        return nil
    }

    // MARK: - Helpers

    /// The first number out of its range, named `<path>.<field>`; fields
    /// left out pass.
    private func checkNumbers(_ fields: [NumberField], path: String) -> TemplateRefusal? {
        for field in fields {
            guard let number = field.value else { continue }
            if let refusal = checkNumber(.double(number), range: field.range, unit: field.unit, path: "\(path).\(field.name)") { return refusal }
        }
        return nil
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from value: JSONValue) -> Value? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func wrongColor(_ path: String) -> TemplateRefusal {
        wrongType(path, String(localized: "a color like #7A80FF or rgba(255,255,255,0.84)"))
    }

    private func wrongShadow(_ path: String) -> TemplateRefusal {
        wrongType(path, String(localized: "a shadow in em, like 0 0.05em 0 rgba(18,10,70,0.5)"))
    }
}
