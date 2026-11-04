//
//  ClaudeCodeDebugScripts.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// What each `cc-*` scene's pretend Claude Code prints.
enum ClaudeCodeDebugScripts {
    private typealias Line = DebugUnixScriptRunner.Line
    private typealias Stream = ClaudeCodeDebugStream
    typealias Script = DebugUnixScriptRunner.Script

    private static let sentEverything = "Sent 18 suggestions: What’s New in 12 languages, keywords for German and Japanese, and the App Review notes."
    private static let buildCommand = "xcodebuild -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build"

    static let test = Script(lines: [
        Line(delay: .milliseconds(400), text: Stream.started()),
        Line(delay: .milliseconds(600), text: Stream.appLocalizer("list_apps", id: "t1")),
        Line(delay: .milliseconds(300), text: Stream.said("You have 6 apps in AppLocalizer, from Fieldnote Scanner to Tempo Metronome.")),
        Line(delay: .milliseconds(200), text: Stream.result(text: "You have 6 apps in AppLocalizer.")),
    ])

    static let askWorking = Script(lines: [
        Line(delay: .milliseconds(200), text: Stream.started()),
        Line(delay: .milliseconds(200), text: Stream.appLocalizer("get_store_page", id: "a1")),
        Line(delay: .milliseconds(200), text: Stream.read(ProjectFolderPath.expanded("~/Developer/Lumen/CHANGELOG.md"), id: "a2")),
    ], exitStatus: nil)

    static let everythingWorking = Script(lines: [
        Line(delay: .milliseconds(200), text: Stream.started()),
        Line(delay: .milliseconds(200), text: Stream.appLocalizer("get_store_page", id: "e1")),
    ], exitStatus: nil)

    static let everythingFinished = Script(lines: [
        Line(delay: .zero, text: Stream.started()),
        Line(delay: .zero, text: Stream.appLocalizer("begin_suggestions", id: "f1")),
        Line(delay: .zero, text: Stream.read(ProjectFolderPath.expanded("~/Developer/Lumen/CHANGELOG.md"), id: "f2")),
        Line(delay: .zero, text: Stream.command("git log v1.3..HEAD --oneline", id: "f3")),
        Line(delay: .zero, text: Stream.appLocalizer("suggest_fields", id: "f4")),
        Line(delay: .zero, text: Stream.appLocalizer("end_suggestions", id: "f5")),
        Line(delay: .zero, text: Stream.result(text: sentEverything)),
    ])

    static let notLoggedIn = Script(lines: [
        Line(delay: .milliseconds(200), text: Stream.started()),
        Line(delay: .milliseconds(200), text: Stream.result(isError: true, text: "Invalid API key · Please run /login", apiErrorStatus: 401)),
    ], exitStatus: 1)

    static let denied = Script(lines: [
        Line(delay: .milliseconds(200), text: Stream.started()),
        Line(delay: .milliseconds(100), text: Stream.appLocalizer("get_store_page", id: "d1")),
        Line(delay: .milliseconds(100), text: Stream.command("swift package resolve", id: "d2")),
        Line(delay: .zero, text: Stream.failed("d2", message: "Permission to use Bash with command swift package resolve has been denied.")),
        Line(delay: .milliseconds(100), text: Stream.result(
            text: "I couldn’t resolve the package dependencies, so the suggestions only use the code I could read.",
            denials: [("Bash", ["command": "swift package resolve"]), ("Edit", ["file_path": "Sources/Lumen/Info.plist"])]
        )),
    ])

    /// Designing Product Page Optimization's Outcome variant, still at it.
    static let variantWorking = Script(lines: [
        Line(delay: .milliseconds(200), text: Stream.started()),
        Line(delay: .milliseconds(150), text: Stream.appLocalizer("next_step", id: "v1")),
        Line(delay: .milliseconds(150), text: Stream.appLocalizer("get_design_brief", id: "v2")),
        Line(delay: .milliseconds(150), text: Stream.read(ProjectFolderPath.expanded("~/Developer/Lumen/Design/Brand.md"), id: "v3")),
        Line(delay: .milliseconds(150), text: Stream.appLocalizer("render_preview", id: "v4")),
        Line(delay: .milliseconds(150), text: Stream.said("Designing the Outcome search image: a calm morning page, the same type and colours, no interface.")),
    ], exitStatus: nil)

    static let autopilotWorking = Script(lines: [
        Line(delay: .milliseconds(200), text: Stream.started()),
        Line(delay: .milliseconds(100), text: Stream.appLocalizer("get_capture_plan", id: "p1")),
        Line(delay: .milliseconds(100), text: Stream.command(buildCommand, id: "p2")),
        Line(delay: .milliseconds(100), text: Stream.command("xcrun simctl io booted screenshot /tmp/lumen-today.png", id: "p3")),
    ], exitStatus: nil)
}
#endif
