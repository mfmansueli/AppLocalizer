//
//  AutopilotNextStep+MCPScreens.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// The plan has no screens: nothing can be captured or recorded yet.
    static var chooseScreensJSON: JSONValue {
        [
            "action": "choose_screens",
            "how": .string("""
            This plan has no screens yet, so nothing can be captured or recorded. Read the project, choose the screens and \
            send them with update_capture_plan, then call next_step. \(AutopilotRun.choosingScreensHow)
            """),
        ]
    }

    /// `suggest_screens`: the device, what the plan has on it, what the
    /// person asked for, and how to answer.
    static func suggestScreensJSON(_ request: AutopilotScreenRequest, run: AutopilotRun?) -> JSONValue {
        let plan = run?.plan
        let display = request.device
        let screens: [JSONValue] = (plan?.screens(on: display) ?? []).enumerated().map { index, screen in
            ["slot": .int(index + 1), "name": .string(screen.name), "steps": .string(screen.steps)]
        }
        let room = plan?.screenRoom(on: display) ?? AutopilotCenter.maximumScreens
        var json: [String: JSONValue] = [
            "action": "suggest_screens",
            "device": .string(display.hasOwnScreens ? display.mcpValue : "set"),
            "screens": .array(screens),
            "room": .int(room),
            "version": .string(run?.versionString ?? ""),
            "how": .string(display == .watch ? watchHow(room: room) : setHow(room: room, writtenFrom: plan?.writtenFrom)),
        ]
        if let ask = request.ask { json["ask"] = .string(ask) }
        return .object(json)
    }

    /// The set's screens, captured on iPhone and iPad.
    private static func setHow(room: Int, writtenFrom: String?) -> String {
        """
        Suggest up to \(min(3, room)) screens the app’s screenshot set is missing, best first. Read the \
        app's UI tests\(writtenFrom.map { " (\($0))" } ?? ""), the commits since the last version (git log), and the live \
        screenshots (get_capture_plan's screens are the set's). Prefer what's new in this version and in no screenshot yet, \
        features people search for, and what the app does outside itself (widgets). For each: name, reason (one sentence: \
        why it shows the app well), evidence (the file, target or commit that shows it), steps (how to reach it from \
        launch, like the plan's), caption (the primary language's headline, 3–6 words). Send them with propose_screens \
        and this run's ID. Nothing is added until the person adds it; don't change the plan or the project.
        """
    }

    /// Apple Watch's own screens: the watch app, captured without captions.
    private static func watchHow(room: Int) -> String {
        """
        Suggest up to \(min(3, room)) Apple Watch screens the watch app's screenshots are missing, best first. These are \
        the watch's own screens (screens above), captured on the watch simulator paired with the iPhone one, not the \
        iPhone and iPad set. Read the watch app's target and its UI tests, the commits since the last version (git log) \
        that touch the watch app, and the live watch screenshots. Prefer what's new in this version, what people use on \
        the wrist (glanceable views, quick actions, workouts, complications and Smart Stack widgets) and what's in no watch \
        screenshot yet. For each: name, reason (one sentence: why it shows the watch app well), evidence (the file, \
        target or commit that shows it), steps (how to reach it from the watch app's launch, like the plan's). Leave out \
        caption: watch screenshots have none. Send them with propose_screens and this run's ID. Nothing is added until \
        the person adds it; don't change the plan or the project.
        """
    }
}
