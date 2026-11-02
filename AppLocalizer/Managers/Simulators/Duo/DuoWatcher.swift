//
//  DuoWatcher.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Watches iPhone Duo's simulator for Screenshot Autopilot, so the Duo
/// mostly sorts itself out. It starts closed and only the person can open
/// it, in Device Hub (`DeviceHub`); AppLocalizer looks at its inner display
/// every few seconds through the helper, starts it when it isn't running,
/// restarts it when it's stuck (its SpringBoard crashed, or a spinner that
/// doesn't go away), and says when the person has opened it, so the run
/// captures it without a Retry. It never restarts an open Duo: starting it
/// again closes it.
@MainActor
@Observable
final class DuoWatcher {
    /// What it did or saw, for the run's log.
    enum Event: Hashable, Sendable {
        case started
        case restarted(DuoStep.Reason)
        /// Closed (or stuck) when it first looked, open now.
        case opened

        var logText: String {
            switch self {
            case .started:
                String(localized: "iPhone Duo wasn’t running: AppLocalizer started it (it starts closed)")
            case .restarted(.springBoardCrashed):
                String(localized: "iPhone Duo was stuck, its SpringBoard crashed: AppLocalizer restarted it")
            case .restarted(.spinner):
                String(localized: "iPhone Duo was stuck on a spinner: AppLocalizer restarted it")
            case .opened:
                String(localized: "iPhone Duo is open: its screens are captured next")
            }
        }
    }

    private(set) var state: DuoState = .unknown

    @ObservationIgnored private weak var simulators: MacSimulators?
    /// The inner display's ID; it changes each time the simulator starts.
    @ObservationIgnored private var inner: (udid: String, display: String)?
    @ObservationIgnored private var spinnerSince: Date?
    @ObservationIgnored private var restarts = 0
    /// A look is under way: a view's task that restarts while one is still
    /// waiting on the helper mustn't restart the Duo a second time.
    @ObservationIgnored private var isLooking = false
    /// Between looks.
    @ObservationIgnored var interval: Duration = DuoWatcher.defaultInterval
    @ObservationIgnored var now: () -> Date = Date.init

    init(simulators: MacSimulators) {
        self.simulators = simulators
    }

    /// DEBUG scenes look often, so UI tests don't wait.
    static var defaultInterval: Duration {
        #if DEBUG
        if DebugScene.requestedID != nil { return .milliseconds(300) }
        #endif
        return .seconds(4)
    }

    // MARK: - Watching

    /// Looks every `interval` until the task is cancelled, or, with
    /// `untilOpened`, until the person opens it after it was closed or
    /// stuck: then it returns true. One already open when it starts is
    /// left alone, as whatever stopped the run there isn't the Duo being
    /// closed.
    func watch(mayStart: Bool, untilOpened: Bool, onEvent: (Event) -> Void = { _ in }) async -> Bool {
        while !Task.isCancelled, simulators != nil {
            let event = await look(mayStart: mayStart)
            if let event { onEvent(event) }
            if untilOpened, event == .opened { return true }
            // Less often while there's nothing to see: no helper that can
            // look, or no simulator yet.
            try? await Task.sleep(for: state.isWatched ? interval : interval * 3)
        }
        return false
    }

    /// One look, and the step it calls for (`DuoStep`); nothing while
    /// another look is under way.
    @discardableResult
    func look(mayStart: Bool) async -> Event? {
        guard let simulators, !isLooking else { return nil }
        isLooking = true
        defer { isLooking = false }
        guard simulators.hasHelper else {
            state = .noHelper
            return nil
        }
        if simulators.inventory == nil { await simulators.check() }
        guard let device = simulators.inventory?.simulator(for: .iPhoneDuo) else {
            state = simulators.state == .oldHelper ? .oldHelper : .noSimulator
            return nil
        }
        guard let look = await look(at: device) else { return nil }
        switch DuoStep.next(after: look, restarts: restarts, mayStart: mayStart, now: now()) {
        case .start:
            return await start(device.udid)
        case let .restart(reason):
            return await restart(device.udid, because: reason)
        case let .giveUp(reason):
            state = .stuck(reason)
            return nil
        case .wait:
            return settle(look.inner)
        }
    }

