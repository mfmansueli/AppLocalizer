//
//  AutopilotPlan+Rehearsal.swift
//  AppLocalizer
//

import Foundation

/// The rehearsal: every screen on every device in the primary language and
/// one other before the rest. Whatever breaks with languages — a test that
/// finds a button by its English title, sample data in one language, a
/// label that doesn't fit — breaks there once, instead of in every
/// language.
extension AutopilotPlan {
    /// The other language rehearsed: one in another script than the primary
    /// language's (Japanese, Korean, Chinese, Arabic…), else German for its
    /// long words, else the next one. Nil with a single language.
    var rehearsalLocale: String? {
        guard capturesEachLanguage else { return nil }
        let others = capturedLocales.filter { $0 != primaryLocale }
        let primaryScript = Self.script(of: primaryLocale)
        return others.first { Self.script(of: $0) != primaryScript }
            ?? others.first { $0 == "de" || $0.hasPrefix("de-") }
            ?? others.first
    }

    /// The primary language or the rehearsal's.
    func isRehearsal(_ target: AutopilotCaptureTarget) -> Bool {
        target.locale == primaryLocale || target.locale == rehearsalLocale
    }

    /// `targets`, the rehearsal's first, each part in its own order.
    var rehearsalFirstTargets: [AutopilotCaptureTarget] {
        let all = targets
        guard rehearsalLocale != nil else { return all }
        return all.filter(isRehearsal) + all.filter { !isRehearsal($0) }
    }

    /// "Latn", "Jpan", "Cyrl".
    static func script(of code: String) -> String? {
        let maximal = Locale.Language(identifier: code).maximalIdentifier
        return Locale.Language(identifier: maximal).script?.identifier
    }
}
