//
//  TemplateOperationApplier.swift
//  AppLocalizer
//

import Foundation

/// Applies `replace` operations to a template, all or nothing. Every
/// operation is checked against `TemplateSchema` (known path, right type,
/// in range, an installed font, a fallback that can draw its script), then
/// the result is checked as a whole (`min` never above `size`, a linear
/// background has an angle and two stops). Refusals say what to change, so
/// an assistant can fix its proposal; the template editor uses the same
/// checks for its controls.
struct TemplateOperationApplier: Sendable {
    var fonts: ScreenshotFontCatalog = .standard

    /// The template with `operations` applied, or every reason it can't be.
    /// The version is left alone: saving makes the new one.
    func applying(_ operations: [TemplateOperation], to template: ScreenshotTemplate) -> Result<ScreenshotTemplate, TemplateRefusals> {
        var tree = template.json
        var refusals: [TemplateRefusal] = []
        for operation in operations {
            switch apply(operation, to: tree, slotCount: template.slots.count) {
            case let .success(updated): tree = updated
            case let .failure(refusal): refusals.append(refusal)
            }
        }
        guard refusals.isEmpty else { return .failure(TemplateRefusals(items: refusals)) }
        guard let result = try? ScreenshotTemplate(json: tree) else {
            return .failure(TemplateRefusals(items: [
                TemplateRefusal(path: "", kind: .wrongType, reason: String(localized: "The operations don’t make a valid template.")),
            ]))
        }
        let inconsistencies = consistencyRefusals(in: result)
        return inconsistencies.isEmpty ? .success(result) : .failure(TemplateRefusals(items: inconsistencies))
    }

    // MARK: - One operation

    private func apply(_ operation: TemplateOperation, to tree: JSONValue, slotCount: Int) -> Result<JSONValue, TemplateRefusal> {
        let path = operation.path
        guard operation.operation == TemplateOperation.replaceOperation else {
            return .failure(TemplateRefusal(
                path: path,
                kind: .unsupportedOperation,
                reason: String(localized: "Only “replace” operations are supported; “\(operation.operation)” isn’t.")
            ))
        }
        let components = path.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        if components.first == "slots" {
            return applySlot(operation, components: components, to: tree, slotCount: slotCount)
        }
        guard let rule = TemplateSchema.rule(for: path) else { return .failure(unknownPath(path)) }
        if let refusal = check(operation.value, against: rule, path: path) { return .failure(refusal) }
        return .success(tree.setting(operation.value.isNull ? nil : operation.value, at: components[...]))
    }

    /// `slots.<i>.layout` and `slots.<i>.over.<path>`.
    private func applySlot(_ operation: TemplateOperation, components: [String], to tree: JSONValue, slotCount: Int) -> Result<JSONValue, TemplateRefusal> {
        let path = operation.path
        guard components.count >= 3, let index = Int(components[1]) else { return .failure(unknownPath(path)) }
        guard (0..<slotCount).contains(index) else {
            return .failure(TemplateRefusal(
                path: path,
                kind: .unknownSlot,
                reason: String(localized: "The template has \(slotCount) slots, numbered 0 to \(slotCount - 1); there’s no slot \(index).")
            ))
        }
        if components.count == 3, components[2] == "layout" {
            let rule = TemplateFieldRule.choice(TemplateSlot.Layout.allCases.map(\.rawValue))
            if let refusal = check(operation.value, against: rule, path: path) { return .failure(refusal) }
            return .success(tree.setting(operation.value, at: components[...]))
        }
        guard components.count > 3, components[2] == "over" else { return .failure(unknownPath(path)) }
        let field = components[3...].joined(separator: ".")
        guard let rule = TemplateSchema.overrideRule(for: field) else { return .failure(unknownPath(path)) }
        let key = ["slots", components[1], "over", field]
        if operation.value.isNull { return .success(tree.setting(nil, at: key[...])) }
        if let refusal = check(operation.value, against: rule, path: path) { return .failure(refusal) }
        return .success(tree.setting(operation.value, at: key[...]))
    }

    // MARK: - Values

    private func check(_ value: JSONValue, against rule: TemplateFieldRule, path: String) -> TemplateRefusal? {
        switch rule {
        case let .number(range, unit):
            checkNumber(value, range: range, unit: unit, path: path)
        case let .integer(range):
            checkInteger(value, range: range, path: path)
        case .boolean:
            value.boolValue == nil ? wrongType(path, String(localized: "true or false")) : nil
        case let .choice(options):
            checkChoice(value, options: options, path: path)
        case .color:
            value.stringValue.flatMap(TemplateColor.init) == nil ? wrongType(path, String(localized: "a color like #7A80FF or rgba(255,255,255,0.84)")) : nil
        case let .colors(count):
            checkColors(value, count: count, path: path)
        case .font:
            checkFont(value, path: path)
        case let .fallbackFont(script):
            value.isNull ? nil : checkFallback(value, script: script, path: path)
        case .text:
            (value.stringValue ?? "").trimmingCharacters(in: .whitespaces).isEmpty ? wrongType(path, String(localized: "non-empty text")) : nil
        }
    }

