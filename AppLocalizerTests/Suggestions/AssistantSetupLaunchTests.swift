//
//  AssistantSetupLaunchTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Setup with AppLocalizer starting Claude Code: step 3 waits for the
/// helper, step 4 runs the test itself and connects on its own.
@MainActor
@Suite("AssistantSetupViewModel · Claude Code started by AppLocalizer")
struct AssistantSetupLaunchTests {
    private typealias Lines = ClaudeCodeTestFixtures
    private let clock = TestClock()
    private let assistants: MCPServerController
    private let runner = FakeUnixScriptRunner()
    private let launcher: ClaudeCodeLauncher

    init() {
        assistants = MCPTestFixtures.controller(clock: clock)
        launcher = ClaudeCodeTestFixtures.launcher(assistants: assistants, runner: runner, clock: clock)
        runner.lines = [
            Lines.initLine(),
            Lines.toolUseLine("mcp__applocalizer__list_apps", id: "t1"),
            Lines.resultLine(text: "You have 6 apps in AppLocalizer."),
        ]
    }

    private func setup(appID: StoreApp.ID? = ClaudeCodeTestFixtures.lumenID, launcher: ClaudeCodeLauncher? = nil) -> AssistantSetupViewModel {
        let keyAssistant = KeyAssistantController(service: StubKeyAssistantService(), secrets: InMemorySecretStore(), defaults: nil)
        return AssistantSetupViewModel(
            assistants: assistants,
            keyAssistant: keyAssistant,
            appName: "Lumen Journal",
            appID: appID,
            launcher: launcher ?? self.launcher
        )
    }

    /// Steps 1 and 2, to the snippet.
    private func toSnippet(_ setup: AssistantSetupViewModel) {
        _ = setup.advance()
        setup.setServerOn(true)
        _ = setup.advance()
        #expect(setup.step == .snippet)
    }

    @Test func itsOfferedForClaudeCodeWithAnApp() {
        let setup = setup()
        #expect(setup.offersLaunch)
        #expect(setup.launches)
        setup.choose(.cursor)
        #expect(!setup.offersLaunch)
        #expect(!setup.launches)

        let withoutApp = self.setup(appID: nil)
        #expect(!withoutApp.offersLaunch)
        let keyAssistant = KeyAssistantController(service: StubKeyAssistantService(), secrets: InMemorySecretStore(), defaults: nil)
        let withoutLauncher = AssistantSetupViewModel(assistants: assistants, keyAssistant: keyAssistant, appName: "Lumen Journal")
        #expect(!withoutLauncher.offersLaunch)
    }

    @Test func setupOpenedBeforeTheAppListLoadedOffersItOnceTheAppArrives() {
        let setup = setup(appID: nil)
        #expect(!setup.offersLaunch)
        setup.setApp(id: ClaudeCodeTestFixtures.lumenID, name: "Lumen Journal")
        #expect(setup.offersLaunch)
        #expect(setup.launches)
        #expect(setup.key.appName == "Lumen Journal")
    }

    @Test func theSnippetStepWaitsForTheHelper() async {
        runner.helperExists = false
        let setup = setup()
        toSnippet(setup)
        await launcher.refreshHelper()
        #expect(!setup.canContinue)
        #expect(setup.footnote.isEmpty)

        runner.helperExists = true
        await launcher.refreshHelper()
        #expect(setup.canContinue)
        #expect(setup.footnote == "Next, AppLocalizer runs a test.")

        // Pasting a command needs no helper.
        runner.helperExists = false
        await launcher.refreshHelper()
        setup.chooseLaunch(false)
        #expect(!setup.launches)
        #expect(setup.canContinue)
    }

    @Test func choosingOnlyHappensOnTheSnippetStep() {
        let setup = setup()
        setup.chooseLaunch(false)
        #expect(setup.launches)
    }

    @Test func theTestRunConnectsOnItsOwn() async throws {
        await launcher.refreshHelper()
        let setup = setup()
        toSnippet(setup)
        #expect(!setup.advance())
        #expect(setup.step == .test)
        #expect(!setup.isConnected)
        #expect(setup.continueTitle == "Finish Without Testing")

        await setup.startTest()
        let run = try #require(setup.testRun)
        #expect(run.purpose == .test)
        #expect(run.prompt == AssistantSetupViewModel.testPrompt)
        #expect(run.workingDirectory == ClaudeCodeTestFixtures.lumenFolder)
        // The pending client was paired, and the run acts as it.
        #expect(assistants.pendingPairing == nil)
        #expect(assistants.pairedClients.count == 1)

        await ClaudeCodeTestFixtures.waitForEnd(of: run.id, in: launcher)
        #expect(setup.isConnected)
        #expect(setup.continueTitle == "Done")
        #expect(!setup.canGoBack)
        #expect(setup.advance())
        #expect(assistants.pairedClients.count == 1)
    }

