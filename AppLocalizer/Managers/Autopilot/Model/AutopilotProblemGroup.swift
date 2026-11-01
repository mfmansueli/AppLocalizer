//
//  AutopilotProblemGroup.swift
//  AppLocalizer
//

import Foundation

/// Open problems with one cause: the same screen, and the same change to
/// the project (a test that finds a button by its English title fails in
/// every language and on every device) or the same fix. The person answers
/// them together.
struct AutopilotProblemGroup: Hashable, Sendable, Identifiable {
    /// In the order they were reported; never empty.
    var problems: [AutopilotProblem]

    /// The first problem's.
    var id: String { first.id }

    var first: AutopilotProblem { problems[0] }

    var screenID: String { first.target.screenID }

    var isSingle: Bool { problems.count == 1 }

    /// The languages, in the order they were reported.
    var locales: [String] { Self.unique(problems.map(\.target.locale)) }

    /// The devices, in the order they were reported.
    var displayTypes: [ScreenshotDisplayType] { Self.unique(problems.map(\.target.displayType)) }

    var needsProjectChange: Bool { problems.contains(where: \.needsProjectChange) }

    /// No screen on its device can be captured.
    var isDeviceWide: Bool { first.isDeviceWide }

    var displayType: ScreenshotDisplayType { first.target.displayType }

    /// Every fix is a command, so retrying adds it to the plan.
    var fixIsCommand: Bool { proposedFix != nil && problems.allSatisfy { $0.proposedFix?.isEmpty != false || $0.fixIsCommand } }

    var wasRefused: Bool { problems.contains(where: \.wasRefused) }

    /// The first refused command.
    var refusedCommand: String? { problems.lazy.compactMap(\.refusedCommand).first { !$0.isEmpty } }

    /// The first proposed fix.
    var proposedFix: String? { problems.lazy.compactMap(\.proposedFix).first { !$0.isEmpty } }

    /// Whether any of them is in `locale`.
    func includes(locale: String) -> Bool { problems.contains { $0.target.locale == locale } }

    /// `problems` grouped by screen and cause, in the order each group's
    /// first problem was reported.
    static func groups(of problems: [AutopilotProblem]) -> [AutopilotProblemGroup] {
        var groups: [AutopilotProblemGroup] = []
        var indices: [String: Int] = [:]
        for problem in problems {
            let key = Self.key(of: problem)
            if let index = indices[key] {
                groups[index].problems.append(problem)
            } else {
                indices[key] = groups.count
                groups.append(AutopilotProblemGroup(problems: [problem]))
            }
        }
        return groups
    }

    /// The device, for a device-wide problem; else the screen, and the
    /// change to the project, the fix or (with neither) what happened.
    private static func key(of problem: AutopilotProblem) -> String {
        if problem.isDeviceWide { return "device\u{1F}" + problem.target.displayType.rawValue }
        let cause = if problem.needsProjectChange {
            "project"
        } else if let fix = problem.proposedFix?.trimmingCharacters(in: .whitespacesAndNewlines), !fix.isEmpty {
            "fix:" + fix
        } else {
            "what:" + problem.what
        }
        return problem.target.screenID + "\u{1F}" + cause
    }

    private static func unique<Value: Hashable>(_ values: [Value]) -> [Value] {
        var seen = Set<Value>()
        return values.filter { seen.insert($0).inserted }
    }
}