    private func checkNumber(_ value: JSONValue, range: ClosedRange<Double>, unit: String, path: String) -> TemplateRefusal? {
        guard let number = value.doubleValue else { return wrongType(path, String(localized: "a number")) }
        let bounds = "\(range.lowerBound.formatted()) and \(range.upperBound.formatted())" + (unit.isEmpty ? "" : " \(unit)")
        return range.contains(number) ? nil : outOfRange(path, number.formatted(), range: bounds)
    }

    private func checkInteger(_ value: JSONValue, range: ClosedRange<Int>, path: String) -> TemplateRefusal? {
        guard let number = value.intValue else { return wrongType(path, String(localized: "a whole number")) }
        return range.contains(number) ? nil : outOfRange(path, "\(number)", range: "\(range.lowerBound) and \(range.upperBound)")
    }

    private func checkChoice(_ value: JSONValue, options: [String], path: String) -> TemplateRefusal? {
        guard let text = value.stringValue, options.contains(text) else {
            let list = options.joined(separator: ", ")
            return TemplateRefusal(path: path, kind: .outOfRange, reason: String(localized: "\(path) is one of \(list)."))
        }
        return nil
    }

    private func checkColors(_ value: JSONValue, count: ClosedRange<Int>, path: String) -> TemplateRefusal? {
        guard let stops = value.arrayValue, stops.allSatisfy({ $0.stringValue.flatMap(TemplateColor.init) != nil }) else {
            return wrongType(path, String(localized: "a list of colors like [\"#7A80FF\", \"#3A2FB8\"]"))
        }
        return count.contains(stops.count) ? nil : outOfRange(path, "\(stops.count)", range: "\(count.lowerBound) and \(count.upperBound) colors")
    }

    private func checkFont(_ value: JSONValue, path: String) -> TemplateRefusal? {
        guard let name = value.stringValue else { return wrongType(path, String(localized: "a font name")) }
        guard fonts.isAvailable(name) else {
            return TemplateRefusal(path: path, kind: .unknownFont, reason: String(localized: "“\(name)” isn’t installed on this Mac."))
        }
        return nil
    }

    private func checkFallback(_ value: JSONValue, script: ScreenshotScript, path: String) -> TemplateRefusal? {
        if let refusal = checkFont(value, path: path) { return refusal }
        let name = value.stringValue ?? ""
        guard fonts.covers(name, script.sampleText) else {
            let candidates = fonts.fonts(drawing: script)
            let suggestion = candidates.isEmpty ? "" : " " + String(localized: "Fonts that can: \(candidates.joined(separator: ", ")).")
            return TemplateRefusal(
                path: path,
                kind: .fontCantDrawScript,
                reason: String(localized: "\(name) can’t draw \(script.title).") + suggestion
            )
        }
        return nil
    }

    // MARK: - The whole template

    private func consistencyRefusals(in template: ScreenshotTemplate) -> [TemplateRefusal] {
        var refusals: [TemplateRefusal] = []
        let background = template.background
        switch background.kind {
        case .linear where background.angle == nil:
            refusals.append(inconsistent("bg.angle", String(localized: "A linear background needs an angle in degrees.")))
        case .linear where background.stops.count < 2, .panorama where background.stops.count < 2:
            refusals.append(inconsistent("bg.stops", String(localized: "A \(background.kind.rawValue) background needs at least two colors.")))
        case .image where background.image == nil:
            refusals.append(inconsistent("bg.image", String(localized: "An image background needs an asset id.")))
        default:
            break
        }
        for index in template.slots.indices {
            let resolved = template.resolved(forSlot: index)
            let prefix = template.slots[index].over.isEmpty ? "" : "slots.\(index).over."
            for (block, style) in [("headline", resolved.caption.headline), ("subhead", resolved.caption.subhead)] where style.min > style.size {
                let reason = String(localized: "The smallest size (\(style.min.formatted()) u) is above the size (\(style.size.formatted()) u).")
                refusals.append(inconsistent("\(prefix)caption.\(block).min", reason))
            }
        }
        return Array(Set(refusals)).sorted { $0.path < $1.path }
    }

    // MARK: - Refusals

    private func unknownPath(_ path: String) -> TemplateRefusal {
        if TemplateSchema.readOnlyPaths.contains(path) {
            return TemplateRefusal(path: path, kind: .unknownPath, reason: String(localized: "\(path) is set by AppLocalizer and can’t be changed by a proposal."))
        }
        let parent = path.split(separator: ".").dropLast().joined(separator: ".")
        let siblings = TemplateSchema.fields(under: parent)
        let hint = siblings.isEmpty || parent.isEmpty ? "" : " " + String(localized: "Fields under \(parent): \(siblings.joined(separator: ", ")).")
        return TemplateRefusal(path: path, kind: .unknownPath, reason: String(localized: "“\(path)” isn’t a template field.") + hint)
    }

    private func wrongType(_ path: String, _ expected: String) -> TemplateRefusal {
        TemplateRefusal(path: path, kind: .wrongType, reason: String(localized: "\(path) takes \(expected)."))
    }

    private func outOfRange(_ path: String, _ value: String, range: String) -> TemplateRefusal {
        TemplateRefusal(path: path, kind: .outOfRange, reason: String(localized: "\(path) must be between \(range); \(value) is out of range."))
    }

    private func inconsistent(_ path: String, _ reason: String) -> TemplateRefusal {
        TemplateRefusal(path: path, kind: .inconsistent, reason: reason)
    }
}
