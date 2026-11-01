//
//  AutopilotPreflight.swift
//  AppLocalizer
//

import Foundation

/// What the assistant checks in the project before capturing: the things
/// that make captures fail in every language but the one the project was
/// written in, or every time the run is unattended. `get_capture_plan`
/// sends them with the rehearsal, and AppLocalizer's own Claude Code is
/// told them too.
enum AutopilotPreflight {
    /// One sentence each.
    static let checks = [
        """
        UI tests find buttons, tabs and segments by accessibility identifier, never by their visible title: \
        app.buttons["Styles"] fails in every other language.
        """,
        "Sample data shown in the captures is in each language (names, entries, phrases), not only the primary one.",
        """
        UI tests take the language from the locale's testArguments (-testLanguage, -testRegion) and don't force \
        their own -AppleLanguages or -AppleLocale, which would override it.
        """,
        """
        Every command starts with xcodebuild or xcrun: switches go in a scheme or test plan, never as VAR=value in \
        front of the command.
        """,
        "Nothing waits on a permission alert, the keyboard or the network: grant permissions with simctl and use local sample data.",
    ]

    /// What to do when a check fails.
    static let whenACheckFails = """
    If you can change the project, fix it before capturing. If you can't, report it once with \
    report_capture_problem and changesProject: true, with the file and line to change as proposedFix: \
    AppLocalizer holds that screen on that device in the other languages instead of failing it in each.
    """

    /// Why the rehearsal's language was chosen.
    static func rehearsalReason(locale: String, primaryLocale: String) -> String {
        let script = AutopilotPlan.script(of: locale)
        if script != AutopilotPlan.script(of: primaryLocale) {
            return "Its script differs from \(primaryLocale)'s, so text found by its \(primaryLocale) title and cut-off labels show up."
        }
        if locale == "de" || locale.hasPrefix("de-") {
            return "Its long words show labels that don't fit."
        }
        return "Another language than \(primaryLocale)."
    }

    /// `get_capture_plan`'s `rehearsal`; nil with one language.
    static func rehearsalJSON(for plan: AutopilotPlan) -> JSONValue? {
        guard let locale = plan.rehearsalLocale else { return nil }
        return [
            "locale": .string(locale),
            "why": .string(rehearsalReason(locale: locale, primaryLocale: plan.primaryLocale)),
            "how": """
            next_step gives every screen on every device in the primary language and this one first, then the \
            other languages. Whatever fails there fails once instead of in every language.
            """,
        ]
    }

    /// `get_capture_plan`'s `preflight`.
    static var json: JSONValue {
        ["checks": .array(checks.map(JSONValue.string)), "whenACheckFails": .string(whenACheckFails)]
    }
}
