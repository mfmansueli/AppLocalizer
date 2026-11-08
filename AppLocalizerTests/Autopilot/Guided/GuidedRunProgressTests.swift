//
//  GuidedRunProgressTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Making it's bar and line, and the next stop under it: the times say
/// "about" and come from the pace so far once something has arrived.
@MainActor
@Suite("GuidedRunProgress")
struct GuidedRunProgressTests {
    private static let start = AutopilotTestFixtures.now

    /// Half of the small plan's eight captures in, at a minute each.
    private static var halfCaptured: AutopilotRun {
        var run = AutopilotTestFixtures.run(.capture)
        GuidedDefaults.apply(to: &run.plan)
        AutopilotTestFixtures.captureAll(&run, except: Set(run.plan.targets.suffix(4)))
        return run
    }

    @Test func capturingGoesAtThePaceSoFar() {
        let run = Self.halfCaptured
        let progress = GuidedRunProgress.make(run, now: Self.start.addingTimeInterval(4 * 60))
        #expect(progress.title == "Capturing in Simulator")
        #expect(progress.fraction == 0.5)
        #expect(progress.line == "4 of 8 captures · about 4 min left")
        #expect(progress.minutesLeft == 4)
    }

    @Test func beforeAnythingArrivesThePlanSaysHowLong() {
        let run = AutopilotTestFixtures.run(.capture)
        let progress = GuidedRunProgress.make(run, now: Self.start.addingTimeInterval(60))
        #expect(progress.fraction == 0)
        #expect(progress.minutesLeft == AutopilotEstimate.captureMinutes(for: 8))
        #expect(progress.line.hasPrefix("0 of 8 captures · about "))
    }

    @Test func theDesignCountsLooksAndHeaders() {
        let run = StudioDebugGuided.designing(arrived: 2)
        let progress = GuidedRunProgress.make(run, now: Self.start)
        #expect(progress.title == "Designing in Northpier Brand")
        let looks = "2 of \(run.expectedDirections) screenshot looks"
        let headers = "\(run.designedConcepts.count) of \(run.expectedConcepts) headers"
        #expect(progress.line.hasPrefix("\(looks) · \(headers) · about "))
        #expect(progress.fraction > 0 && progress.fraction < 1)
    }

    @Test func localizingCountsTheLanguagesDone() {
        let run = StudioDebugRuns.run(.localize)
        let done = run.plan.localeCodes.count { run.localeStatus[$0]?.isDone == true }
        let progress = GuidedRunProgress.make(run, now: Self.start)
        #expect(progress.title == "Localizing and checking")
        #expect(progress.line.hasPrefix("\(done) of \(run.plan.localeCodes.count) languages · about "))
    }

    /// Like Bruma's run: every language checked, its header and search
    /// loops in each language and the App Previews on iPhone and iPad
    /// still to make.
    private static var everyLanguageChecked: AutopilotRun {
        var run = StudioDebugRuns.run(.localize)
        run.plan.alsoMakes.makesArtwork = true
        run.plan.alsoMakes.artworkSize = .headerAndSearch
        run.plan.alsoMakes.artworkMotion = .loop
        run.plan.alsoMakes.makesAppPreview = true
        run.plan.alsoMakes.previewLanguages = .primary
        for code in run.plan.localeCodes { run.localeStatus[code] = .fits(note: nil) }
        return run
    }

    /// Bruma's run said "12 of 12 languages · about 1 min left" over a
    /// full bar for the hour and more its loops and App Previews took.
    @Test func checkedLanguagesLeaveTheExtrasStillToMake() {
        let run = Self.everyLanguageChecked
        let progress = GuidedRunProgress.make(run, now: Self.start)
        let count = run.plan.localeCodes.count
        #expect(progress.line.hasPrefix("\(count) of \(count) languages · about "))
        #expect(progress.minutesLeft == 1 + AutopilotEstimate.extrasMakingMinutes(for: run.plan))
        #expect(AutopilotEstimate.extrasMakingMinutes(for: run.plan) > 1, "Every language's loops and two App Previews")
        #expect(progress.fraction < 1)
    }

    @Test func theArtworkGoesAtItsPace() {
        var run = Self.everyLanguageChecked
        let count = run.plan.localeCodes.count
        var extras = AutopilotExtrasProgress()
        extras.artworkTotal = count
        extras.artworkDone = 2
        extras.artworkStartedAt = Self.start
        extras.previewsTotal = 2
        run.extrasProgress = extras
        let checked = GuidedRunProgress.make(Self.everyLanguageChecked, now: Self.start)

        // Two languages in 4 min; the App Previews at their estimate.
        let progress = GuidedRunProgress.make(run, now: Self.start.addingTimeInterval(4 * 60))
        let previews = AutopilotEstimate.previewsMinutes(for: run.plan)
        #expect(previews == 2)
        let left = 2 * (count - 2) + Int(previews)
        #expect(progress.line == "Header and search artwork · 2 of \(count) languages · about \(left) min left")
        #expect(progress.minutesLeft == left)
        #expect(progress.title == "Localizing and checking")
        #expect(progress.fraction > checked.fraction && progress.fraction < 1, "On from where checking left it")
    }

