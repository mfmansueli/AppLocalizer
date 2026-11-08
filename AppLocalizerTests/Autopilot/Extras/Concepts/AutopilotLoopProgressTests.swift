//
//  AutopilotLoopProgressTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What the header loop waits for after the person asked for changes:
/// who has it, how many languages are made and about how long is left.
@MainActor
@Suite("AutopilotLoopProgress")
struct AutopilotLoopProgressTests {
    private static let now = AutopilotTestFixtures.now

    private static func asked() -> AutopilotRun {
        var run = StudioDebugHeaderStyle.watching(version: 1)
        run.loopReview?.request = AutopilotRevisionRequest(note: "Slower", askedAt: now)
        return run
    }

    /// Bruma's remake: 12 languages, the first `done` at `each` minutes,
    /// the last finished `since` minutes ago.
    private static func making(done: Int, each: Double = 6, since: Double = 0) -> AutopilotRun {
        var run = asked()
        run.loopReview?.isRemaking = true
        var extras = AutopilotExtrasProgress()
        extras.artworkTotal = 12
        extras.artworkDone = done
        let last = now.addingTimeInterval(-since * 60)
        extras.artworkDoneAt = done > 0 ? last : nil
        extras.artworkStartedAt = last.addingTimeInterval(-Double(done) * each * 60)
        run.extrasProgress = extras
        return run
    }

    @Test func nothingToWaitForSaysNothing() {
        #expect(AutopilotLoopProgress.make(StudioDebugHeaderStyle.watching(version: 1), now: Self.now) == nil)

        var approved = Self.making(done: 3)
        approved.loopReview?.approvedAt = Self.now
        #expect(AutopilotLoopProgress.make(approved, now: Self.now) == nil)
    }

    @Test func whileTheDesignSourceWorksItSaysWhatComesAfter() throws {
        let run = Self.asked()
        let progress = try #require(AutopilotLoopProgress.make(run, now: Self.now))
        let designer = (run.reviser ?? run.designKind).title
        #expect(progress.title == "\(designer) is revising the loop: “Slower”.")
        #expect(progress.fraction == nil)
        #expect(progress.line.isEmpty)
        #expect(progress.minutesLeft == nil)
        let minutes = max(1, Int(AutopilotEstimate.artworkMinutes(for: run.plan).rounded(.up)))
        #expect(progress.detail.hasSuffix(GuidedRunProgress.about(minutes) + "."))
    }

    /// The request stays until the loops are made: Bruma's run kept saying
    /// Claude Design was revising for the hour AppLocalizer drew them.
    @Test func onceTheNewVersionArrivedItSaysAppLocalizerIsMakingIt() throws {
        let progress = try #require(AutopilotLoopProgress.make(Self.making(done: 7), now: Self.now))
        #expect(progress.title == "Making the new loop")
        #expect(progress.line == "7 of 12 languages · about 30 min left")
        #expect(progress.fraction == 7.0 / 12)
        #expect(progress.minutesLeft == 30)
        #expect(progress.approveNote == "You can approve once the new loop is made · about 30 min left")
    }

    /// A language takes minutes: the figure goes down between them rather
    /// than climbing until the next one lands.
    @Test func theTimeCountsDownBetweenLanguages() throws {
        let later = try #require(AutopilotLoopProgress.make(Self.making(done: 7, since: 5), now: Self.now))
        #expect(later.minutesLeft == 25)
    }

    @Test func aLanguageRunningLateStillSaysAMinute() throws {
        let late = try #require(AutopilotLoopProgress.make(Self.making(done: 11, since: 20), now: Self.now))
        #expect(late.minutesLeft == 1)
    }

    @Test func beforeTheFirstLanguageItIsTheEstimateLessTheTimeGone() throws {
        var run = Self.making(done: 0)
        let estimate = 60.0
        run.extrasProgress?.artworkStartedAt = Self.now.addingTimeInterval(-10 * 60)
        let left = try #require(run.extrasProgress?.artworkMinutesLeft(estimate: estimate, now: Self.now))
        #expect(left == 50)
        let progress = try #require(AutopilotLoopProgress.make(run, now: Self.now))
        #expect(progress.line.hasPrefix("0 of 12 languages · about "))
    }

    @Test func oneLanguageSaysSo() throws {
        var run = Self.making(done: 0)
        run.extrasProgress?.artworkTotal = 1
        let progress = try #require(AutopilotLoopProgress.make(run, now: Self.now))
        #expect(progress.line.hasPrefix("0 of 1 language · about "))
    }

    @Test func theChecksCardSaysItsBeingMadeNotThatSomethingIsWrong() {
        let run = Self.making(done: 7)
        let checks = GuidedReviewChecks.checks(for: .artwork, run: run)
        let total = run.plan.localeCodes.count
        #expect(checks.map(\.state) == [.working])
        #expect(checks.first?.text == "Making the new loop in 7 of \(total) languages. Its checks run as each is made.")
    }

    @Test func theHiddenStripSaysItIsRunningNotYourTurn() {
        let strip = AutopilotStripContent.guided(
            run: Self.making(done: 7), appName: "Lumen", assistant: "Claude Code", designProject: nil, hasNewSet: false, now: Self.now
        )
        #expect(strip.kind == .running)
        #expect(strip.title == "Autopilot is running")
        #expect(strip.text == "Making the new loop · 7 of 12 languages · about 30 min left")
        #expect(strip.progress == 7.0 / 12)
    }

    @Test func aboutSaysHoursAndMinutes() {
        #expect(GuidedRunProgress.about(6) == "about 6 min")
        #expect(GuidedRunProgress.about(60) == "about 1 h")
        #expect(GuidedRunProgress.about(66) == "about 1 h 6 min")
    }
}
#endif
