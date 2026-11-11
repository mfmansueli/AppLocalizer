//
//  SectionLoadStampTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("SectionLoadStamp")
struct SectionLoadStampTests {
    private let date = Date(timeIntervalSince1970: 1_000_000)

    @Test func freshUnderTheSameRefreshAndWithinTheAge() {
        let stamp = SectionLoadStamp(refreshCount: 2, date: date)
        #expect(stamp.isFresh(refreshCount: 2, now: date.addingTimeInterval(59), maximumAge: 60))
    }

    @Test func staleAfterARefresh() {
        let stamp = SectionLoadStamp(refreshCount: 2, date: date)
        #expect(!stamp.isFresh(refreshCount: 3, now: date, maximumAge: 60))
    }

    @Test func staleOnceItReachesTheAge() {
        let stamp = SectionLoadStamp(refreshCount: 2, date: date)
        #expect(!stamp.isFresh(refreshCount: 2, now: date.addingTimeInterval(60), maximumAge: 60))
    }
}
