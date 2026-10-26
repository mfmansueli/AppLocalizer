//
//  ScreenshotCoverageTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("ScreenshotCoverage")
struct ScreenshotCoverageTests {
    private let coverage = StorePageSampleData.screenshots

    @Test func presentScreenshots() {
        let status = coverage.status(for: .englishUS, on: .iPhone)
        #expect(status == .present(count: 6))
        #expect(status.title == "6 screenshots")
        #expect(!status.isFlagged)
        #expect(ScreenshotStatus.present(count: 1).title == "1 screenshot")
    }

    @Test func iPhoneFallsBackToThePrimaryLocale() {
        let status = coverage.status(for: .spanishMexico, on: .iPhone)
        #expect(status == .usesPrimary(.englishUS))
        #expect(status.title == "Uses English (U.S.)")
        #expect(status.isFlagged)
    }

    @Test func otherSizesAreMissing() {
        #expect(coverage.status(for: .spanishMexico, on: .iPad) == .missing)
        #expect(coverage.status(for: .german, on: .mac) == .missing)
        #expect(ScreenshotStatus.missing.title == "Missing")
    }

    @Test func noFallbackWithoutPrimaryScreenshots() {
        let coverage = ScreenshotCoverage(primaryLocale: .englishUS, counts: [.german: [.iPad: 3]])
        #expect(coverage.status(for: .german, on: .iPhone) == .missing)
        #expect(coverage.status(for: .englishUS, on: .iPhone) == .missing)
        #expect(coverage.count(for: .german, on: .iPad) == 3)
    }

    @Test func flaggedCounts() {
        #expect(coverage.flaggedCount(in: [.englishUS]) == 0)
        #expect(coverage.flaggedCount(in: [.german]) == 1)
        #expect(coverage.flaggedCount(in: [.spanishMexico]) == 3)
        #expect(ScreenshotDevice.allCases.map(\.title) == ["iPhone 6.9″", "iPad 13″", "Mac"])
    }
}
