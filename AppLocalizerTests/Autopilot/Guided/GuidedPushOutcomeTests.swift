//
//  GuidedPushOutcomeTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Done step says "Sent" only when every image and extra went.
@Suite("GuidedPushOutcome")
struct GuidedPushOutcomeTests {
    private typealias Tally = GuidedPushOutcome.Tally

    @Test func afterARelaunchItCantTell() {
        #expect(GuidedPushOutcome.make(images: nil, extras: nil) == .unknown)
    }

    @Test func aPushStillGoingIsSending() {
        let running = Tally(total: 4, done: 1, isRunning: true)
        let finished = Tally(total: 2, done: 2, isRunning: false)
        #expect(GuidedPushOutcome.make(images: running, extras: finished) == .sending)
    }

    @Test func everythingSentIsSent() {
        let images = Tally(total: 4, done: 4, isRunning: false)
        #expect(GuidedPushOutcome.make(images: images, extras: nil) == .sent)
        #expect(GuidedPushOutcome.make(images: images, extras: Tally(total: 1, done: 1, isRunning: false)) == .sent)
    }

    /// Going offline leaves rows "not sent", with no failure among them.
    @Test func anythingNotSentIsPartly() {
        let images = Tally(total: 4, done: 4, isRunning: false)
        #expect(GuidedPushOutcome.make(images: Tally(total: 4, done: 3, isRunning: false), extras: nil) == .partly)
        #expect(GuidedPushOutcome.make(images: images, extras: Tally(total: 2, done: 0, isRunning: false)) == .partly)
    }

    @Test func onlyWhatIsSureSaysSent() {
        #expect(GuidedPushOutcome.sent.title == "Sent to the App Store")
        #expect(GuidedPushOutcome.partly.title == "Not everything was sent")
        #expect(GuidedPushOutcome.unknown.title == "Sent from this Mac")
        #expect(GuidedPushOutcome.unknown.detail?.contains("can’t tell how it ended") == true)
    }
}
#endif
