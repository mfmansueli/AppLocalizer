//
//  ClaudeCodeHelperScriptTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The helper saved in the scripts folder: what `check` answers, its exit
/// line, and the script's own text.
@Suite("Claude Code helper script")
struct ClaudeCodeHelperScriptTests {
    @Test func checkFindsClaudeCodeAndShortensItsVersion() {
        let output = "helper 1\nclaude /Users/sam/.local/bin/claude\nversion 2.1.316 (Claude Code)\n"
        let installation = ClaudeCodeInstallation(path: "/Users/sam/.local/bin/claude", version: "2.1.316", helperVersion: 1)
        #expect(ClaudeCodeHelperScript.parseCheck(output) == .found(installation))
        #expect(installation.title == "Claude Code 2.1.316")
        #expect(installation.displayPath(home: "/Users/sam") == "~/.local/bin/claude")
    }

    @Test func checkWithoutAVersionStillFindsIt() {
        let result = ClaudeCodeHelperScript.parseCheck("helper 2\nclaude /opt/homebrew/bin/claude")
        #expect(result == .found(ClaudeCodeInstallation(path: "/opt/homebrew/bin/claude", version: "", helperVersion: 2)))
        #expect(ClaudeCodeInstallation(path: "", version: "", helperVersion: 2).title == "Claude Code")
    }

    @Test func checkSaysWhenClaudeCodeIsMissing() {
        #expect(ClaudeCodeHelperScript.parseCheck("helper 1\nclaude-missing") == .claudeMissing(helperVersion: 1))
    }

    @Test(arguments: ["", "zsh: permission denied", "claude /usr/bin/claude", "helper one\nclaude /x", "helper 1"])
    func anythingElseIsUnreadable(output: String) {
        #expect(ClaudeCodeHelperScript.parseCheck(output) == .unreadable)
    }

    @Test func theExitLineCarriesTheStatus() {
        #expect(ClaudeCodeHelperScript.exitStatus(in: "applocalizer-helper-exit 0") == 0)
        #expect(ClaudeCodeHelperScript.exitStatus(in: "applocalizer-helper-exit 143") == 143)
        #expect(ClaudeCodeHelperScript.exitStatus(in: #"{"type":"result"}"#) == nil)
        #expect(ClaudeCodeHelperScript.exitStatus(in: "applocalizer-helper-exit") == nil)
    }

    @Test func theScriptMatchesWhatTheAppExpects() {
        let script = ClaudeCodeHelperScript.contents
        #expect(script.hasPrefix("#!/bin/zsh"))
        #expect(script.contains("applocalizer-helper \(ClaudeCodeHelperScript.version)"))
        #expect(script.contains("helper_version=\(ClaudeCodeHelperScript.version)\n"))
        #expect(script.contains("\(ClaudeCodeHelperScript.exitMarker) $code"))
        #expect(script.contains("return \(ClaudeCodeRunFailure.claudeMissingStatus)"))
        #expect(script.contains("return \(ClaudeCodeRunFailure.folderMissingStatus)"))
        // Stop is a terminate: a background job ignores interrupts.
        #expect(script.contains("kill -TERM $pid"))
        // Claude Code gets pipes of its own, so AppLocalizer's never turns
        // non-blocking and the exit line always gets through.
        #expect(script.contains(#"$claude "$@" </dev/null > >(cat) 2> >(cat >&2) &"#))
        #expect(ClaudeCodeHelperScript.version >= 4)
        // Autopilot's simulator check and fix: fixed commands, checked
        // arguments.
        #expect(script.contains("/usr/bin/xcrun simctl list -j runtimes devicetypes devices"))
        #expect(script.contains("iOS|watchOS|visionOS|tvOS) ;;"))
        #expect(script.contains("/usr/bin/xcodebuild -downloadPlatform $1"))
        #expect(script.contains("$type != com.apple.CoreSimulator.SimDeviceType.*"))
        #expect(script.contains("/usr/bin/xcrun simctl create $name $type $runtime"))
        // iPhone Duo (`DuoWatcher`): fixed commands on a simulator and display
        // checked to be identifiers, each with a time limit, as a stuck
        // simulator can keep simctl waiting; the timer holds no pipe.
        #expect(script.contains("[[ ${#1} == 36 && $1 != *[^0-9A-F-]* ]]"))
        #expect(script.contains("( /bin/sleep $seconds && kill -TERM $pid ) </dev/null >/dev/null 2>&1 &"))
        #expect(script.contains("with_limit 30 /usr/bin/xcrun simctl io $1 enumerate"))
        #expect(script.contains("with_limit 30 /usr/bin/xcrun simctl io $udid screenshot --display=$display $file >/dev/null"))
        #expect(script.contains("/usr/bin/sips -Z 256 $file"))
        #expect(script.contains("/usr/bin/base64 -i $file"))
        // Crashes since it started: its launchd_bootstrap.plist is written then.
        #expect(script.contains("[[ $report -nt $started ]] || continue"))
        #expect(script.contains("/usr/bin/grep -q \"SimDevice.$1\" $report"))
        #expect(script.contains("with_limit 300 /usr/bin/xcrun simctl bootstatus $1 -b"))
        #expect(script.contains("with_limit 120 /usr/bin/xcrun simctl shutdown $1"))
        // An older helper is told apart by its usage line, which stays one line.
        #expect(script.contains("| simulator-crashes <udid> | boot-simulator <udid> | shutdown-simulator <udid>\"\n"))
        #expect(ClaudeCodeHelperScript.fileName.hasSuffix(".zsh"))
    }
}
