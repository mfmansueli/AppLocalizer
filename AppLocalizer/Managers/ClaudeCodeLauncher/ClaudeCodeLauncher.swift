//
//  ClaudeCodeLauncher.swift
//  AppLocalizer
//

import Foundation
import Observation
import Synchronization

/// Starts the person's own Claude Code from AppLocalizer, so Ask, Suggest
/// Everything, Autopilot and the rest need no Terminal and nothing pasted.
/// The sandbox doesn't let the app start programs, so it goes through the
/// helper the person saved once in the app's scripts folder
/// (`ClaudeCodeHelperScript`), which macOS runs outside the sandbox.
///
/// Each run is a restricted print run in the app's project folder
/// (`ClaudeCodeInvocation`), connected only to AppLocalizer's server with a
/// token made for that run and dropped when it ends. What it suggests or
/// captures arrives over MCP as usual; the launcher keeps the run's own
/// story (`ClaudeCodeRun`): its phase, each step, the result, and why it
/// failed. Without the helper every screen keeps copying its prompt.
@MainActor
@Observable
final class ClaudeCodeLauncher {
    private(set) var helper: ClaudeCodeHelperState = .unknown
    /// Recent runs, oldest first.
    private(set) var runs: [ClaudeCodeRun] = []
    /// Each app's project folder, absolute.
    private(set) var projectFolders: [StoreApp.ID: String]
    /// The names of apps a run started for or a folder was chosen for, so
    /// Settings can list them without the library.
    private(set) var appNames: [StoreApp.ID: String]
    /// Why Install Helper… couldn't save it.
    var installError: String?
    /// The run Show Output shows.
    var shownRunID: ClaudeCodeRun.ID?

