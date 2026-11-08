//
//  ScreenshotTemplate+Paths.swift
//  AppLocalizer
//

import Foundation

// Reading the template by dotted path, the way per-slot overrides and
// assistant proposals address it, and the order of resolution: a slot's
// override, then the template's own value.
extension ScreenshotTemplate {
    /// The template as JSON, keys as in README §3.
    var json: JSONValue {
        (try? JSONValue(encoding: self)) ?? .null
    }

    /// Decodes a template from its JSON.
    init(json: JSONValue) throws {
        let data = try JSONEncoder().encode(json)
        self = try JSONDecoder().decode(ScreenshotTemplate.self, from: data)
    }

    /// The template's own value at a dotted path (`caption.headline.size`),
    /// or nil when there's nothing there.
    func value(at path: String) -> JSONValue? {
        json.value(at: path.split(separator: ".").map(String.init))
    }

    /// The value slot `index` uses: its override if it has one, else the
    /// template's.
    func value(at path: String, slot index: Int) -> JSONValue? {
        if slots.indices.contains(index), let override = slots[index].over[path] { return override }
        return value(at: path)
    }

    /// The template as slot `index` sees it, with that slot's overrides laid
    /// on top, then the landscape ones on a landscape canvas. An override
    /// the template can't take (a path that neither exists nor is a field
    /// the template may leave out, or a value of the wrong type) is
    /// ignored.
    func resolved(forSlot index: Int, isLandscape: Bool = false) -> ScreenshotTemplate {
        let slotOverrides = slots.indices.contains(index) ? slots[index].over : [:]
        let landscapeOverrides = isLandscape ? landscape ?? [:] : [:]
        guard !slotOverrides.isEmpty || !landscapeOverrides.isEmpty else { return self }
        var tree = json
        for overrides in [slotOverrides, landscapeOverrides] {
            for (path, value) in overrides.sorted(by: { $0.key < $1.key }) {
                let components = path.split(separator: ".").map(String.init)
                let isKnown = tree.value(at: components) != nil || TemplateSchema.overrideRule(for: path) != nil
                guard isKnown, !["slots", "lan", "landscape"].contains(components.first ?? "") else { continue }
                let candidate = tree.setting(value, at: components[...])
                if (try? ScreenshotTemplate(json: candidate)) != nil { tree = candidate }
            }
        }
        return (try? ScreenshotTemplate(json: tree)) ?? self
    }
}
