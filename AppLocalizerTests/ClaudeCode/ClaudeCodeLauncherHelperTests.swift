//
//  ClaudeCodeLauncherHelperTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The helper in the scripts folder, and each app's project folder.
@MainActor
@Suite("ClaudeCodeLauncher · helper and folders")
struct ClaudeCodeLauncherHelperTests {
    private let assistants = MCPTestFixtures.controller()
    private let runner = FakeUnixScriptRunner()

    private func launcher(
        defaults: UserDefaults? = nil,
        chosenFolder: String? = ClaudeCodeTestFixtures.lumenFolder,
        asked: ClaudeCodeTestFixtures.FolderRequests = .init()
    ) -> ClaudeCodeLauncher {
        ClaudeCodeTestFixtures.launcher(assistants: assistants, runner: runner, defaults: defaults, chosenFolder: chosenFolder, asked: asked)
    }

    @Test func aMissingHelperCantStart() async {
        runner.helperExists = false
        let launcher = launcher()
        #expect(launcher.helper == .unknown)
        await launcher.refreshHelper()
        #expect(launcher.helper == .notInstalled)
        #expect(!launcher.canStart)
        #expect(runner.recordedArguments.isEmpty)
        #expect(launcher.helper.installTitle == "Install Helper…")
        #expect(!launcher.helper.isInstalled)
    }

    @Test func theHelperFindsClaudeCode() async {
        let launcher = launcher()
        await launcher.refreshHelper()
        let installation = ClaudeCodeInstallation(path: FakeUnixScriptRunner.claudePath, version: "2.1.316", helperVersion: ClaudeCodeHelperScript.version)
        #expect(launcher.helper == .ready(installation))
        #expect(launcher.canStart)
        #expect(runner.recordedArguments == [["check"]])
        #expect(launcher.helper.installTitle == nil)
        #expect(launcher.helper.detail == "Claude Code 2.1.316 · ~/.local/bin/claude")
    }

    @Test func anOlderHelperNeedsSavingAgain() async {
        runner.checkLines = ["helper 0", "claude /usr/local/bin/claude"]
        let launcher = launcher()
        await launcher.refreshHelper()
        #expect(launcher.helper == .outdated(installedVersion: 0))
        #expect(launcher.helper.installTitle == "Save the Helper Again…")

        runner.checkLines = ["helper 0", "claude-missing"]
        await launcher.refreshHelper()
        #expect(launcher.helper == .outdated(installedVersion: 0))

        // Version 1 shared AppLocalizer's pipe with Claude Code, which can
        // lose a run's end.
        runner.checkLines = ["helper 1", "claude /usr/local/bin/claude"]
        await launcher.refreshHelper()
        #expect(launcher.helper == .outdated(installedVersion: 1))
        #expect(!launcher.canStart)
    }

    /// Version 2 runs Claude Code as this one does: a run doesn't stop for
    /// the update, and the helper still asks to be saved again.
    @Test func anOlderHelperThatStillRunsClaudeCodeIsReadyAndAsksForTheUpdate() async {
        #expect(ClaudeCodeHelperScript.minimumRunVersion == 2)
        runner.checkLines = ["helper 2", "claude /usr/local/bin/claude", "version 2.1.316 (Claude Code)"]
        let launcher = launcher()
        await launcher.refreshHelper()
        #expect(launcher.canStart)
        #expect(launcher.helper.isOlder)
        #expect(launcher.helper.title == "Helper needs updating")
        #expect(launcher.helper.installTitle == "Save the Helper Again…")
        #expect(launcher.helper.detail.contains("still starts"))

        runner.checkLines = FakeUnixScriptRunner.foundLines
        await launcher.refreshHelper()
        #expect(!launcher.helper.isOlder)
        #expect(launcher.helper.installTitle == nil)
    }

    @Test func noClaudeCodeOnThisMac() async {
        runner.checkLines = ["helper \(ClaudeCodeHelperScript.version)", "claude-missing"]
        let launcher = launcher()
        await launcher.refreshHelper()
        #expect(launcher.helper == .claudeMissing)
        #expect(launcher.helper.isInstalled)
        #expect(!launcher.canStart)
    }

    @Test func aHelperThatCantRunSaysWhy() async {
        runner.checkLines = []
        runner.taskError = "The file “Start Claude Code.zsh” couldn’t be opened because you don’t have permission to view it."
        let launcher = launcher()
        await launcher.refreshHelper()
        #expect(launcher.helper == .failed(runner.taskError ?? ""))

        runner.taskError = nil
        runner.errorOutput = "zsh: permission denied\n"
        await launcher.refreshHelper()
        #expect(launcher.helper == .failed("zsh: permission denied"))

        runner.errorOutput = ""
        await launcher.refreshHelper()
        #expect(launcher.helper == .failed("The helper didn’t answer."))
    }

