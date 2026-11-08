//
//  AutopilotShotStyle.swift
//  AppLocalizer
//

import Foundation

/// Where the screenshot directions come from (the plan's Screenshot
/// style): three of the design source's own, one from each of up to three
/// gallery templates, or none: the current template stays and only the
/// captures and captions are new. The raw values are the brief's
/// `shot_style`.
enum AutopilotShotStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case free
    case templates
    case keep

    /// The most templates a plan picks; a fourth replaces the last.
    static let maximumTemplates = 3

    /// "Claude Design proposes 3", "From templates", "Keep template v4".
    func title(design: String, version: Int?) -> String {
        switch self {
        case .free: String(localized: "\(design) proposes 3")
        case .templates: String(localized: "From templates")
        case .keep: version.map { String(localized: "Keep template v\($0)") } ?? String(localized: "Keep the template")
        }
    }

    /// The note beside the choice.
    func note(design: String, brand: String?, picked: Int, version: Int?) -> String {
        let inBrand = brand.map { String(localized: " in \($0)") } ?? ""
        switch self {
        case .free:
            return String(localized: "\(design) designs 3 directions of its own\(inBrand). You choose one.")
        case .templates:
            let count = TemplateStarter.allCases.count
            return String(localized: """
            Pick up to 3 of the \(count) templates (a 4th replaces the last). \(design) makes one direction from each\(inBrand). \
            \(picked) of 3 picked.
            """)
        case .keep:
            let name = version.map { String(localized: "template v\($0)") } ?? String(localized: "template")
            return String(localized: "Your current \(name) stays; only the captures and captions are new. No direction to choose.")
        }
    }

    /// "Bold Stack · for Lumen": a direction made from a picked template.
    static func directionName(template: String, app: String) -> String {
        String(localized: "\(template) · for \(app)")
    }

    /// Picks `name`, or takes it out: a fourth replaces the last.
    static func toggling(_ name: String, in picks: [String]) -> [String] {
        var picks = picks
        if let index = picks.firstIndex(of: name) {
            picks.remove(at: index)
            return picks
        }
        if picks.count >= maximumTemplates { picks.removeLast() }
        picks.append(name)
        return picks
    }
}
