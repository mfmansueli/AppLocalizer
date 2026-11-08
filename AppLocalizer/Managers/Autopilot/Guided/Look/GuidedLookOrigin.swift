//
//  GuidedLookOrigin.swift
//  AppLocalizer
//

import Foundation

/// Which of the person's template picks a look on Choose was made from,
/// so the template's name stays in sight after the Look step.
@MainActor
enum GuidedLookOrigin {
    /// The pick (1-based) and template `direction` starts from, when the
    /// run's looks come from picked templates and it's one of them.
    static func pick(of direction: AutopilotDirection, plan: AutopilotPlan) -> (number: Int, starter: TemplateStarter)? {
        guard plan.screenshotStyle == .templates, let starter = direction.template.starter else { return nil }
        let picks = StarterDirectionMaker.starters(named: plan.screenshotTemplates)
        return picks.firstIndex(of: starter).map { ($0 + 1, starter) }
    }

    /// "Made from your pick 1, the Cinema template, in Northpier Brand."
    static func text(for direction: AutopilotDirection, plan: AutopilotPlan, brand: String?) -> String? {
        guard let (number, starter) = pick(of: direction, plan: plan) else { return nil }
        guard let brand else { return String(localized: "Made from your pick \(number), the \(starter.title) template.") }
        return String(localized: "Made from your pick \(number), the \(starter.title) template, in \(brand).")
    }
}
