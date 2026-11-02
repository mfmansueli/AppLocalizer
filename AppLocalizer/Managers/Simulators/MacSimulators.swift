//
//  MacSimulators.swift
//  AppLocalizer
//

import Foundation
import Observation
import Synchronization

/// This Mac's simulators, for Screenshot Autopilot: whether each planned
/// device can be captured before the run starts, and the fix when it can't
/// (download the platform's simulator, make the simulator), and iPhone
/// Duo's, which starts closed (`duo`) and is captured from a recording of
/// its inner display (`recorder`). The app is sandboxed, so it asks the
/// Claude Code helper (`ClaudeCodeHelperScript`), which runs `xcrun simctl`
/// and `xcodebuild` outside the sandbox.
@MainActor
@Observable
final class MacSimulators {
    enum State: Hashable, Sendable {
        case unknown
        case checking
        case checked(SimulatorInventory)
        /// No helper to ask.
        case noHelper
        /// A helper from before it could list simulators.
        case oldHelper
        /// It couldn't read them: why.
        case failed(String)
    }

    private(set) var state: State = .unknown
    /// The device whose simulator is being installed or made.
    private(set) var working: ScreenshotDisplayType?
    /// `xcodebuild`'s latest progress line while it downloads.
    private(set) var progress: String?
    /// Why the last install or make didn't work.
    private(set) var failure: String?

    @ObservationIgnored private let runner: any UnixScriptRunning
    @ObservationIgnored private let helperURL: URL?

    /// iPhone Duo's simulator: whether it's open, and starting or
    /// restarting it.
    @ObservationIgnored private(set) lazy var duo = DuoWatcher(simulators: self)
    /// Records iPhone Duo's inner display during a UI test, whose own
    /// screenshot there is the cover display.
    @ObservationIgnored private(set) lazy var recorder = DisplayRecorder(simulators: self)

    init(runner: any UnixScriptRunning, helperURL: URL?) {
        self.runner = runner
        self.helperURL = helperURL
    }

    /// The helper is saved, so it can be asked.
    var hasHelper: Bool {
        guard let helperURL else { return false }
        return runner.exists(helperURL)
    }

    var inventory: SimulatorInventory? {
        if case let .checked(inventory) = state { return inventory }
        return nil
    }

    /// Nil until checked.
    func status(for display: ScreenshotDisplayType) -> SimulatorStatus? {
        inventory?.status(for: display)
    }

    /// The planned devices this Mac can't capture yet.
    func missing(in displays: [ScreenshotDisplayType]) -> [ScreenshotDisplayType] {
        displays.filter { status(for: $0)?.canCapture == false }
    }

    // MARK: - Checking

    /// Lists the simulators again; what was known stays shown meanwhile.
    func check() async {
        guard hasHelper else {
            state = .noHelper
            return
        }
        if inventory == nil { state = .checking }
        let answer = await run(["simulators"])
        if let inventory = try? SimulatorInventory.parse(answer.lines.joined(separator: "\n")) {
            state = .checked(inventory)
        } else if answer.isFromOlderHelper {
            state = .oldHelper
        } else {
            state = .failed(Self.reason(answer))
        }
    }

    /// What the state says, when it isn't the list.
    var message: String? {
        switch state {
        case .unknown, .checking: String(localized: "Checking this Mac’s simulators…")
        case .checked: nil
        case .noHelper: String(localized: "Install the helper so AppLocalizer can check this Mac’s simulators before starting.")
        case .oldHelper: String(localized: "Save the helper again so AppLocalizer can check this Mac’s simulators before starting.")
        case let .failed(reason): reason
        }
    }

    /// Why the list couldn't be read: no Xcode, or what it said.
    private static func reason(_ answer: SimulatorHelperAnswer) -> String {
        if answer.exit.errorOutput.contains("xcrun: error") {
            return String(localized: "Xcode isn’t set up on this Mac: install it and open it once.")
        }
        return answer.exit.lastErrorLine ?? answer.exit.taskError ?? String(localized: "AppLocalizer couldn’t read this Mac’s simulators.")
    }

    // MARK: - Fixing

    /// Downloads and installs the platform's simulator `display` needs
    /// (several GB), then makes the simulator.
    func install(for display: ScreenshotDisplayType) async {
        guard working == nil, let platform = status(for: display)?.platformToInstall else { return }
        working = display
        progress = nil
        failure = nil
        let answer = await run(["install-platform", platform]) { [weak self] line in
            Task { @MainActor in
                guard let self, self.working == display else { return }
                self.progress = line
            }
        }
        if answer.status != 0 {
            failure = answer.lines.last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                ?? answer.exit.lastErrorLine ?? String(localized: "The \(platform) simulator didn’t install.")
        }
        await check()
        working = nil
        progress = nil
        if answer.status == 0, case .canMake = status(for: display) { await make(for: display) }
    }

    /// Makes the simulator `display` needs, on the newest runtime that runs
    /// it.
    func make(for display: ScreenshotDisplayType) async {
        guard working == nil, case let .canMake(type, typeID, _, runtimeID) = status(for: display) else { return }
        working = display
        failure = nil
        let answer = await run(["create-simulator", type, typeID, runtimeID])
        if answer.status != 0 {
            failure = answer.exit.lastErrorLine ?? String(localized: "The \(type) simulator couldn’t be made.")
        }
        await check()
        working = nil
    }

    // MARK: - The helper

    /// Runs one of the helper's simulator commands; `onLine` gets each line
    /// as it comes.
    func run(_ arguments: [String], onLine: (@Sendable (String) -> Void)? = nil) async -> SimulatorHelperAnswer {
        guard let helperURL else {
            return SimulatorHelperAnswer(exit: UnixScriptExit(taskError: String(localized: "The helper isn’t installed.")))
        }
        let answer = Mutex(SimulatorHelperAnswer())
        let exit = await runner.run(helperURL, arguments: arguments) { line in
            if let status = ClaudeCodeHelperScript.exitStatus(in: line) {
                answer.withLock { $0.status = status }
            } else {
                answer.withLock { $0.lines.append(line) }
                onLine?(line)
            }
        }
        var result = answer.withLock { $0 }
        result.exit = exit
        return result
    }
}
