//
//  AutopilotNextStep+MCPScreens.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `suggest_screens`: what the plan has, what the person asked for, and
    /// how to answer.
    static func suggestScreensJSON(_ request: AutopilotScreenRequest, run: AutopilotRun?) -> JSONValue {
        let plan = run?.plan
        let screens: [JSONValue] = (plan?.screens ?? []).enumerated().map { index, screen in
            ["slot": .int(index + 1), "name": .string(screen.name), "steps": .string(screen.steps)]
        }
        let room = AutopilotCenter.maximumScreens - (plan?.screens.count ?? 0)
        var json: [String: JSONValue] = [
            "action": "suggest_screens",
            "screens": .array(screens),
            "room": .int(room),
            "version": .string(run?.versionString ?? ""),
            "how": .string("""
            Suggest up to \(min(3, room)) screens the app’s screenshot set is missing, best first. Read the \
            app's UI tests\(plan?.writtenFrom.map { " (\($0))" } ?? ""), the commits since the last version (git log), and the live \
            screenshots (get_capture_plan's screens are the set's). Prefer what's new in this version and in no screenshot yet, \
            features people search for, and what the app does outside itself (widgets). For each: name, reason (one sentence: \
            why it shows the app well), evidence (the file, target or commit that shows it), steps (how to reach it from \
            launch, like the plan's), caption (the primary language's headline, 3–6 words). Send them with propose_screens \
            and this run's ID. Nothing is added until the person adds it; don't change the plan or the project.
            """),
        ]
        if let ask = request.ask { json["ask"] = .string(ask) }
        return .object(json)
    }
}
