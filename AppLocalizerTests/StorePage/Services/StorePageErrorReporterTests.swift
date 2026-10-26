//
//  StorePageErrorReporterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Which loading failures reach the workspace banner, and what the Store
/// Page itself says.
@MainActor
@Suite("StorePageErrorReporter")
struct StorePageErrorReporterTests {
    private let push = PushController(queue: ChangeQueue(), history: PushHistory())

    @Test func aRateLimitResumesAtTheNextHour() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-10-26T14:20:00Z"))
        _ = StorePageErrorReporter.report(AppStoreConnectError.rateLimited, to: push, now: now)
        #expect(push.notice == .rateLimited(resumeAt: StorePageErrorReporter.nextHour(after: now)))
        #expect(StorePageErrorReporter.nextHour(after: now).timeIntervalSince(now) == 40 * 60)
    }

    @Test func beingOfflineSaysSo() {
        let message = StorePageErrorReporter.report(URLError(.notConnectedToInternet), to: push)
        #expect(push.notice == .offline)
        #expect(!message.isEmpty)
    }

    @Test func appleRejectingTheReadIsAnAPIError() {
        let error = AppStoreConnectError.rejected(statusCode: 403, code: "FORBIDDEN_ERROR", detail: "No access")
        _ = StorePageErrorReporter.report(error, to: push)
        #expect(push.notice == .apiError(error.pushFailureText))
    }

    @Test func aMissingResourceStaysInTheSection() {
        _ = StorePageErrorReporter.report(AppStoreConnectError.notFound(detail: nil), to: push)
        #expect(push.notice == nil)
    }

    @Test func otherErrorsOnlyReturnTheirText() {
        let message = StorePageErrorReporter.report(CocoaError(.fileReadCorruptFile), to: push)
        #expect(push.notice == nil)
        #expect(message == CocoaError(.fileReadCorruptFile).localizedDescription)
    }
}