    @Test func startingTwiceKeepsOneRun() async throws {
        runner.exitStatus = nil
        await launcher.refreshHelper()
        let setup = setup()
        toSnippet(setup)
        _ = setup.advance()
        await setup.startTest()
        let first = try #require(setup.testRunID)
        await ClaudeCodeTestFixtures.waitForHelper(runner)
        await setup.startTest()
        #expect(setup.testRunID == first)
        #expect(runner.recordedArguments.filter { $0.first == "run" }.count == 1)
        setup.cancel()
        await ClaudeCodeTestFixtures.waitForEnd(of: first, in: launcher)
    }

    @Test func theFolderClaudeCodeUsedIsSuggested() async {
        await launcher.refreshHelper()
        var paired = MCPTestFixtures.pair(.claudeCode, in: assistants, at: clock.now).client
        paired.workingDirectory = "/Users/sam/Developer/Lumen"
        assistants.restorePairings([paired], tokens: assistants.tokens)
        let setup = setup()
        toSnippet(setup)
        #expect(setup.projectFolder == "/Users/sam/Developer/Lumen")
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == nil)
        _ = setup.advance()
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == "/Users/sam/Developer/Lumen")
    }

    /// MB Admin's setup after Bruma's: the folder Claude Code last worked in
    /// is Bruma's, so it isn't kept for MB Admin; the person chooses it.
    @Test func anotherAppsFolderIsntKeptForThisOne() async {
        await launcher.refreshHelper()
        launcher.setProjectFolder("/Users/sam/Developer/Lumen", for: ClaudeCodeTestFixtures.tempoID)
        var paired = MCPTestFixtures.pair(.claudeCode, in: assistants, at: clock.now).client
        paired.workingDirectory = "/Users/sam/Developer/Lumen"
        assistants.restorePairings([paired], tokens: assistants.tokens)
        let setup = setup()
        toSnippet(setup)
        #expect(setup.projectFolder == nil, "Step 3 says Not chosen yet, with Choose…")
        _ = setup.advance()
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == nil)
    }

    /// A suggested folder whose projects plainly build another app isn't
    /// kept either.
    @Test func aSuggestionThatBuildsAnotherAppIsntKept() async {
        await launcher.refreshHelper()
        var paired = MCPTestFixtures.pair(.claudeCode, in: assistants, at: clock.now).client
        paired.workingDirectory = "/Users/sam/Developer/Tempo"
        assistants.restorePairings([paired], tokens: assistants.tokens)
        launcher.bundleIDLookup = { _ in "com.northpier.lumen" }
        launcher.folderChecker = { _ in ProjectFolderCheck(bundleIDs: ["com.northpier.tempo"], hasVariables: false) }
        let setup = setup()
        toSnippet(setup)
        #expect(setup.projectFolder == nil)
        launcher.folderChecker = { _ in ProjectFolderCheck(bundleIDs: ["com.northpier.lumen"], hasVariables: false) }
        #expect(setup.projectFolder == "/Users/sam/Developer/Tempo")
    }

    @Test func cancellingStopsTheTestAndUnpairs() async throws {
        runner.lines = [Lines.initLine()]
        runner.exitStatus = nil
        await launcher.refreshHelper()
        let setup = setup()
        toSnippet(setup)
        _ = setup.advance()
        await setup.startTest()
        let id = try #require(setup.testRunID)
        #expect(assistants.pairedClients.count == 1)

        setup.cancel()
        await ClaudeCodeTestFixtures.waitForEnd(of: id, in: launcher)
        #expect(launcher.run(id)?.phase == .stopped)
        #expect(assistants.pairedClients.isEmpty)
        #expect(assistants.runTokens.isEmpty)
    }

    @Test func aFailedTestIsntConnectedAndTryAgainIsUsed() async throws {
        runner.lines = [Lines.initLine(), Lines.resultLine(isError: true, text: "Not logged in · Please run /login")]
        runner.exitStatus = 1
        await launcher.refreshHelper()
        let setup = setup()
        toSnippet(setup)
        _ = setup.advance()
        await setup.startTest()
        let failed = try #require(setup.testRunID)
        await ClaudeCodeTestFixtures.waitForEnd(of: failed, in: launcher)
        #expect(!setup.isConnected)
        #expect(setup.testRun?.failure == .notLoggedIn("Not logged in · Please run /login"))

        runner.lines = [Lines.initLine(), Lines.toolUseLine("mcp__applocalizer__list_apps", id: "t1"), Lines.resultLine(text: "6 apps.")]
        runner.exitStatus = 0
        let retried = try #require(await launcher.retry(failed))
        setup.useTestRun(retried)
        await ClaudeCodeTestFixtures.waitForEnd(of: retried, in: launcher)
        #expect(setup.isConnected)
    }
}