    @Test func thenTheAppPreviews() {
        var run = Self.everyLanguageChecked
        var extras = AutopilotExtrasProgress()
        extras.artworkTotal = run.plan.localeCodes.count
        extras.artworkDone = extras.artworkTotal
        extras.previewsTotal = 2
        extras.previewsDone = 1
        extras.previewsStartedAt = Self.start
        run.extrasProgress = extras

        let progress = GuidedRunProgress.make(run, now: Self.start.addingTimeInterval(90))
        #expect(progress.line == "App Previews · 1 of 2 · about 2 min left")
        #expect(progress.minutesLeft == 2)
        #expect(GuidedNextStop.line(for: run, progress: progress).hasPrefix("Next for you: review everything and push, in about 2 min."))

        // Only iPhone's, none made yet: its estimate.
        run.plan.runChoice.previewDisplays = [.iPhone]
        run.extrasProgress?.previewsTotal = 1
        run.extrasProgress?.previewsDone = 0
        run.extrasProgress?.previewsStartedAt = nil
        #expect(GuidedRunProgress.make(run, now: Self.start).line == "App Preview · about 1 min left")
    }

    /// MB Admin's run, just started: "Next for you: choose the look, in
    /// about 4 min" left out the capturing still to come.
    @Test func whileStartingTheCapturingIsCounted() {
        var run = AutopilotTestFixtures.run(.waiting)
        run.captures = []
        let progress = GuidedRunProgress.make(run, now: Self.start)
        let capturing = AutopilotEstimate.captureMinutes(for: run.plan) + AutopilotEstimate.recordingMinutes(for: run.plan)
        #expect(progress.minutesLeft == capturing)
        #expect(progress.line.hasSuffix(" · about \(capturing) min left"))
        let design = AutopilotEstimate.designMinutes(for: run.designKind) + AutopilotEstimate.extrasDesignMinutes(for: run.plan)
        #expect(GuidedNextStop.minutes(to: .choose, run: run, progress: progress) == capturing + design)
    }

    /// MB Admin's run after Record Again: every capture in, the App
    /// Preview's recordings left, and it said "Capturing · 18 of 18".
    @Test func onceCapturedItSaysItsRecording() {
        var run = AutopilotTestFixtures.run(.capture)
        run.captures = []
        run.plan.alsoMakes.makesAppPreview = true
        AutopilotTestFixtures.captureAll(&run)
        let recordings = run.plan.recordingTargets.count
        let progress = GuidedRunProgress.make(run, now: Self.start)
        #expect(progress.title == "Recording the App Preview")
        #expect(progress.line.hasPrefix("0 of \(recordings) recordings · about "))
        #expect(progress.minutesLeft == GuidedRunProgress.recordingMinutesLeft(run))
    }

    @Test func thePaceIsTheTimeEachCaptureTook() {
        #expect(GuidedRunProgress.minutesLeft(done: 0, total: 6, since: Self.start, now: Self.start) == nil)
        #expect(GuidedRunProgress.minutesLeft(done: 6, total: 6, since: Self.start, now: Self.start) == 0)
        #expect(GuidedRunProgress.minutesLeft(done: 2, total: 6, since: Self.start, now: Self.start.addingTimeInterval(600)) == 20)
        #expect(GuidedRunProgress.minutesLeft(done: 2, total: 6, since: nil, now: Self.start) == nil)
    }

    /// A run left waiting for days (a problem, the app quit) used to say
    /// "about 4.414 min left" (4,414 minutes in Portuguese): the pace now
    /// starts at the first capture, and a pause counts as 10 minutes at most.
    @Test func aLongPauseCantMakeTheEstimateHours() throws {
        // The ap-run scene: 76 of 120 captured.
        var run = StudioDebugGuided.started(StudioDebugExtras.run(.capture, languages: .primary))
        run.startedAt = Self.start.addingTimeInterval(-30 * 86400)
        let firstCapture = try #require(run.captures.map(\.receivedAt).min())
        let progress = GuidedRunProgress.make(run, now: firstCapture.addingTimeInterval(14 * 86400))
        let left = try #require(progress.minutesLeft)
        #expect(left < 60)
    }

