//
//  ClaudeCodeRun.swift
//  AppLocalizer
//

import Foundation

/// One Claude Code session AppLocalizer started: what for, where, what it's
/// doing now, and how it ended. Everything it sends AppLocalizer arrives
/// over MCP as usual; this is the run's own story, for the status strips
/// and Show Output.
struct ClaudeCodeRun: Identifiable, Hashable, Sendable {
    enum Phase: Hashable, Sendable {
        /// The helper is starting Claude Code.
        case starting
        /// Claude Code's session began.
        case working
        case finished
        /// The person stopped it.
        case stopped
        case failed(ClaudeCodeRunFailure)
    }

    /// The most lines Show Output keeps.
    static let activityLimit = 400

    var id: UUID
    var appID: StoreApp.ID
    var appName: String
    var purpose: ClaudeCodeRunPurpose
    var prompt: String
    /// Absolute path.
    var workingDirectory: String
    var startedAt: Date
    var endedAt: Date?
    var phase: Phase = .starting
    /// Claude Code's session, for `claude --resume`.
    var sessionID: String?
    var claudeVersion: String?
    var activity: [ClaudeCodeActivity] = []
    var result: ClaudeCodeResult?
    /// How many of AppLocalizer's tools it called.
    var appLocalizerCalls = 0

    var isActive: Bool {
        phase == .starting || phase == .working
    }

    var failure: ClaudeCodeRunFailure? {
        if case let .failed(failure) = phase { return failure }
        return nil
    }

    /// "~/Developer/Lumen".
    var displayDirectory: String {
        ProjectFolderPath.abbreviated(workingDirectory)
    }

    /// The step the status strip shows: the last tool or words, e.g.
    /// "Read CHANGELOG.md" or "AppLocalizer · get_store_page".
    var latestStep: String? {
        guard let step = activity.last(where: { $0.kind != .started }) else { return nil }
        return step.kind == .appLocalizer ? String(localized: "AppLocalizer · \(step.text)") : step.text
    }

    /// "Starting Claude Code in ~/Developer/Lumen…", "Working in
    /// ~/Developer/Lumen", "Finished", "Stopped", or the failure's title.
    var statusTitle: String {
        switch phase {
        case .starting: String(localized: "Starting Claude Code in \(displayDirectory)…")
        case .working: String(localized: "Working in \(displayDirectory)")
        case .finished where denials.isEmpty: String(localized: "Finished")
        case .finished where denials.count == 1: String(localized: "Finished · 1 step wasn’t allowed")
        case .finished: String(localized: "Finished · \(denials.count) steps weren’t allowed")
        case .stopped: String(localized: "Stopped")
        case let .failed(failure): failure.title
        }
    }

    /// Show Output's list: the activity, less the closing words when the
    /// result below it repeats them.
    var timeline: [ClaudeCodeActivity] {
        guard let last = activity.last, last.kind == .said, let result, !result.text.isEmpty else { return activity }
        let said = last.text.hasSuffix("…") ? String(last.text.dropLast()) : last.text
        return result.text.hasPrefix(said) ? Array(activity.dropLast()) : activity
    }

    /// Calls the run's permissions refused.
    var denials: [ClaudeCodeResult.Denial] {
        result?.denials ?? []
    }

    /// `cd '<folder>' && claude --resume <session>`, to continue it in
    /// Terminal with the person watching.
    var resumeCommand: String? {
        guard let sessionID else { return nil }
        return "cd \(Self.shellQuoted(workingDirectory)) && claude --resume \(sessionID)"
    }

    /// How long it ran, or has been running at `date`.
    func elapsed(at date: Date) -> TimeInterval {
        (endedAt ?? date).timeIntervalSince(startedAt)
    }

    private static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
