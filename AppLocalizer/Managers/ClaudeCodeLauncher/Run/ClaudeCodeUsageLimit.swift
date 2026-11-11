//
//  ClaudeCodeUsageLimit.swift
//  AppLocalizer
//

import Foundation

/// Claude Code stopping because the person's plan ran out of usage for now:
/// "You've hit your 5-hour limit · resets 11:20pm (Europe/Dublin)". It
/// isn't a failure to fix, only a wait, so Autopilot continues by itself
/// once the limit resets (`AutopilotContinuation`). Alba's run sat for 40
/// minutes past its reset, waiting for someone to press Try Again.
struct ClaudeCodeUsageLimit: Hashable, Sendable {
    /// When Claude Code said the limit resets; nil when it didn't say, or
    /// said it in a form this doesn't read.
    var resetsAt: Date?

    /// How long to wait when no reset time could be read.
    static let fallbackWait: TimeInterval = 30 * 60
    /// A little after the reset, so the first request isn't the one that's
    /// still refused.
    static let margin: TimeInterval = 90
    /// Never wait longer than this for one reset.
    static let longestWait: TimeInterval = 6 * 3600

    /// The limit `message` reports, or nil when it's another error.
    init?(message: String, now: Date) {
        let text = message.lowercased()
        let isLimit = (text.contains("limit") && (text.contains("hit your") || text.contains("reached") || text.contains("resets")))
            || text.contains("usage limit")
        guard isLimit else { return nil }
        resetsAt = Self.resetDate(in: text, now: now)
    }

    /// When Autopilot starts Claude Code again.
    func resumeDate(now: Date) -> Date {
        let wanted = resetsAt.map { $0.addingTimeInterval(Self.margin) } ?? now.addingTimeInterval(Self.fallbackWait)
        return min(max(wanted, now.addingTimeInterval(Self.margin)), now.addingTimeInterval(Self.longestWait))
    }

    /// "resets 11:20pm (Europe/Dublin)", "resets at 3am": the next time
    /// the clock shows that, in the time zone named or this Mac's.
    static func resetDate(in text: String, now: Date) -> Date? {
        let pattern = /resets\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)(?:\s*\(([^)]+)\))?/.ignoresCase()
        guard let match = text.firstMatch(of: pattern), var hour = Int(match.1), (1...12).contains(hour) else { return nil }
        let minute = match.2.flatMap { Int($0) } ?? 0
        guard (0..<60).contains(minute) else { return nil }
        hour = hour % 12 + (match.3.lowercased() == "pm" ? 12 : 0)
        var calendar = Calendar(identifier: .gregorian)
        if let name = match.4, let zone = timeZone(named: String(name)) { calendar.timeZone = zone }
        return calendar.nextDate(after: now.addingTimeInterval(-60), matching: DateComponents(hour: hour, minute: minute), matchingPolicy: .nextTime)
    }

    /// "europe/dublin" as Claude Code wrote it, in whatever case.
    private static func timeZone(named name: String) -> TimeZone? {
        let wanted = name.trimmingCharacters(in: .whitespaces).lowercased()
        return TimeZone.knownTimeZoneIdentifiers.first { $0.lowercased() == wanted }.flatMap(TimeZone.init(identifier:))
    }
}
