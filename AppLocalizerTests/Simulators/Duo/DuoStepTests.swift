//
//  DuoStepTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What AppLocalizer does after looking at iPhone Duo's simulator: start
/// it during a run, restart it when it's stuck (never when it's open), and
/// leave opening it to the person.
@Suite("iPhone Duo's next step")
struct DuoStepTests {
    private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func next(_ look: DuoStep.Look, restarts: Int = 0, mayStart: Bool = true) -> DuoStep {
        DuoStep.next(after: look, restarts: restarts, mayStart: mayStart, now: now)
    }

    @Test func aDuoThatIsntRunningIsStartedOnlyDuringARun() {
        #expect(next(DuoStep.Look(isBooted: false)) == .start)
        #expect(next(DuoStep.Look(isBooted: false), mayStart: false) == .wait)
    }

    @Test func closedOrOpenItWaits() {
        #expect(next(DuoStep.Look(isBooted: true, inner: .black)) == .wait)
        #expect(next(DuoStep.Look(isBooted: true, inner: .showing)) == .wait)
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