    /// What a running Duo's inner display shows, and whether its
    /// SpringBoard crashed; nil when that can't be told, and `state` says
    /// why.
    private func look(at device: SimulatorInventory.Device) async -> DuoStep.Look? {
        guard device.isBooted else {
            spinnerSince = nil
            return DuoStep.Look(isBooted: false)
        }
        switch await read(device.udid) {
        case .olderHelper:
            state = .oldHelper
            return nil
        case let .unreadable(reason):
            // Shut down in Device Hub since the last check, maybe.
            await simulators?.check()
            if simulators?.inventory?.simulator(for: .iPhoneDuo)?.isBooted == true {
                state = .failed(reason ?? String(localized: "AppLocalizer couldn’t read iPhone Duo’s inner display."))
            }
            return nil
        case let .seen(inner):
            spinnerSince = inner == .spinner ? spinnerSince ?? now() : nil
            let crashed = inner == .showing ? false : await crashedSinceStart(device.udid)
            return DuoStep.Look(isBooted: true, inner: inner, crashedSinceStart: crashed, spinnerSince: spinnerSince)
        }
    }

    /// Nothing to do: the state is what it shows. `.opened` once it's open
    /// after being seen closed or stuck.
    private func settle(_ inner: DuoInnerDisplay?) -> Event? {
        let before = state
        state = inner.map(DuoState.init) ?? .notRunning
        guard state == .open else { return nil }
        restarts = 0
        return before.isWatched && before != .open ? .opened : nil
    }

    // MARK: - Steps

    private func start(_ udid: String) async -> Event? {
        guard let simulators else { return nil }
        state = .starting
        let answer = await simulators.run(["boot-simulator", udid])
        inner = nil
        await simulators.check()
        guard answer.succeeded else {
            state = .failed(answer.failure ?? String(localized: "iPhone Duo didn’t start."))
            return nil
        }
        state = .closed
        return .started
    }

    private func restart(_ udid: String, because reason: DuoStep.Reason) async -> Event? {
        guard let simulators else { return nil }
        state = .restarting(reason)
        restarts += 1
        spinnerSince = nil
        // It may have shut down already; starting it is what matters.
        _ = await simulators.run(["shutdown-simulator", udid])
        let answer = await simulators.run(["boot-simulator", udid])
        inner = nil
        await simulators.check()
        guard answer.succeeded else {
            state = .failed(answer.failure ?? String(localized: "iPhone Duo didn’t start again."))
            return nil
        }
        state = .closed
        return .restarted(reason)
    }

    // MARK: - The helper

    private enum Reading {
        case seen(DuoInnerDisplay)
        case unreadable(String?)
        case olderHelper
    }

    /// The inner display, found by its size the first time after each
    /// start.
    private func read(_ udid: String) async -> Reading {
        guard let simulators else { return .unreadable(nil) }
        if inner?.udid != udid {
            let answer = await simulators.run(["simulator-displays", udid])
            if answer.isFromOlderHelper { return .olderHelper }
            let list = SimulatorDisplayList.parse(answer.lines.joined(separator: "\n"))
            guard answer.succeeded, let display = list.display(sized: ScreenshotDisplayType.iPhoneDuo.portraitPixelSize) else {
                return .unreadable(answer.failure)
            }
            inner = (udid, display.id)
        }
        guard let inner else { return .unreadable(nil) }
        let answer = await simulators.run(["simulator-screenshot", udid, inner.display])
        if answer.isFromOlderHelper { return .olderHelper }
        guard answer.succeeded, let seen = DuoInnerDisplay(base64: answer.lines.joined()) else {
            self.inner = nil
            return .unreadable(answer.failure)
        }
        return .seen(seen)
    }

    private func crashedSinceStart(_ udid: String) async -> Bool {
        guard let simulators else { return false }
        let answer = await simulators.run(["simulator-crashes", udid])
        return answer.succeeded && answer.lines.contains { $0.contains("SpringBoard") }
    }
}
