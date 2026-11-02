//
//  DuoStepTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What AppLocalizer does after looking at iPhone Duo's simulator: start
/// it and open it during a run, restart it when it's stuck (never when it's
/// open), and leave it to the person after two tries at opening it.
@Suite("iPhone Duo's next step")
struct DuoStepTests {
    private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func next(_ look: DuoStep.Look, restarts: Int = 0, opens: Int = 0, mayStart: Bool = true) -> DuoStep {
        DuoStep.next(after: look, restarts: restarts, opens: opens, mayStart: mayStart, now: now)
    }

    @Test func aDuoThatIsntRunningIsStartedOnlyDuringARun() {
        #expect(next(DuoStep.Look(isBooted: false)) == .start)
        #expect(next(DuoStep.Look(isBooted: false), mayStart: false) == .wait)
    }

    @Test func aClosedDuoIsOpenedOnlyDuringARun() {
        let closed = DuoStep.Look(isBooted: true, inner: .black)
        #expect(next(closed) == .open)
        #expect(next(closed, mayStart: false) == .wait, "The plan is only being looked at")
        #expect(next(DuoStep.Look(isBooted: true, inner: .showing)) == .wait)
    }

    @Test func afterTwoTriesAtOpeningItItsLeftToThePerson() {
        let closed = DuoStep.Look(isBooted: true, inner: .black)
        #expect(next(closed, opens: 1) == .open)
        #expect(next(closed, opens: DuoStep.maximumOpens) == .wait)
    }

    /// A spinner may be it starting: it's opened once it's black, or
    /// restarted once the spinner has lasted.
    @Test func aSpinnerOrAnUnreadableDisplayIsntOpened() {
        #expect(next(DuoStep.Look(isBooted: true, inner: .spinner, spinnerSince: now)) == .wait)
        #expect(next(DuoStep.Look(isBooted: true, inner: nil)) == .wait)
    }

    @Test func aStuckDuoIsRestartedBeforeItsOpened() {
        #expect(next(DuoStep.Look(isBooted: true, inner: .black, crashedSinceStart: true)) == .restart(.springBoardCrashed))
    }

    /// The stuck Duo: SpringBoard crashed whenever an app opened, and only
    /// a spinner showed.
    @Test func aCrashedSpringBoardRestartsIt() {
        #expect(next(DuoStep.Look(isBooted: true, inner: .spinner, crashedSinceStart: true)) == .restart(.springBoardCrashed))
        #expect(next(DuoStep.Look(isBooted: true, inner: .black, crashedSinceStart: true)) == .restart(.springBoardCrashed))
        #expect(next(DuoStep.Look(isBooted: true, inner: nil, crashedSinceStart: true)) == .restart(.springBoardCrashed))
        #expect(next(DuoStep.Look(isBooted: true, inner: .black, crashedSinceStart: true), mayStart: false) == .restart(.springBoardCrashed))
    }

    @Test func anOpenDuoIsNeverRestarted() {
        #expect(next(DuoStep.Look(isBooted: true, inner: .showing, crashedSinceStart: true)) == .wait)
    }

    @Test func aSpinnerRestartsItOnlyOnceItHasLasted() {
        let fresh = DuoStep.Look(isBooted: true, inner: .spinner, spinnerSince: now.addingTimeInterval(-30))
        #expect(next(fresh) == .wait, "Starting, or being opened")
        let lasting = DuoStep.Look(isBooted: true, inner: .spinner, spinnerSince: now.addingTimeInterval(-DuoStep.spinnerLimit))
        #expect(next(lasting) == .restart(.spinner))
    }

    @Test func afterTwoRestartsItsLeftToThePerson() {
        let stuck = DuoStep.Look(isBooted: true, inner: .spinner, crashedSinceStart: true)
        #expect(next(stuck, restarts: 1) == .restart(.springBoardCrashed))
        #expect(next(stuck, restarts: DuoStep.maximumRestarts) == .giveUp(.springBoardCrashed))
    }
}
