//
//  ClaudeCodeDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Board 22 of the design: Claude Code started by AppLocalizer, through the
/// pretend helper (`DebugUnixScriptRunner`), in Lumen Journal's folder:
/// - `cc-setup`, `cc-setup-installed`, `cc-setup-test`: setup's step 3
///   before and after the helper is saved, and step 4's test run
///   connecting on its own.
/// - `cc-ask`, `cc-everything`: Ask on the Store Page and Suggest
///   Everything on Overview, started and working.
/// - `cc-output`: Show Output for a finished run.
/// - `cc-login`: Ask while Claude Code isn't logged in; `cc-denied`:
///   Suggest Everything finished with two refused steps.
/// - `cc-settings` (opened by `SettingsDebugScenes`): Settings → AI
///   Assistants with the helper and the project folders.
/// - `cc-toolbar`: the Assistant button's popover with two runs going.
/// - `cc-hint`: Ask without the helper, offering to set it up.
/// - `cc-live`: not pretend: setup's test prompt through the helper really
///   saved in the scripts folder, with the real Claude Code, AppLocalizer's
///   server on port 47399 (so it never meets the real app's), and Show
///   Output open. `CC_LIVE_FOLDER` picks the folder (home by default);
///   `CC_LIVE_STOP_AFTER` stops it after that many seconds.
///
/// Every other scene has no helper, so its prompts are copied as before.
enum ClaudeCodeDebugScenes {
    static let ids = [
        "cc-setup", "cc-setup-installed", "cc-setup-test", "cc-ask", "cc-everything", "cc-output",
        "cc-login", "cc-denied", "cc-settings", "cc-toolbar", "cc-hint", "cc-live",
    ]

    /// Other scenes with the pretend helper: Product Page Optimization's
    /// variant request.
    static let helperScenes = ["shots-ppo-asking"]

    static let livePort: UInt16 = 47399

    static func isLive(_ id: String) -> Bool {
        id == "cc-live"
    }

    /// The real helper for `cc-live`, else the pretend one.
    static func scriptRunner(for id: String) -> any UnixScriptRunning {
        isLive(id) ? LiveUnixScriptRunner() : runner(for: id)
    }

    /// The pretend helper for a scene.
    static func runner(for id: String) -> DebugUnixScriptRunner {
        var runner = DebugUnixScriptRunner()
        switch id {
        case "cc-setup-installed", "cc-setup-test": runner.script = ClaudeCodeDebugScripts.test
        case "cc-ask": runner.script = ClaudeCodeDebugScripts.askWorking
        case "cc-everything": runner.script = ClaudeCodeDebugScripts.everythingWorking
        case "cc-output": runner.script = ClaudeCodeDebugScripts.everythingFinished
        case "cc-login": runner.script = ClaudeCodeDebugScripts.notLoggedIn
        case "cc-denied": runner.script = ClaudeCodeDebugScripts.denied
        case "cc-toolbar":
            runner.script = ClaudeCodeDebugScripts.everythingWorking
            runner.scripts = [ClaudeCodeRunPurpose.autopilot.title: ClaudeCodeDebugScripts.autopilotWorking]
        case "cc-settings": break
        case "shots-ppo-asking": runner.script = ClaudeCodeDebugScripts.variantWorking
        default: runner.helperExists = false
        }
        return runner
    }

    /// Lumen Journal's project folder, and Tempo Metronome's chosen in the
    /// Open panel.
    @MainActor
    static func configure(_ launcher: ClaudeCodeLauncher, for id: String) {
        guard ids.contains(id) || helperScenes.contains(id) else { return }
        AssistantsSettingsTab.debugScrollsToLauncher = id == "cc-settings"
        launcher.folderChooser = { _, _ in ProjectFolderPath.expanded("~/Developer/Tempo") }
        let folder = isLive(id)
            ? ProcessInfo.processInfo.environment["CC_LIVE_FOLDER"] ?? ProjectFolderPath.home
            : ProjectFolderPath.expanded("~/Developer/Lumen")
        launcher.setProjectFolder(folder, for: DebugFixtures.AppID.lumen)
        launcher.rememberApp(DebugFixtures.AppID.lumen, name: "Lumen Journal")
        launcher.rememberApp(DebugFixtures.AppID.tempo, name: "Tempo Metronome")
    }

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "cc-setup", "cc-setup-installed", "cc-setup-test":
            AssistantSetupSheet.debugStep = id == "cc-setup-test" ? .test : .snippet
            let scene = DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store(includesAssistant: false), presentedSheet: .assistantSetup)
            return SuggestionsDebugScenes.with(.pairing, scene)
        case "cc-ask", "cc-login", "cc-hint":
            return SuggestionsDebugScenes.storePage(.connected) { model in
                model.openEditor(.englishUS)
                model.requestsAsk = true
            }
        case "cc-everything", "cc-denied":
            OverviewSectionView.debugRequestsSuggestEverything = true
            return overview()
        case "cc-output":
            return AnyView(overview().modifier(StartsRuns(purposes: [.suggestEverything], showsOutput: true)))
        case "cc-toolbar":
            AssistantToolbarIndicator.debugShowsPopover = true
            return AnyView(overview().modifier(StartsRuns(purposes: [.suggestEverything, .autopilot])))
        case "cc-live":
            let stopsAfter = ProcessInfo.processInfo.environment["CC_LIVE_STOP_AFTER"].flatMap(Double.init)
            return AnyView(overview().modifier(StartsRuns(purposes: [.test], showsOutput: true, waitsForEnd: false, stopsAfter: stopsAfter)))
        default:
            return nil
        }
    }

    @MainActor
    private static func overview() -> AnyView {
        SuggestionsDebugScenes.with(.connected, DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store()))
    }

    /// Starts runs for Lumen Journal as the scene appears, as if the person
    /// had asked; with `showsOutput`, opens Show Output once the first ends
    /// (or at once).
    private struct StartsRuns: ViewModifier {
        let purposes: [ClaudeCodeRunPurpose]
        var showsOutput = false
        var waitsForEnd = true
        /// Seconds after which the first run is stopped, as if Stop was
        /// clicked.
        var stopsAfter: Double?
        @Environment(ClaudeCodeLauncher.self) private var launcher

        func body(content: Content) -> some View {
            content.task {
                for purpose in purposes {
                    let prompt = purpose == .test
                        ? AssistantSetupViewModel.testPrompt
                        : String(localized: "\(purpose.title) for Lumen Journal 1.4 with AppLocalizer’s tools.")
                    guard let id = await launcher.start(purpose, appID: DebugFixtures.AppID.lumen, appName: "Lumen Journal", prompt: prompt),
                          showsOutput else { continue }
                    while waitsForEnd, launcher.run(id)?.isActive == true {
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                    launcher.shownRunID = id
                    if let stopsAfter {
                        try? await Task.sleep(for: .seconds(stopsAfter))
                        launcher.stop(id)
                    }
                }
            }
        }
    }
}
#endif
