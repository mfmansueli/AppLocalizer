//
//  TemplateChange.swift
//  AppLocalizer
//

import Foundation

/// One field that differs between two templates: a version note's part,
/// and a proposal's "old → new" row.
struct TemplateChange: Hashable, Sendable, Identifiable {
    /// The schema path, with `slots.<i>.` in front for a slot's layout or
    /// override.
    var path: String
    /// Nil when the field (or override) wasn't there.
    var old: JSONValue?
    var new: JSONValue?

    var id: String { path }

    /// The slot the change is limited to, if it is.
    var slot: Int? {
        let parts = path.split(separator: ".")
        guard parts.count >= 3, parts[0] == "slots" else { return nil }
        return Int(parts[1])
    }

    /// The schema path without the slot prefix: `caption.headline.size`
    /// for `slots.1.over.caption.headline.size`.
    var fieldPath: String {
        let parts = path.split(separator: ".").map(String.init)
        guard slot != nil else { return path }
        return parts[2] == "over" ? parts.dropFirst(3).joined(separator: ".") : parts.dropFirst(2).joined(separator: ".")
    }

    /// "Headline size", or "Slot 2 headline size" for an override.
    var title: String {
        guard let slot else { return TemplateSchema.title(for: fieldPath) }
        if fieldPath == "layout" { return String(localized: "Slot \(slot + 1) layout") }
        let field = TemplateSchema.title(for: fieldPath)
        return String(localized: "Slot \(slot + 1) \(field.prefix(1).lowercased() + field.dropFirst())")
    }

    /// "104 u", or "template" when a slot override was removed.
    var newText: String {
        if slot != nil, fieldPath != "layout", new == nil { return String(localized: "as the template") }
        return TemplateSchema.formatted(new, at: fieldPath)
    }

    var oldText: String {
        if slot != nil, fieldPath != "layout", old == nil { return String(localized: "as the template") }
        return TemplateSchema.formatted(old, at: fieldPath)
    }

    /// "Headline size 104 u".
    var summary: String { "\(title) \(newText)" }
}
