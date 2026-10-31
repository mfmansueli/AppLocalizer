//
//  AutopilotNextStep+MCP.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `next_step`'s result: what to do, and with which tools.
    func mcpJSON(run: AutopilotRun?) -> JSONValue {
        switch self {
        case .noRun:
            [
                "action": "none",
                "say": "No Autopilot run is waiting. Ask the person to open AppLocalizer → Screenshots → Run Autopilot… and press Start Autopilot.",
            ]
        case let .capture(targets, retries):
            Self.captureJSON(targets: targets, retries: retries, run: run)
        case let .wait(reason, seconds):
            ["action": "wait", "reason": .string(reason), "retryAfterSeconds": .int(seconds)]
        case let .design(remaining):
            [
                "action": "design",
                "remaining": .int(remaining),
                "how": """
                Call get_design_brief, design with the person's design project, and send each direction with \
                propose_direction as an AppLocalizer template (template and/or ops on a base starter). They \
                arrive one by one; the person chooses one.
                """,
            ]
        case let .revise(note):
            [
                "action": "revise_direction",
                "note": .string(note),
                "how": "Change the direction(s) the note is about and send each with revise_direction.",
            ]
        case let .writeCaptions(overflows):
            Self.writeCaptionsJSON(overflows)
        case .done:
            [
                "action": "done",
                "say": "The new set waits in AppLocalizer's Review & Push. Nothing is uploaded until the person pushes.",
            ]
        }
    }

    private static func captureJSON(targets: [AutopilotCaptureTarget], retries: [AutopilotProblem], run: AutopilotRun?) -> JSONValue {
        let items: [JSONValue] = targets.prefix(40).map { target in
            [
                "screen": .string(target.screenID),
                "name": .string(run?.plan.screen(id: target.screenID)?.name ?? target.screenID),
                "displayType": .string(target.displayType.mcpValue),
                "locale": .string(target.locale),
            ]
        }
        let fixes: [JSONValue] = retries.map { problem in
            [
                "screen": .string(problem.target.screenID),
                "displayType": .string(problem.target.displayType.mcpValue),
                "locale": .string(problem.target.locale),
                "fix": .string(problem.proposedFix ?? ""),
            ]
        }
        return [
            "action": "capture",
            "remaining": .int(targets.count),
            "targets": .array(items),
            "retryWithFix": .array(fixes),
            "how": """
            Capture each target up to 3 times, upload each PNG to the plan's upload URL and call report_capture \
            with the upload ID, attempt and a score from 0 to 1 (content filled in, no keyboard, alert or \
            spinner, nothing private, matches the caption) with notes saying why. When a screen can't be \
            reached, call report_capture_problem and go on with the others.
            """,
        ]
    }

    private static func writeCaptionsJSON(_ overflows: [AutopilotOverflow]) -> JSONValue {
        let items: [JSONValue] = overflows.map { item in
            var json: [String: JSONValue] = [
                "locale": .string(item.locale),
                "slot": .int(item.slot + 1),
                "displayType": .string(item.displayType.mcpValue),
                "maxLines": .int(item.maxLines),
                "problem": .string(item.headline.isEmpty ? "missing" : "too_long"),
            ]
            if !item.headline.isEmpty {
                json["headline"] = .string(item.headline)
                json["fill"] = .double((item.fill * 100).rounded() / 100)
            }
            if let subhead = item.subhead { json["subhead"] = .string(subhead) }
            return .object(json)
        }
        return [
            "action": "write_captions",
            "captions": .array(items),
            "how": """
            Write the missing captions and shorten the ones too long, keeping the meaning and the brand's \
            voice; check with measure_caption, then send them all with propose_captions and this run's ID \
            as run. They're saved right away and the run checks them again.
            """,
        ]
    }
}
