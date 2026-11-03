//
//  AppPreviewFactsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What keeps an App Preview file from App Store Connect.
@Suite("App Preview facts")
struct AppPreviewFactsTests {
    private let spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 886, height: 1920))
    private let good = AppPreviewFacts(
        seconds: 24, pixelSize: PixelSize(width: 886, height: 1920), framesPerSecond: 30, codec: .h264, audioChannels: 2, byteCount: 30_000_000
    )

    @Test func aFileThatFollowsTheRulesHasNoIssues() {
        #expect(good.issues(against: spec).isEmpty)
        var proRes = good
        proRes.codec = .proRes422HQ
        proRes.pixelSize = PixelSize(width: 1920, height: 886)
        proRes.seconds = 15
        #expect(proRes.issues(against: spec).isEmpty)
    }

    @Test func eachBrokenRuleIsOneSentence() {
        var facts = good
        facts.seconds = 12
        facts.framesPerSecond = 60
        facts.pixelSize = PixelSize(width: 1320, height: 2868)
        facts.codec = .other
        facts.audioChannels = 0
        facts.byteCount = 600 * 1024 * 1024
        let issues = facts.issues(against: spec)
        #expect(issues.count == 6)
        #expect(issues.allSatisfy { $0.hasSuffix(".") })
        #expect(issues[0].contains("12"))
        #expect(issues[2].contains("1320 × 2868"))
    }

    @Test func lengthsJustOutsideTheRangeAreIssues() {
        var long = good
        long.seconds = 30.2
        #expect(long.issues(against: spec).count == 1)
        var rounded = good
        rounded.seconds = 14.97
        #expect(rounded.issues(against: spec).isEmpty)
    }

    @Test func monoSoundIsAnIssue() {
        var mono = good
        mono.audioChannels = 1
        #expect(mono.issues(against: spec) == ["The App Preview's sound is mono; App Store Connect wants stereo."])
        var surround = good
        surround.audioChannels = 6
        #expect(surround.issues(against: spec) == ["The App Preview's sound has 6 channels; App Store Connect wants stereo."])
    }
}
