//
//  AutopilotContinuation.swift
//  AppLocalizer
//

import Foundation

/// Keeps a run going when Claude Code stops before it's done. One device
/// or screen that can't be captured must not stop the whole run.
///
/// - When the Claude Code AppLocalizer started for a run ends with work
///   left, and it sent something (it made progress), AppLocalizer starts
///   it again with the prompt that continues the run. One that sent
///   nothing isn't started again, so it can't loop; the sheet says it
///   stopped, with its last words and Continue.
/// - Before Claude Code continues, a planned device this Mac can't run
///   becomes one problem for the device, so the rest goes on without it.
/// - A run nobody works on says so (`stall`), whoever started it.
@MainActor
enum AutopilotContinuation {
    /// How long a run whose prompt was pasted goes without news before the
    /// sheet asks whether Claude Code stopped: long enough for a build.
    static let quietLimit: TimeInterval = 30 * 60

    // MARK: - When a session ends

    /// The launcher's word that a run ended (`ClaudeCodeLauncher.onRunEnded`).
    static func sessionEnded(_ session: ClaudeCodeRun, center: AutopilotCenter, launcher: ClaudeCodeLauncher) async {
        guard session.purpose == .autopilot, let run = center.run(for: session.appID), shouldStartAgain(after: session, run: run) else { return }
        center.update(session.appID) { run in
            run.appendLog(String(localized: "Claude Code stopped with work left; AppLocalizer started it again"), kind: .event, at: center.now())
        }
        await start(appID: session.appID, appName: session.appName, center: center, launcher: launcher)
    }

    /// Only a session of this run that AppLocalizer started, that ended by
    /// itself (not Stop), with work left for the assistant, and that sent
    /// something.
    static func shouldStartAgain(after session: ClaudeCodeRun, run: AutopilotRun) -> Bool {
        guard session.purpose == .autopilot, session.phase != .stopped, !session.isActive,
              run.startsClaudeCode == true, run.assistantHasWork,
              let started = run.startedAt, session.startedAt >= started.addingTimeInterval(-1)
        else { return false }
        return run.hasNews(since: session.startedAt)
    }

    // MARK: - Continuing

    /// Starts Claude Code with the prompt that continues the run, after
    /// reporting the devices this Mac can't run. Returns the session, the
    /// one already going, or nil when nothing's left for the assistant or
    /// it can't start here (no helper, no folder).
    @discardableResult
    static func start(appID: StoreApp.ID, appName: String, center: AutopilotCenter, launcher: ClaudeCodeLauncher) async -> ClaudeCodeRun.ID? {
        guard let run = center.run(for: appID), run.assistantHasWork else { return nil }
        if run.stage == .capture {
            await launcher.simulators.check()
            center.reportMissingSimulators(appID: appID, simulators: launcher.simulators)
        }
        guard center.run(for: appID)?.assistantHasWork == true else { return nil }
        let prompt = AutopilotPrompt.continuing(appName: appName, appID: appID)
        // Marked first: the session can end before `start` returns.
        let before = center.run(for: appID)?.startsClaudeCode
        center.update(appID) { $0.startsClaudeCode = true }
        guard let id = await launcher.start(.autopilot, appID: appID, appName: appName, prompt: prompt) else {
            center.update(appID) { $0.startsClaudeCode = before }
            return nil
        }
        return id
    }

    // MARK: - Nobody working

    /// Why nobody is working on `run` although the assistant has work, or
    /// nil while someone is, or should be. `session` is the newest Claude
    /// Code AppLocalizer started for it. A session that failed says so
    /// itself, with Try Again.
    static func stall(of run: AutopilotRun, session: ClaudeCodeRun?, now: Date) -> AutopilotStall? {
        guard run.stage != .waiting, run.assistantHasWork else { return nil }
        if let session {
            switch session.phase {
            case .starting, .working, .failed: return nil
            case .finished: return .ended(lastWords: session.result?.text.trimmingCharacters(in: .whitespacesAndNewlines))
            case .stopped: return .ended(lastWords: nil)
            }
        }
        if run.startsClaudeCode == true { return .notRunning }
        guard let last = run.lastNewsAt ?? run.startedAt, now.timeIntervalSince(last) >= quietLimit else { return nil }
        return .quiet(since: last)
    }
}
