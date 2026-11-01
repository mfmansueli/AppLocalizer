//
//  TemplateSchema+Titles.swift
//  AppLocalizer
//

import Foundation

// Template fields in words, for version notes and a proposal's
// "old → new": "Headline size", "Device width 74%", "Thai fallback none".
extension TemplateSchema {
    /// The field's name in a sentence, e.g. "Smallest headline size".
    static func title(for path: String) -> String {
        if let title = titles[path] { return title }
        let parts = path.split(separator: ".").map(String.init)
        if parts.count == 3, parts[0] == "caption", let block = blockTitles[parts[1]], let field = textStyleTitles[parts[2]] {
            return "\(block) \(field)"
        }
        if parts.count == 3, parts[0] == "fonts", parts[1] == "fallback", let script = ScreenshotScript(rawValue: parts[2]) {
            return String(localized: "\(script.title) fallback")
        }
        return path
    }

    /// A value as the inspector shows it: "104 u", "168°", "74%", "on",
    /// "none".
    static func formatted(_ value: JSONValue?, at path: String) -> String {
        guard let value, !value.isNull else { return String(localized: "none") }
        if let flag = value.boolValue { return flag ? String(localized: "on") : String(localized: "off") }
        if let list = value.arrayValue { return list.map { formatted($0, at: "") }.joined(separator: ", ") }
        if let number = value.doubleValue, case let .number(_, unit)? = rule(for: path) {
            if unit.isEmpty, fractionPaths.contains(path) { return "\((number * 100).formatted(.number.precision(.fractionLength(0...1))))%" }
            let text = number.formatted(.number.precision(.fractionLength(0...2)))
            return unit.isEmpty ? text : (unit == "°" ? "\(text)°" : "\(text) \(unit)")
        }
        if let number = value.doubleValue { return number.formatted() }
        return value.stringValue ?? ""
    }

    /// Lengths given as a fraction of the canvas, shown as percentages.
    private static let fractionPaths: Set = [
        "device.width", "device.offset", "device.bleed", "caption.gap", "safe.top", "safe.side", "safe.bottom",
    ]

    private static let titles: [String: String] = [
        "name": String(localized: "Name"),
        "canvas.iphone": String(localized: "iPhone orientation"),
        "canvas.ipad": String(localized: "iPad orientation"),
        "canvas.duo": String(localized: "iPhone Duo orientation"),
        "bg.kind": String(localized: "Background"),
        "bg.angle": String(localized: "Gradient angle"),
        "bg.stops": String(localized: "Background colors"),
        "bg.image": String(localized: "Background image"),
        "device.show": String(localized: "Device frame"),
        "device.width": String(localized: "Device width"),
        "device.color": String(localized: "Device finish"),
        "device.offset": String(localized: "Device offset"),
        "device.bleed": String(localized: "Device bleed"),
        "caption.placement": String(localized: "Caption placement"),
        "caption.align": String(localized: "Caption alignment"),
        "caption.gap": String(localized: "Space under the caption"),
        "caption.headline.min": String(localized: "Smallest headline size"),
        "caption.subhead.min": String(localized: "Smallest subhead size"),
        "caption.ink": String(localized: "Caption color"),
        "caption.subInk": String(localized: "Subhead color"),
        "caption.band.color": String(localized: "Band color"),
        "caption.band.pos": String(localized: "Band position"),
        "fit.shrink": String(localized: "Shrink to fit"),
        "fit.hyphenate": String(localized: "Hyphenate long words"),
        "rtl.mirror": String(localized: "Right-to-left mirroring"),
        "safe.top": String(localized: "Space above the caption"),
        "safe.side": String(localized: "Side safe areas"),
        "safe.bottom": String(localized: "Bottom safe area"),
        "fonts.display": String(localized: "Display font"),
    ]

    private static let blockTitles = ["headline": String(localized: "Headline"), "subhead": String(localized: "Subhead")]

    private static let textStyleTitles = [
        "font": String(localized: "font"),
        "weight": String(localized: "weight"),
        "size": String(localized: "size"),
        "min": String(localized: "smallest size"),
        "lh": String(localized: "line height"),
        "maxLines": String(localized: "lines"),
        "tracking": String(localized: "tracking"),
    ]
}
