//
//  FirstSyncProgressTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("FirstSyncProgress")
struct FirstSyncProgressTests {
    @Test func readsTheTeamFirst() {
        let progress = FirstSyncProgress()
        #expect(progress.fraction == 0)
        #expect(progress.detail == "Reading your team and apps…")
    }

    @Test func countsAppsAsTheirSummariesLoad() {
        let progress = FirstSyncProgress(appCount: 6, syncedCount: 2)
        #expect(progress.detail == "Found 6 apps · reading subscriptions and store pages (3 of 6)")
        #expect(progress.fraction == 3.0 / 7.0)
    }

    @Test func finishedSyncIsFull() {
        #expect(FirstSyncProgress(appCount: 6, syncedCount: 6).fraction == 1)
        #expect(FirstSyncProgress(appCount: 6, syncedCount: 6).detail.hasSuffix("(6 of 6)"))
    }

    @Test func anEmptyAccountIsDoneAtOnce() {
        #expect(FirstSyncProgress(appCount: 0).fraction == 1)
        #expect(FirstSyncProgress(appCount: 1).detail.hasPrefix("Found 1 app ·"))
    }
}