    @ObservationIgnored let assistants: MCPServerController
    /// This Mac's simulators, asked through the same helper.
    @ObservationIgnored let simulators: MacSimulators
    @ObservationIgnored private let runner: any UnixScriptRunning
    @ObservationIgnored let helperURL: URL?
    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let now: () -> Date
    /// Asks the person for an app's project folder: an Open panel, canned
    /// in tests and DEBUG scenes.
    @ObservationIgnored var folderChooser: @MainActor (_ appName: String, _ suggestion: String?) -> String?
    /// Told when a run ends, however it ended: Autopilot starts Claude Code
    /// again when it stopped with work left (`AutopilotContinuation`).
    @ObservationIgnored var onRunEnded: (@MainActor (ClaudeCodeRun) -> Void)?
    @ObservationIgnored private var tasks: [ClaudeCodeRun.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var stopRequested: Set<ClaudeCodeRun.ID> = []
    @ObservationIgnored private var exitStatuses: [ClaudeCodeRun.ID: Int32] = [:]
    @ObservationIgnored private var serverFailed: Set<ClaudeCodeRun.ID> = []
    @ObservationIgnored private var nextActivityID = 0

    /// Runs kept for Show Output, the oldest finished ones going first.
    static let runLimit = 12

    /// How long the helper has to end after Claude Code's result, its last
    /// word, before the run counts as ended anyway and the helper is told
    /// to stop: a helper that never ends must not keep a run "working",
    /// which holds back Continue and Retry.
    @ObservationIgnored var resultGrace: Duration = .seconds(60)

    init(
        assistants: MCPServerController,
        runner: any UnixScriptRunning = LiveUnixScriptRunner(),
        helperURL: URL? = ClaudeCodeHelperInstaller.helperURL,
        defaults: UserDefaults? = nil,
        now: @escaping () -> Date = Date.init,
        folderChooser: @escaping @MainActor (String, String?) -> String? = ClaudeCodeFolderPicker.choose,
        simulatorRunner: (any UnixScriptRunning)? = nil
    ) {
        self.assistants = assistants
        self.runner = runner
        self.helperURL = helperURL
        simulators = MacSimulators(runner: simulatorRunner ?? runner, helperURL: helperURL)
        self.defaults = defaults
        self.now = now
        self.folderChooser = folderChooser
        projectFolders = (defaults?.dictionary(forKey: Key.projectFolders) as? [String: String]) ?? [:]
        appNames = (defaults?.dictionary(forKey: Key.appNames) as? [String: String]) ?? [:]
        assistants.launcher = self
    }

    // MARK: - Reading

    /// The helper is in place and found Claude Code.
    var canStart: Bool { helper.isReady }

    var activeRuns: [ClaudeCodeRun] { runs.filter(\.isActive) }

    func run(_ id: ClaudeCodeRun.ID?) -> ClaudeCodeRun? {
        guard let id else { return nil }
        return runs.first { $0.id == id }
    }

    /// The newest run for `purpose` in this app; with `date`, only one
    /// started since then, e.g. for the request a screen opened.
    func latestRun(appID: StoreApp.ID, purpose: ClaudeCodeRunPurpose, since date: Date? = nil) -> ClaudeCodeRun? {
        guard let run = runs.last(where: { $0.appID == appID && $0.purpose == purpose }) else { return nil }
        if let date, run.startedAt < date.addingTimeInterval(-1) { return nil }
        return run
    }

    func projectFolder(for appID: StoreApp.ID) -> String? {
        projectFolders[appID]
    }

    /// The apps Settings lists, by name.
    var knownApps: [(id: StoreApp.ID, name: String)] {
        appNames.map { (id: $0.key, name: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Where the Open panel starts: the folder the paired Claude Code last
    /// worked in, else the API key's project folder.
    func suggestedFolder(for appID: StoreApp.ID) -> String? {
        if let folder = projectFolders[appID] { return folder }
        let claudeCode = assistants.pairedClients.last { $0.kind == .claudeCode && $0.workingDirectory != nil }
        if let directory = claudeCode?.workingDirectory { return ProjectFolderPath.expanded(directory) }
        return assistants.keyAssistant?.configuration?.projectFolderPath.map { ProjectFolderPath.expanded($0) }
    }

    // MARK: - Helper

    /// Looks for the helper and asks it where Claude Code is.
    func refreshHelper() async {
        guard let helperURL, runner.exists(helperURL) else {
            helper = .notInstalled
            return
        }
        helper = .checking
        let lines = Mutex<[String]>([])
        let exit = await runner.run(helperURL, arguments: ["check"]) { line in
            lines.withLock { $0.append(line) }
        }
        let output = lines.withLock { $0.joined(separator: "\n") }
        switch ClaudeCodeHelperScript.parseCheck(output) {
        case let .found(installation) where installation.helperVersion < ClaudeCodeHelperScript.minimumRunVersion:
            helper = .outdated(installedVersion: installation.helperVersion)
        case let .found(installation):
            // An older helper that still runs Claude Code is ready, and
            // asks to be saved again for what's new.
            helper = .ready(installation)
        case let .claudeMissing(version) where version < ClaudeCodeHelperScript.minimumRunVersion:
            helper = .outdated(installedVersion: version)
        case .claudeMissing:
            helper = .claudeMissing
        case .unreadable:
            helper = .failed(exit.taskError ?? exit.lastErrorLine ?? String(localized: "The helper didn’t answer."))
        }
    }

    /// Install Helper…: the Save panel, then a fresh check.
    func installHelper() async {
        installError = nil
        do {
            guard try ClaudeCodeHelperInstaller.install() else { return }
        } catch {
            installError = error.localizedDescription
            return
        }
        await refreshHelper()
    }

    // MARK: - Folders

    func setProjectFolder(_ path: String?, for appID: StoreApp.ID) {
        projectFolders[appID] = path
        defaults?.set(projectFolders, forKey: Key.projectFolders)
    }

    /// Keeps `name` for Settings' list of folders.
    func rememberApp(_ appID: StoreApp.ID, name: String) {
        guard !name.isEmpty, appNames[appID] != name else { return }
        appNames[appID] = name
        defaults?.set(appNames, forKey: Key.appNames)
    }

    /// Choose…: the Open panel for `appName`'s folder. Returns the folder,
    /// or nil when the person cancelled.
    @discardableResult
    func chooseProjectFolder(for appID: StoreApp.ID, appName: String) -> String? {
        guard let folder = folderChooser(appName, suggestedFolder(for: appID)) else { return nil }
        setProjectFolder(folder, for: appID)
        rememberApp(appID, name: appName)
        return folder
    }

    // MARK: - Runs

    /// Starts Claude Code for `purpose` with `prompt`, asking for the
    /// project folder the first time. Returns the run (the one already
    /// going, for the same purpose), or nil when it can't start here: no
    /// helper, or no folder chosen. Callers copy the prompt then.
    func start(_ purpose: ClaudeCodeRunPurpose, appID: StoreApp.ID, appName: String, prompt: String) async -> ClaudeCodeRun.ID? {
        // Asked right as AppLocalizer opens, before or during the first
        // check.
        if helper == .unknown || helper == .checking { await refreshHelper() }
        guard canStart, let helperURL else { return nil }
        guard runner.exists(helperURL) else {
            helper = .notInstalled
            return nil
        }
        if let active = latestRun(appID: appID, purpose: purpose), active.isActive { return active.id }
        guard let folder = projectFolder(for: appID) ?? chooseProjectFolder(for: appID, appName: appName) else { return nil }
        rememberApp(appID, name: appName)
        let run = ClaudeCodeRun(
            id: UUID(),
            appID: appID,
            appName: appName,
            purpose: purpose,
            prompt: prompt,
            workingDirectory: folder,
            startedAt: now()
        )
        append(run)
        if let problem = await assistants.startForLaunch() {
            end(run.id, as: .failed(.serverUnavailable(problem)))
            return run.id
        }
        guard let clientID = assistants.launchClientID() else {
            end(run.id, as: .failed(.serverUnavailable(String(localized: "Couldn’t pair Claude Code."))))
            return run.id
        }
        let token = assistants.issueRunToken(for: clientID)
        let invocation = ClaudeCodeInvocation(
            workingDirectory: folder,
            prompt: prompt,
            permissions: purpose.permissions,
            port: assistants.port,
            token: token,
            sessionName: "AppLocalizer · \(purpose.title) · \(appName)"
        )
        launch(run.id, helperURL: helperURL, invocation: invocation)
        return run.id
    }

    /// Try Again: the same request as a new run, after choosing the folder
    /// again when it was missing.
    func retry(_ id: ClaudeCodeRun.ID) async -> ClaudeCodeRun.ID? {
        guard let run = run(id), !run.isActive else { return nil }
        if run.failure?.needsFolder == true {
            guard chooseProjectFolder(for: run.appID, appName: run.appName) != nil else { return nil }
        }
        return await start(run.purpose, appID: run.appID, appName: run.appName, prompt: run.prompt)
    }

    /// Open in Terminal: an interactive Claude Code in the run's folder with
    /// its prompt typed in. False when Claude Code's link isn't set up on
    /// this Mac, or the prompt is too long for it.
    @discardableResult
    func openInTerminal(_ id: ClaudeCodeRun.ID) -> Bool {
        guard let run = run(id) else { return false }
        return ClaudeCodeDeepLink.open(folder: run.workingDirectory, prompt: run.prompt)
    }

    /// Stop: the helper ends Claude Code; what it already sent stays.
    func stop(_ id: ClaudeCodeRun.ID) {
        guard let task = tasks[id] else { return }
        stopRequested.insert(id)
        task.cancel()
    }

    /// Forgets a run that ended.
    func dismiss(_ id: ClaudeCodeRun.ID) {
        guard run(id)?.isActive == false else { return }
        runs.removeAll { $0.id == id }
        if shownRunID == id { shownRunID = nil }
    }

    private func launch(_ id: ClaudeCodeRun.ID, helperURL: URL, invocation: ClaudeCodeInvocation) {
        let (lines, continuation) = AsyncStream<String>.makeStream()
        let runner = runner
        let arguments = invocation.helperArguments
        let token = invocation.token
        tasks[id] = Task { [weak self] in
            async let exit: UnixScriptExit = {
                let exit = await runner.run(helperURL, arguments: arguments) { continuation.yield($0) }
                continuation.finish()
                return exit
            }()
            var grace: Task<Void, Never>?
            for await line in lines {
                guard let self else { continue }
                receive(line, for: id)
                if grace == nil, run(id)?.result != nil {
                    grace = endAfterGrace(id, token: token)
                }
            }
            let ended = await exit
            grace?.cancel()
            self?.complete(id, exit: ended, token: token)
        }
    }

    /// Ends the run on its result when the helper hasn't ended
    /// `resultGrace` after it, and tells the helper to stop.
    private func endAfterGrace(_ id: ClaudeCodeRun.ID, token: String) -> Task<Void, Never> {
        let grace = resultGrace
        return Task { [weak self] in
            guard await (try? Task.sleep(for: grace)) != nil, let self, run(id)?.isActive == true else { return }
            tasks[id]?.cancel()
            complete(id, exit: UnixScriptExit(), token: token)
        }
    }

    private func receive(_ line: String, for id: ClaudeCodeRun.ID) {
        if let status = ClaudeCodeHelperScript.exitStatus(in: line) {
            exitStatuses[id] = status
            return
        }
        for event in ClaudeCodeStreamParser.events(in: line) {
            update(id) { run in apply(event, to: &run, id: id) }
        }
    }

    private func apply(_ event: ClaudeCodeStreamEvent, to run: inout ClaudeCodeRun, id: ClaudeCodeRun.ID) {
        switch event {
        case let .started(sessionID, _, version, failedServers):
            run.phase = .working
            run.sessionID = sessionID
            run.claudeVersion = version
            note(.started, version.map { String(localized: "Claude Code \($0) started") } ?? String(localized: "Claude Code started"), in: &run)
            if failedServers.contains(MCPEndpoint.serverName) {
                serverFailed.insert(id)
                note(.problem, String(localized: "AppLocalizer’s server didn’t connect."), in: &run)
            }
        case let .said(text):
            note(.said, text.count > 600 ? String(text.prefix(599)) + "…" : text, in: &run)
        case let .usedTool(use):
            if use.kind == .appLocalizer { run.appLocalizerCalls += 1 }
            nextActivityID += 1
            run.activity.append(ClaudeCodeActivity(id: nextActivityID, date: now(), toolUse: use))
        case let .toolFailed(toolUseID, message):
            let step = run.activity.last { $0.toolUseID == toolUseID }?.text ?? String(localized: "A step")
            let reason = message.split(whereSeparator: \.isNewline).first.map(String.init) ?? message
            note(.problem, String(localized: "\(step) failed: \(reason)"), in: &run)
        case let .finished(result):
            run.result = result
            if run.sessionID == nil { run.sessionID = result.sessionID }
        }
        if run.activity.count > ClaudeCodeRun.activityLimit {
            run.activity.removeFirst(run.activity.count - ClaudeCodeRun.activityLimit)
        }
    }

    private func note(_ kind: ClaudeCodeActivity.Kind, _ text: String, in run: inout ClaudeCodeRun) {
        nextActivityID += 1
        run.activity.append(ClaudeCodeActivity(id: nextActivityID, date: now(), kind: kind, text: text))
    }

    /// Once: a run already ended on its result (`endAfterGrace`) stays
    /// as it ended when its helper ends after all.
    private func complete(_ id: ClaudeCodeRun.ID, exit: UnixScriptExit, token: String) {
        assistants.revokeRunToken(token)
        tasks[id] = nil
        let status = exitStatuses.removeValue(forKey: id)
        let didFailToConnect = serverFailed.remove(id) != nil
        let didStop = stopRequested.remove(id) != nil
        guard let run = run(id), run.isActive else { return }
        if didStop {
            end(id, as: .stopped)
        } else if let result = run.result, !result.isError {
            end(id, as: .finished)
        } else if didFailToConnect, run.appLocalizerCalls == 0, run.result?.isLoginProblem != true {
            end(id, as: .failed(.serverNotConnected))
        } else {
            let started = run.sessionID != nil
            end(id, as: .failed(.classify(status: status, result: run.result, exit: exit, folder: run.workingDirectory, started: started)))
        }
    }

    private func end(_ id: ClaudeCodeRun.ID, as phase: ClaudeCodeRun.Phase) {
        update(id) { run in
            run.phase = phase
            run.endedAt = now()
        }
        if let ended = run(id) { onRunEnded?(ended) }
    }

    private func append(_ run: ClaudeCodeRun) {
        runs.append(run)
        while runs.count > Self.runLimit, let oldest = runs.firstIndex(where: { !$0.isActive }) {
            runs.remove(at: oldest)
        }
    }

    private func update(_ id: ClaudeCodeRun.ID, _ change: (inout ClaudeCodeRun) -> Void) {
        guard let index = runs.firstIndex(where: { $0.id == id }) else { return }
        change(&runs[index])
    }

    enum Key {
        static let projectFolders = "claudeCode.projectFolders"
        static let appNames = "claudeCode.appNames"
    }
}