    /// Bruma's run reused 54 captures of 432 and said "about 4 h 9 min
    /// left" before its first new one: the last run's captures and the
    /// pause since were taken for this run's pace.
    @Test func keptCapturesDontCountInThePace() {
        var run = AutopilotTestFixtures.run(.capture)
        GuidedDefaults.apply(to: &run.plan)
        let targets = run.plan.targets
        let started = Self.start.addingTimeInterval(3600)
        run.startedAt = started
        // Half kept from the last run, an hour before this start.
        for (index, target) in targets.prefix(4).enumerated() {
            run.captures.append(AutopilotTestFixtures.capture(target, in: run.plan, second: index * 60))
        }
        let before = GuidedRunProgress.make(run, now: started.addingTimeInterval(5 * 60))
        #expect(before.line == "4 of 8 captures · about \(AutopilotEstimate.captureMinutes(for: 4)) min left")

        // Two new ones, a minute each, from the start's first capture.
        for (index, target) in targets.dropFirst(4).prefix(2).enumerated() {
            run.captures.append(AutopilotTestFixtures.capture(target, in: run.plan, second: 3600 + 5 * 60 + index * 60))
        }
        let after = GuidedRunProgress.make(run, now: started.addingTimeInterval(7 * 60))
        #expect(after.line == "6 of 8 captures · about 2 min left")
    }

    /// Bruma's run, everything in but its Mac to retry or leave out, said
    /// "324 of 432 captures · about 52 min left" with nothing going on.
    @Test func whatWaitsOnYouHasNoTimeLeft() throws {
        var run = AutopilotTestFixtures.run(.capture)
        GuidedDefaults.apply(to: &run.plan)
        let held = try #require(run.plan.targets.last)
        let device = Set(run.plan.targets.filter { $0.displayType == held.displayType })
        try #require(device.count > 1 && device.count < run.totalCaptures)
        var problem = AutopilotTestFixtures.problem(held, fix: "Make the UI tests build for this device.")
        problem.affectsDevice = true
        run.problems = [problem]

        // Another device still capturing: its pace goes on.
        let other = try #require(run.plan.targets.first { !device.contains($0) })
        AutopilotTestFixtures.captureAll(&run, except: device.union([other]))
        #expect(!run.waitsOnlyOnProblems)

        run.captures.append(AutopilotTestFixtures.capture(other, in: run.plan, second: 60))
        #expect(run.waitsOnlyOnProblems)
        let done = run.totalCaptures - device.count
        let progress = GuidedRunProgress.make(run, now: Self.start.addingTimeInterval(10 * 60))
        #expect(progress.line == "\(done) of \(run.totalCaptures) captures · \(device.count) wait on you")
        #expect(progress.minutesLeft == nil)

        // Retried: the assistant is at it again.
        run.problems[0].resolution = .retryWithFix
        #expect(!run.waitsOnlyOnProblems)
    }

    @Test func pausesCountTenMinutesAtMost() {
        let times = [Self.start, Self.start.addingTimeInterval(60), Self.start.addingTimeInterval(3 * 3600)]
        let now = Self.start.addingTimeInterval(3 * 3600 + 60)
        let active = GuidedRunProgress.activeStart(of: times, now: now)
        #expect(active == now.addingTimeInterval(-(60 + 600 + 60)), "1 min, a 3-hour pause as 10 min, then 1 min")
        #expect(GuidedRunProgress.activeStart(of: [], now: now) == nil)
    }

    @Test func hoursAreWrittenAsHours() {
        #expect(GuidedRunProgress.aboutLeft(0) == "")
        #expect(GuidedRunProgress.aboutLeft(45) == " · about 45 min left")
        #expect(GuidedRunProgress.aboutLeft(60) == " · about 1 h left")
        #expect(GuidedRunProgress.aboutLeft(80) == " · about 1 h 20 min left")
    }

    @Test func aShareIsAMinuteAtLeast() {
        #expect(GuidedRunProgress.share(of: 10, left: 1, total: 3) == 4)
        #expect(GuidedRunProgress.share(of: 10, left: 0, total: 3) == 1)
        #expect(GuidedRunProgress.share(of: 10, left: 3, total: 3) == 10)
    }

    // MARK: - Next stop

    @Test func theNextStopIsChooseThenReview() {
        let run = Self.halfCaptured
        #expect(GuidedNextStop.next(after: run) == .choose)

        var forMe = run
        forMe.plan.stopsToChoose = false
        #expect(GuidedNextStop.next(after: forMe) == .review)

        var picks = run
        picks.plan.stopsToPick = true
        #expect(GuidedNextStop.next(after: picks) == .pick)

        #expect(GuidedNextStop.next(after: StudioDebugRuns.run(.localize)) == .review)
    }

    @Test func theNextStopWaitsForTheDesign() {
        let run = Self.halfCaptured
        let progress = GuidedRunProgress.make(run, now: Self.start.addingTimeInterval(4 * 60))
        let design = AutopilotEstimate.designMinutes(for: run.designKind) + AutopilotEstimate.extrasDesignMinutes(for: run.plan)
        #expect(GuidedNextStop.minutes(to: .choose, run: run, progress: progress) == 4 + design)
        #expect(GuidedNextStop.minutes(to: .review, run: run, progress: progress)
            == 4 + design + GuidedMakeSummary.localizeMinutes(run.plan))
        #expect(GuidedNextStop.line(for: run, progress: progress) == """
        Next for you: choose the look, in about \(4 + design) min. You can close this window; Autopilot keeps going and lets you know.
        """)
    }
}
#endif
