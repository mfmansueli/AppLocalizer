//
//  AutopilotNextStep+MCP.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `next_step`'s result: what to do, and with which tools.
    func mcpJSON(run: AutopilotRun?) -> JSONValue {
        switch self {
        case .noRun, .done:
            closingJSON(run: run)
        case let .capture(targets, retries):
            Self.captureJSON(targets: targets, retries: retries, run: run)
        case let .record(targets):
            Self.recordJSON(targets: targets)
        case let .wait(reason, seconds):
            ["action": "wait", "reason": .string(reason), "retryAfterSeconds": .int(seconds)]
        case .recordAgain, .design:
            beforeChoosingJSON
        case .revise, .revisePreview:
            revisionJSON(run: run)
        case let .writeCaptions(overflows):
            Self.writeCaptionsJSON(overflows)
        case let .writeArtworkTexts(needs):
            Self.writeArtworkTextsJSON(needs)
        case let .designVariant(request):
            Self.designVariantJSON(request)
        case let .suggestScreens(request):
            Self.suggestScreensJSON(request, run: run)
        }
    }

    /// Recording moments again, then designing: the steps before the
    /// person chooses a direction.
    private var beforeChoosingJSON: JSONValue {
        switch self {
        case let .recordAgain(screenIDs):
            [
                "action": "record_again",
                "moments": .array(screenIDs.map { .string($0) }),
                "how": """
                The person asked to record these App Preview moments again before the design step. For each, call \
                rerecord_moment with moment_id to see where, record only that screen, upload it and call \
                rerecord_moment again with the upload ID. The rest of the recording stays.
                """,
            ]
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
        default:
            ["action": "none"]
        }
    }

    /// `revise_direction` and `revise_app_preview`: the person's changes.
    private func revisionJSON(run: AutopilotRun?) -> JSONValue {
        switch self {
        case let .revisePreview(note, review):
            Self.revisePreviewJSON(note: note, review: review, run: run)
        case let .revise(note):
            [
                "action": "revise_direction",
                "note": .string(note),
                "how": "Change the direction(s) the note is about and send each with revise_direction.",
            ]
        default:
            ["action": "none"]
        }
    }

    /// `none` and `done`: nothing to do now, and why.
    private func closingJSON(run: AutopilotRun?) -> JSONValue {
        if case .noRun = self {
            return [
                "action": "none",
                "say": "No Autopilot run is waiting. Ask the person to open AppLocalizer → Screenshots → Run Autopilot… and press Start Autopilot.",
            ]
        }
        // At the plan, done means the suggested screens are in.
        let say = run?.stage == .plan
            ? "Your suggestions are in AppLocalizer's plan; the person adds the ones they want. Nothing else to do now."
            : "The new set waits in AppLocalizer's Review & Push. Nothing is uploaded until the person pushes."
        return ["action": "done", "say": .string(say)]
    }

    private static func captureJSON(targets: [AutopilotCaptureTarget], retries: [AutopilotProblem], run: AutopilotRun?) -> JSONValue {
        let items: [JSONValue] = targets.prefix(40).map { target in
            var item: [String: JSONValue] = [
                "screen": .string(target.screenID),
                "name": .string(run?.plan.screen(id: target.screenID)?.name ?? target.screenID),
                "displayType": .string(target.displayType.mcpValue),
                "locale": .string(target.locale),
            ]
            // iPhone Duo's closed screens are captured on its cover display,
            // its open ones on the inner display.
            if let pose = run?.plan.duoPose(for: target) { item["pose"] = .string(pose.rawValue) }
            return .object(item)
        }
        let fixes: [JSONValue] = retries.map { problem in
            var item: [String: JSONValue] = [
                "screen": .string(problem.target.screenID),
                "displayType": .string(problem.target.displayType.mcpValue),
                "locale": .string(problem.target.locale),
                "fix": .string(problem.proposedFix ?? ""),
            ]
            if problem.wasRefused, let command = problem.refusedCommand {
                item["refused"] = .string(command)
                item["note"] = .string(
                    "This command was refused. The person may have changed the project since (see fix): read it again, and don't run the refused command."
                )
            }
            return .object(item)
        }
        var json: [String: JSONValue] = [
            "action": "capture",
            "remaining": .int(run?.remainingTargets.count ?? targets.count),
            "targets": .array(items),
            "retryWithFix": .array(fixes),
            "how": """
            Capture each target up to 3 times, upload each PNG to the plan's upload URL and call report_capture \
            with the upload ID, attempt and a score from 0 to 1 (content filled in, no keyboard, alert or \
            spinner, nothing private, matches the caption) with notes saying why. When a screen can't be \
            reached, call report_capture_problem and go on with the others. When the fix is a change to the \
            project, report it once with changesProject: true: AppLocalizer holds that screen on that device in \
            the other languages. When this Mac can't run a device at all, report it once with affectsDevice: true. \
            Don't stop while next_step says capture: report what you can't capture, then ask next_step again, \
            and it gives you the rest.
            """,
        ]
        if let run, !run.remainingRecordings.isEmpty {
            json["record"] = .array(run.remainingRecordings.map(Self.recordingJSON))
            json["recordHow"] = .string(AutopilotRun.recordingHow)
        }
        if let run, let rehearsal = run.plan.rehearsalLocale {
            let rehearsing = targets.contains(where: run.plan.isRehearsal)
            json["phase"] = .string(rehearsing ? "rehearsal" : "capture")
            if rehearsing {
                json["rehearsal"] = .string("""
                Each screen on each device is captured in \(run.plan.primaryLocale) and \(rehearsal) before its other \
                languages, which come once it's done: check that it reaches its screen in \(rehearsal) too, in that \
                language, with nothing cut off. A screen or device that can't go on holds back only its own languages.
                """)
            }
        }
        return .object(json)
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
