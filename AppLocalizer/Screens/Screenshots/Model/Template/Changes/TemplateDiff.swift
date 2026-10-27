//
//  TemplateDiff.swift
//  AppLocalizer
//

import Foundation

/// What changed between two templates, field by field, and the note a
/// saved version gets from it ("Headline size 104 u, hyphenation on").
/// Part 3's template proposals list the same changes as "old → new".
enum TemplateDiff {
    /// Every schema field, slot layout and slot override that differs, in
    /// schema order then slot order.
    static func changes(from old: ScreenshotTemplate, to new: ScreenshotTemplate) -> [TemplateChange] {
        let oldJSON = old.json
        let newJSON = new.json
        var changes: [TemplateChange] = []
        for path in TemplateSchema.rules.keys.sorted(by: schemaOrder) {
            let components = path.split(separator: ".").map(String.init)
            let before = oldJSON.value(at: components)
            let after = newJSON.value(at: components)
            if !equivalent(before, after) { changes.append(TemplateChange(path: path, old: before, new: after)) }
        }
        for index in 0..<max(old.slots.count, new.slots.count) {
            let before = old.slots.indices.contains(index) ? old.slots[index] : TemplateSlot()
            let after = new.slots.indices.contains(index) ? new.slots[index] : TemplateSlot()
            if before.layout != after.layout {
                changes.append(TemplateChange(
                    path: "slots.\(index).layout", old: .string(before.layout.rawValue), new: .string(after.layout.rawValue)
                ))
            }
            for key in Set(before.over.keys).union(after.over.keys).sorted(by: schemaOrder) where !equivalent(before.over[key], after.over[key]) {
                changes.append(TemplateChange(path: "slots.\(index).over.\(key)", old: before.over[key], new: after.over[key]))
            }
        }
        return changes
    }

    /// A version note: the changes in words, the first three by name.
    static func note(for changes: [TemplateChange]) -> String {
        switch changes.count {
        case 0:
            return String(localized: "No changes")
        case 1...3:
            let parts = changes.enumerated().map { index, change in
                index == 0 ? change.summary : change.summary.prefix(1).lowercased() + change.summary.dropFirst()
            }
            return parts.joined(separator: ", ")
        default:
            let first = changes.prefix(2).map(\.title).joined(separator: ", ")
            return String(localized: "\(first) and \(changes.count - 2) more changes")
        }
    }

    private static func equivalent(_ lhs: JSONValue?, _ rhs: JSONValue?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): lhs.isEquivalent(to: rhs)
        case let (value?, nil), let (nil, value?): value.isNull
        }
    }

    /// The inspector's order: canvas, background, device, caption, fit,
    /// right to left, safe areas, fonts.
    private static func schemaOrder(_ lhs: String, _ rhs: String) -> Bool {
        let order = ["name", "canvas", "bg", "device", "caption", "fit", "rtl", "safe", "fonts"]
        let lhsRank = order.firstIndex(of: String(lhs.prefix { $0 != "." })) ?? order.count
        let rhsRank = order.firstIndex(of: String(rhs.prefix { $0 != "." })) ?? order.count
        return lhsRank == rhsRank ? lhs < rhs : lhsRank < rhsRank
    }
}
