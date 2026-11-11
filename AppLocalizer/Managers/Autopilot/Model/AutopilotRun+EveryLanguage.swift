//
//  AutopilotRun+EveryLanguage.swift
//  AppLocalizer
//

import Foundation

/// Retry in Every Language: a change to the project that shows on a screen
/// in every language, not only the one reported. Alba's open topics menu
/// covered the phrase on iPhone in all 14 languages; the assistant reported
/// Italian, the others had been captured before anyone looked, and Retry
/// captured Italian alone.
extension AutopilotRun {
    /// The same screen on the same device in the other languages already
    /// captured, that no problem holds or retries yet.
    func otherLanguageTargets(of problem: AutopilotProblem) -> [AutopilotCaptureTarget] {
        guard !problem.isDeviceWide else { return [] }
        let waiting = Set(problems.filter(\.isOpen).map(\.target) + retries.map(\.target))
        return plan.targets.filter { target in
            target.screenID == problem.target.screenID && target.displayType == problem.target.displayType
                && target.duoPose == problem.target.duoPose && target.locale != problem.target.locale
                && hasCapture(for: target) && !waiting.contains(target)
        }
    }

    /// How many more captures Retry in Every Language would take.
    func otherLanguageCount(of group: AutopilotProblemGroup) -> Int {
        Set(group.problems.flatMap(otherLanguageTargets(of:))).subtracting(group.problems.map(\.target)).count
    }

    /// Retries the problems, and their screen on their device in every
    /// other language already captured, each as a retry of its own: a
    /// capture that arrives after it replaces the old one, and a language
    /// that fails keeps the capture it had. Returns how many were added.
    @discardableResult
    mutating func retryInEveryLanguage(_ problemIDs: [String], makeID: () -> String, at date: Date) -> Int {
        var added = 0
        for problemID in problemIDs {
            guard let index = problems.firstIndex(where: { $0.id == problemID }) else { continue }
            problems[index].resolution = .retryWithFix
            let problem = problems[index]
            for target in otherLanguageTargets(of: problem) {
                var copy = problem
                copy.id = makeID()
                copy.target = target
                copy.reportedAt = date
                problems.append(copy)
                added += 1
            }
        }
        return added
    }
}
