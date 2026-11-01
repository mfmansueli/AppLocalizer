//
//  AutopilotRun+TextCheck.swift
//  AppLocalizer
//

import Foundation

// What the text AppLocalizer read in each capture says about it: a capture
// with an issue ranks below a clean one, and the ones the set still uses
// are listed for the person.
extension AutopilotRun {
    /// A capture in another language that reads as the primary language or
    /// English; cut-off labels beyond the primary language's on the same
    /// screen; a system prompt in any language.
    func textIssues(of capture: AutopilotCapture) -> [CaptureTextIssue] {
        guard let facts = capture.text else { return [] }
        var issues: [CaptureTextIssue] = []
        let isPrimary = capture.target.locale == plan.primaryLocale
        if !isPrimary, let found = facts.language, let expected = StoreLocaleCatalog.locale(code: capture.target.locale) {
            let primary = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.languageIdentifier ?? plan.primaryLocale
            let isFallback = CaptureTextLanguage.isSame(found, primary) || CaptureTextLanguage.isSame(found, "en")
            if isFallback, !CaptureTextLanguage.isSame(found, expected.languageIdentifier) {
                issues.append(.otherLanguage(found: CaptureTextLanguage.name(of: found), expected: expected.name))
            }
        }
        if !isPrimary, facts.truncatedLines.count > (primaryCounterpart(of: capture)?.text?.truncatedLines.count ?? 0) {
            issues.append(.cutOff(facts.truncatedLines))
        }
        if let line = facts.promptLine { issues.append(.systemPrompt(line)) }
        return issues
    }

    /// The captures the set uses that have an issue, in the plan's order.
    var capturesToCheck: [CaptureToCheck] {
        plan.targets.compactMap { target in
            guard let capture = finalCapture(for: target) else { return nil }
            let issues = textIssues(of: capture)
            return issues.isEmpty ? nil : CaptureToCheck(target: target, captureID: capture.id, issues: issues)
        }
    }

    /// The same screen and device in the primary language: the same
    /// attempt, else the best.
    private func primaryCounterpart(of capture: AutopilotCapture) -> AutopilotCapture? {
        let target = AutopilotCaptureTarget(screenID: capture.target.screenID, displayType: capture.target.displayType, locale: plan.primaryLocale)
        let own = captures.filter { $0.target == target }
        return own.first { $0.attempt == capture.attempt } ?? own.max { $0.score < $1.score }
    }
}
