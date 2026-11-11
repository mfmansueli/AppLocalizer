//
//  ClaudeCodeUsageLimitTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ClaudeCodeUsageLimit")
struct ClaudeCodeUsageLimitTests {
    /// 10 November 2026, 23:15:26 in Dublin (UTC then).
    private let now = Date(timeIntervalSince1970: 1_794_352_526)
    private static let said = "You've hit your 5-hour limit · resets 11:20pm (Europe/Dublin)"

    private func dublin(_ date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Dublin") ?? .gmt
        return calendar.dateComponents([.day, .hour, .minute], from: date)
    }

    /// What Alba's run stopped with.
    @Test func theResetTimeIsReadInItsTimeZone() throws {
        let limit = try #require(ClaudeCodeUsageLimit(message: Self.said, now: now))
        let reset = try #require(limit.resetsAt)
        #expect(dublin(reset).hour == 23)
        #expect(dublin(reset).minute == 20)
        #expect(reset > now)
        #expect(reset.timeIntervalSince(now) < 6 * 60)
        // A little after the reset.
        #expect(limit.resumeDate(now: now) == reset.addingTimeInterval(ClaudeCodeUsageLimit.margin))
    }

    @Test func aTimeAlreadyPastTodayIsTomorrows() throws {
        let limit = try #require(ClaudeCodeUsageLimit(message: "You've hit your limit · resets 3am (Europe/Dublin)", now: now))
        let reset = try #require(limit.resetsAt)
        #expect(dublin(reset).hour == 3)
        #expect(dublin(reset).day == dublin(now).day.map { $0 + 1 })
    }

    @Test func aLimitWithoutATimeWaitsHalfAnHour() throws {
        let limit = try #require(ClaudeCodeUsageLimit(message: "Claude usage limit reached.", now: now))
        #expect(limit.resetsAt == nil)
        #expect(limit.resumeDate(now: now) == now.addingTimeInterval(ClaudeCodeUsageLimit.fallbackWait))
    }

    @Test func aResetThatJustPassedStillWaitsAMoment() throws {
        let later = now.addingTimeInterval(5 * 60)
        var limit = try #require(ClaudeCodeUsageLimit(message: Self.said, now: now))
        limit.resetsAt = now.addingTimeInterval(4 * 60)
        #expect(limit.resumeDate(now: later) == later.addingTimeInterval(ClaudeCodeUsageLimit.margin))
    }

    @Test func noWaitIsLongerThanSixHours() throws {
        var limit = try #require(ClaudeCodeUsageLimit(message: Self.said, now: now))
        limit.resetsAt = now.addingTimeInterval(3 * 86400)
        #expect(limit.resumeDate(now: now) == now.addingTimeInterval(ClaudeCodeUsageLimit.longestWait))
    }

    @Test func otherErrorsArentLimits() {
        #expect(ClaudeCodeUsageLimit(message: "API Error: 500 Internal server error", now: now) == nil)
        #expect(ClaudeCodeUsageLimit(message: "Invalid API key · Please run /login", now: now) == nil)
        #expect(ClaudeCodeUsageLimit(message: "", now: now) == nil)
    }
}
