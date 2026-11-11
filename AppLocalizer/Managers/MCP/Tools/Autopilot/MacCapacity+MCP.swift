//
//  MacCapacity+MCP.swift
//  AppLocalizer
//

import Foundation

/// `thisMac` in `get_capture_plan` and in `next_step`'s capture and record
/// steps: how many simulators the assistant keeps running at once, and to
/// let the Mac settle when it's overloaded.
extension MacCapacity {
    var mcpJSON: JSONValue {
        let limit = simulatorsAtOnce
        var how = limit == 1
            ? "Keep one simulator running at a time, with iPhone Duo, which AppLocalizer starts itself, as the only other."
            : "Keep at most \(limit) simulators running at once; iPhone Duo, which AppLocalizer starts itself, counts as one."
        how += """
         Capture device by device: start a device's simulator when you get to it, do all of its targets in this step, then shut it \
        down (xcrun simctl shutdown <simulatorId>) before starting the next one. Don't start every device up front, and \
        never run xcodebuild test on two devices at the same time on this Mac. Run each xcodebuild in the foreground and \
        wait for it: nothing in the background, which stops when your turn ends and takes its captures with it. A simulator \
        you start again has lost its status bar and appearance: run the plan's simulator setup on it again before \
        capturing. Read thisMac again in each step: it changes with what the Mac is doing.
        """
        switch pressure {
        case .calm:
            break
        case .busy:
            how += " This Mac is busy right now (see load), so it's one at a time: shut down the simulators you aren't capturing on."
        case .overloaded:
            how += """
             This Mac is overloaded right now (see load): shut down every simulator but the one you're capturing on \
            (xcrun simctl list devices booted shows them), and start nothing new until the next step says it has settled.
            """
        }
        return .object([
            "simulatorsAtOnce": .int(limit),
            "cores": .int(cores),
            "load": .string("\(Self.format(load)) waiting to run on \(cores) cores: \(pressure.rawValue)"),
            "how": .string(how),
        ])
    }

    /// Adds `thisMac` to a capture plan or to a step that uses simulators.
    static func addGuidance(to json: inout [String: JSONValue], capacity: MacCapacity) {
        if let action = json["action"]?.stringValue, action != "capture", action != "record" { return }
        json["thisMac"] = capacity.mcpJSON
    }

    private static func format(_ load: Double) -> String {
        load >= 10 ? String(Int(load.rounded())) : String(format: "%.1f", load)
    }
}
