//
//  DuoWatcher.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Watches iPhone Duo's simulator for Screenshot Autopilot, so the Duo
/// sorts itself out. AppLocalizer looks at its inner display every few
/// seconds through the helper; during a run it starts the Duo when it isn't
/// running and opens it when it's closed (no command does: the helper
/// presses Open in its window in Device Hub, which takes AppLocalizer being
/// allowed in Accessibility, `DeviceHub`), and it restarts a stuck one (its
/// SpringBoard crashed, or a spinner that doesn't go away). Once it's open,
/// the run captures it without a Retry. It never restarts an open Duo:
/// starting it again closes it.
@MainActor
@Observable
final class DuoWatcher {
    /// What it did or saw, for the run's log.
    enum Event: Hashable, Sendable {
        case started
        case restarted(DuoStep.Reason)
        /// The helper pressed Open in Device Hub.
        case pressedOpen
        /// It can't open the Duo until AppLocalizer is allowed in
        /// Accessibility: macOS asked the person, once.
        case askedForAccessibility
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
            case .pressedOpen:
                String(localized: "iPhone Duo was closed: AppLocalizer opened it in Device Hub")
            case .askedForAccessibility:
                String(localized: "AppLocalizer needs Accessibility to open iPhone Duo: macOS asked for it")
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
    /// Tries at opening it since it last started or was seen open.
    @ObservationIgnored private var opens = 0
    /// Why the last try at opening it failed.
    @ObservationIgnored private var openFailure: String?
    /// The helper is from before it could open the Duo.
    @ObservationIgnored private var helperCantOpen = false
    /// What the helper last said about Accessibility; nil before it's asked.
    @ObservationIgnored private var lacksAccessibility: Bool?
    /// macOS asks the person once.
    @ObservationIgnored private var hasAskedForAccessibility = false
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

    /// Looks every `interval` until the task is cancelled. `mayStart`:
    /// AppLocalizer starts and opens it (during a run, or when the person
    /// asks); otherwise it only says how it is, and restarts a stuck one.
    /// `.opened` comes once it's open after being closed or stuck; one
    /// already open when it starts is left alone, as whatever stopped the
    /// run there isn't the Duo being closed.
    func watch(mayStart: Bool, onEvent: (Event) async -> Void = { _ in }) async {
        while !Task.isCancelled, simulators != nil {
            if let event = await look(mayStart: mayStart) { await onEvent(event) }
            // Less often while there's nothing to see: no helper that can
            // look, or no simulator yet.
            try? await Task.sleep(for: state.isWatched ? interval : interval * 3)
        }
    }

    /// For a recording of its inner display (`DisplayRecorder`): starts and
    /// opens the Duo now if it needs to, and waits until it's open, until
    /// AppLocalizer can't do more by itself, or for `limit`. Its state then.
    func makeOpen(within limit: Duration, onEvent: (Event) async -> Void = { _ in }) async -> DuoState {
        let deadline = ContinuousClock.now + limit
        while !Task.isCancelled, simulators != nil {
            if let event = await look(mayStart: true) { await onEvent(event) }
            switch state {
            case .open, .noHelper, .oldHelper, .noSimulator, .failed:
                return state
            default:
                if state.waitsForPerson || ContinuousClock.now >= deadline { return state }
            }
            try? await Task.sleep(for: min(interval, .seconds(1)))
        }
        return state
    }

    /// The inner display it last read: the simulator and the display's ID.
    var innerDisplay: (udid: String, display: String)? {
        inner
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
        let opens = helperCantOpen ? DuoStep.maximumOpens : opens
        switch DuoStep.next(after: look, restarts: restarts, opens: opens, mayStart: mayStart, now: now()) {
        case .start:
            return await start(device.udid)
        case .open:
            return await open(device)
        case let .restart(reason):
            return await restart(device.udid, because: reason)
        case let .giveUp(reason):
            state = .stuck(reason)
            return nil
        case .wait:
            return await settle(look.inner)
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
    private func settle(_ inner: DuoInnerDisplay?) async -> Event? {
        let before = state
        let seen = inner.map(DuoState.init) ?? .notRunning
        state = seen == .closed ? await closedState() : seen
        guard state == .open else { return nil }
        restarts = 0
        opens = 0
        openFailure = nil
        return before.isWatched && before != .open ? .opened : nil
    }

    /// A closed Duo AppLocalizer isn't opening now: why not. While only
    /// looking (the plan), it asks the helper whether it may, until it may,
    /// so the person can allow it before the run.
    private func closedState() async -> DuoState {
        if helperCantOpen { return .helperCantOpen }
        if opens >= DuoStep.maximumOpens {
            return .couldntOpen(openFailure ?? String(localized: "Device Hub didn’t open it"))
        }
        if lacksAccessibility != false, let simulators {
            let answer = await simulators.run(["accessibility"])
            if answer.isFromOlderHelper {
                helperCantOpen = true
                return .helperCantOpen
            }
            if answer.succeeded { lacksAccessibility = !answer.lines.contains("trusted") }
        }
        return lacksAccessibility == true ? .needsAccessibility : .closed
    }

    // MARK: - Steps

    private func start(_ udid: String) async -> Event? {
        guard let simulators else { return nil }
        state = .starting
        opens = 0
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
        opens = 0
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

    /// The helper shows the Duo's window in Device Hub and presses Open.
    /// Without Accessibility it says so; macOS asks the person the first
    /// time, and later looks try again, so it opens once it's allowed.
    private func open(_ device: SimulatorInventory.Device) async -> Event? {
        guard let simulators else { return nil }
        state = .opening
        let answer = await simulators.run(["open-duo", device.udid, device.name])
        if answer.isFromOlderHelper {
            helperCantOpen = true
            state = .helperCantOpen
            return nil
        }
        if answer.lines.contains("accessibility-needed") {
            lacksAccessibility = true
            state = .needsAccessibility
            guard !hasAskedForAccessibility else { return nil }
            hasAskedForAccessibility = true
            _ = await simulators.run(["accessibility", "prompt"])
            return .askedForAccessibility
        }
        lacksAccessibility = false
        opens += 1
        guard answer.succeeded else {
            openFailure = Self.openFailure(answer)
            state = opens >= DuoStep.maximumOpens ? await closedState() : .closed
            return nil
        }
        // It lights up a moment later: the next look sees it open.
        return .pressedOpen
    }

    /// Why the helper couldn't open it, in a few words.
    private static func openFailure(_ answer: SimulatorHelperAnswer) -> String? {
        if answer.lines.contains("no-device-hub") { return String(localized: "this Mac’s Xcode has no Device Hub") }
        if answer.lines.contains("no-open-button") { return String(localized: "Device Hub didn’t show its Open pose") }
        return answer.failure
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