    @Test func startingBeforeTheFirstCheckChecksFirst() async {
        let launcher = launcher()
        let id = await launcher.start(.test, appID: ClaudeCodeTestFixtures.lumenID, appName: "Lumen Journal", prompt: "List my apps")
        #expect(id != nil)
        #expect(launcher.canStart)
        #expect(runner.recordedArguments.first == ["check"])
    }

    @Test func withoutTheHelperNothingStarts() async {
        let launcher = launcher()
        await launcher.refreshHelper()
        // Deleted since the last check.
        runner.helperExists = false
        let id = await launcher.start(.test, appID: ClaudeCodeTestFixtures.lumenID, appName: "Lumen Journal", prompt: "List my apps")
        #expect(id == nil)
        #expect(launcher.helper == .notInstalled)
        #expect(launcher.runs.isEmpty)
    }

    @Test func theFirstRunAsksForTheFolderOnce() async {
        let asked = ClaudeCodeTestFixtures.FolderRequests()
        let defaults = MCPTestFixtures.defaults()
        let launcher = launcher(defaults: defaults, asked: asked)
        await launcher.refreshHelper()

        let first = await launcher.start(.test, appID: ClaudeCodeTestFixtures.lumenID, appName: "Lumen Journal", prompt: "List my apps")
        await ClaudeCodeTestFixtures.waitForEnd(of: first, in: launcher)
        _ = await launcher.start(.test, appID: ClaudeCodeTestFixtures.lumenID, appName: "Lumen Journal", prompt: "List my apps")

        #expect(asked.requests.map(\.appName) == ["Lumen Journal"])
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == ClaudeCodeTestFixtures.lumenFolder)
        #expect(runner.lastRunArguments?.prefix(2) == ["run", ClaudeCodeTestFixtures.lumenFolder])

        // Remembered for the next launch, with the app's name.
        let reopened = ClaudeCodeTestFixtures.launcher(assistants: MCPTestFixtures.controller(), defaults: defaults)
        #expect(reopened.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == ClaudeCodeTestFixtures.lumenFolder)
        #expect(reopened.knownApps.map(\.name) == ["Lumen Journal"])
    }

    @Test func cancellingTheFolderStartsNothing() async {
        let launcher = launcher(chosenFolder: nil)
        await launcher.refreshHelper()
        let id = await launcher.start(.test, appID: ClaudeCodeTestFixtures.lumenID, appName: "Lumen Journal", prompt: "List my apps")
        #expect(id == nil)
        #expect(launcher.runs.isEmpty)
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == nil)
    }

    @Test func theOpenPanelStartsWhereClaudeCodeLastWorked() throws {
        let asked = ClaudeCodeTestFixtures.FolderRequests()
        let launcher = launcher(asked: asked)
        var paired = MCPTestFixtures.pair(.claudeCode, in: assistants, at: .now).client
        paired.workingDirectory = "~/Developer/Lumen"
        assistants.restorePairings([paired], tokens: assistants.tokens)
        #expect(launcher.suggestedFolder(for: ClaudeCodeTestFixtures.lumenID) == ProjectFolderPath.expanded("~/Developer/Lumen"))

        launcher.chooseProjectFolder(for: ClaudeCodeTestFixtures.tempoID, appName: "Tempo Metronome")
        let request = try #require(asked.requests.first)
        #expect(request.appName == "Tempo Metronome")
        #expect(request.suggestion == ProjectFolderPath.expanded("~/Developer/Lumen"))
        // A chosen folder wins over the suggestion.
        #expect(launcher.suggestedFolder(for: ClaudeCodeTestFixtures.tempoID) == ClaudeCodeTestFixtures.lumenFolder)
    }

    @Test func appsAreListedByNameAndFoldersCanBeForgotten() {
        let defaults = MCPTestFixtures.defaults()
        let launcher = launcher(defaults: defaults)
        launcher.rememberApp(ClaudeCodeTestFixtures.tempoID, name: "Tempo Metronome")
        launcher.rememberApp(ClaudeCodeTestFixtures.lumenID, name: "Lumen Journal")
        launcher.rememberApp(ClaudeCodeTestFixtures.lumenID, name: "")
        #expect(launcher.knownApps.map(\.name) == ["Lumen Journal", "Tempo Metronome"])

        launcher.setProjectFolder("/Users/sam/Tempo", for: ClaudeCodeTestFixtures.tempoID)
        launcher.setProjectFolder(nil, for: ClaudeCodeTestFixtures.tempoID)
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.tempoID) == nil)
        #expect(ClaudeCodeTestFixtures.launcher(assistants: assistants, defaults: defaults).projectFolder(for: ClaudeCodeTestFixtures.tempoID) == nil)
    }
}
