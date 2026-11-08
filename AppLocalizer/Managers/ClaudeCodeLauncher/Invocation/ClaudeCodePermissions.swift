//
//  ClaudeCodePermissions.swift
//  AppLocalizer
//

import Foundation

/// What a run AppLocalizer starts may do. Runs are unattended, so they're
/// started in Claude Code's restricted mode: the person's own settings
/// files (and their allow rules) are ignored, file tools stay inside the
/// project folder, only the tools named here are available, and anything
/// these rules don't allow is refused instead of asked.
enum ClaudeCodePermissions: Hashable, Sendable, CaseIterable {
    /// The setup test: AppLocalizer's tools only.
    case appLocalizerOnly
    /// Suggestions, translations and the privacy scan: read the project and
    /// its git history.
    case readProject
    /// Screenshot Autopilot: also build the app, drive the simulators and
    /// upload captures to AppLocalizer.
    case autopilot

    /// `--tools`: the built-in tools available at all.
    var tools: [String] {
        switch self {
        case .appLocalizerOnly: []
        case .readProject, .autopilot: ["Read", "Grep", "Glob", "Bash"]
        }
    }

    /// The `permissions.allow` rules passed with `--settings`.
    func allowRules(port: UInt16) -> [String] {
        let appLocalizer = ["mcp__\(MCPEndpoint.serverName)"]
        let reading = ["Read", "Grep", "Glob"] + Self.gitCommands.map { "Bash(git \($0):*)" }
        switch self {
        case .appLocalizerOnly:
            return appLocalizer
        case .readProject:
            return appLocalizer + reading
        case .autopilot:
            let building = [
                "Bash(xcodebuild:*)",
                "Bash(xcrun simctl:*)",
                "Bash(xcrun xcresulttool:*)",
                "Bash(open -a Simulator:*)",
                "Bash(mkdir:*)",
                "Bash(ls:*)",
                "Bash(sleep:*)",
                "Bash(echo:*)",
                // Stops an App Preview's recordVideo the way Control-C does,
                // so the file is finished. Without it, MB Admin's App Preview
                // recordings were left out: kill -INT was refused.
                "Bash(\(Self.stopRecordingCommand))",
                // Captures go to AppLocalizer's upload endpoint, and nowhere else.
                "Bash(curl * http://127.0.0.1:\(port)/autopilot/*)",
            ]
            return appLocalizer + reading + building
        }
    }

    /// The `permissions.deny` rules, which win over the allow rules.
    ///
    /// Autopilot may run any `xcrun simctl` command, but not change a
    /// simulator's displays: trying to open iPhone Duo with `simctl io …
    /// screenConfig --display=1 power off`, an assistant left its display
    /// configuration invalid, and the simulator's SpringBoard crashed again
    /// on every start until the simulator was restarted.
    var denyRules: [String] {
        switch self {
        case .appLocalizerOnly, .readProject: []
        case .autopilot: ["Bash(xcrun simctl io * screenConfig*)"]
        }
    }

    /// The one command that stops a recording: it can only interrupt
    /// simulator commands, and never the shell running it (as `pkill -f`
    /// would).
    static let stopRecordingCommand = "killall -INT simctl"

    /// Read-only git subcommands.
    static let gitCommands = ["log", "show", "diff", "tag", "describe", "rev-parse", "ls-files", "status", "branch"]

    /// What Claude is told about running unattended, after Claude Code's own
    /// system prompt.
    var systemPrompt: String {
        var lines = [
            "AppLocalizer, a Mac app, started this Claude Code session for the person, without a terminal.",
            "Nobody is watching it live: don't ask questions, and don't wait for an answer.",
            "Permission prompts are refused automatically, so stay within the allowed tools: AppLocalizer's MCP tools"
                + (self == .appLocalizerOnly ? "." : ", reading files in this project and read-only git commands."),
            "Never push or change App Store Connect directly; everything goes through AppLocalizer's tools, and the person reviews it there.",
            "If something you need is refused or missing, say so in one sentence in your last message and finish.",
        ]
        if self == .autopilot {
            lines.append(
                "For screenshots you may also run xcodebuild, xcrun simctl, xcrun xcresulttool, open -a Simulator, mkdir, ls, sleep and echo, "
                    + "and stop an App Preview recording (xcrun simctl io … recordVideo, started in the background) with exactly "
                    + "\(Self.stopRecordingCommand). "
                    + "Upload each capture with exactly: curl -s --data-binary @<file> -H 'Content-Type: image/png' <upload URL from get_capture_plan>. "
                    + "Run each command on its own, without chaining other commands. "
                    + "Each command must start with one of those programs: VAR=value in front of it, cd or a pipe is refused. "
                    + "UI tests get their language and region from the locale's testArguments (-testLanguage, -testRegion) "
                    + "and anything else from their scheme or test plan. "
                    + "If a command is refused, don't try it in another form: report_capture_problem with refusedCommand, "
                    + "with what to change in the project as proposedFix, and go on with the other screens. "
                    + "You can't edit the project here, so a fix that changes it (a test, a scheme, sample data) is reported once, "
                    + "with changesProject: true and the file and line in proposedFix. "
                    + "When get_capture_plan's appLook isn't known, read the app's design language in the project and send it "
                    + "with report_app_support's look before choosing screens: every design in the run starts from it. "
                    + "Before capturing, check: " + AutopilotPreflight.checks.joined(separator: " ")
            )
            lines.append(
                "Claude Design and Figma can't be opened from here. When next_step says design, design the directions from "
                    + "get_design_brief (the picks, captions, canvases and the design project's summary when it has one) "
                    + "and send each with propose_direction (with the header and search pages when the brief has artworkDesign, "
                    + "tried with render_artwork); when next_step hands you prompts, follow them and send the header and search "
                    + "concepts with propose_artwork_concept and their changes and loops with revise_artwork_concept; "
                    + "don't stop because the design project can't be opened."
            )
        }
        return lines.joined(separator: "\n")
    }

    /// For Settings: "Suggestions, translations, privacy".
    var title: String {
        switch self {
        case .appLocalizerOnly: String(localized: "Setup test")
        case .readProject: String(localized: "Suggestions, translations, privacy")
        case .autopilot: String(localized: "Screenshot Autopilot")
        }
    }

    /// For Settings: what it may do, in words.
    var detail: String {
        switch self {
        case .appLocalizerOnly: String(localized: "AppLocalizer’s tools only")
        case .readProject: String(localized: "AppLocalizer’s tools, reading the project, read-only git")
        case .autopilot: String(localized: "Also xcodebuild, xcrun simctl and uploads to AppLocalizer")
        }
    }
}
