//
//  SimulatorRepair.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Puts this Mac's simulators right when none will start, so a run doesn't
/// stop on something the person may not know how to fix. Alba's run
/// stopped with all 294 captures waiting: the Mac's audio service had been
/// stuck for days, every `simctl boot` failed with "SimAudioProcessorServices
/// failed to create an audio route descriptor", and the card said to run
/// `sudo killall coreaudiod` in Terminal.
///
/// Through the helper, outside the sandbox: `repair-simulators` shuts the
/// simulators down and restarts CoreSimulator's service; `repair-audio`
/// restarts the audio service too, which is the system's, so macOS asks
/// for an administrator's password. After each, one simulator is started
/// (`boot-simulator`) to see that it worked.
@MainActor
@Observable
final class SimulatorRepair {
    private(set) var state: SimulatorRepairState = .idle
    /// The problems a repair was already tried for on its own, so one that
    /// didn't work isn't tried again and again; Fix It still can.
    @ObservationIgnored private(set) var attempted: Set<String> = []

    @ObservationIgnored private weak var simulators: MacSimulators?

    /// The helper's status when the person closed the password request.
    nonisolated static let declinedStatus: Int32 = 77

    init(simulators: MacSimulators) {
        self.simulators = simulators
    }

    /// True the first time for these problems: an automatic repair goes
    /// ahead and they're remembered.
    func shouldTryOnItsOwn(for problemIDs: [String]) -> Bool {
        guard !state.isWorking, !attempted.isSuperset(of: problemIDs) else { return false }
        attempted.formUnion(problemIDs)
        return true
    }

    /// Repairs `fault`, then starts the simulator `probe` (its UDID) to
    /// see that it worked. A simulator service that's restarted and still
    /// fails over audio goes on to the audio service.
    @discardableResult
    func repair(_ fault: SimulatorFault, probe: String?) async -> SimulatorRepairState {
        guard let simulators, !state.isWorking else { return state }
        guard simulators.hasHelper else { return finish(.needsHelper) }
        if fault == .simulatorService {
            state = .restartingSimulators
            let answer = await simulators.run(["repair-simulators"])
            if answer.isFromOlderHelper { return finish(.needsHelper) }
            guard let failure = await startFailure(probe) else { return finish(.repaired) }
            guard SimulatorFault.matching(failure) == .audioService else { return finish(.failed(failure)) }
        }
        state = .restartingAudio
        let answer = await simulators.run(["repair-audio"])
        if answer.isFromOlderHelper { return finish(.needsHelper) }
        if answer.status == Self.declinedStatus { return finish(.declined) }
        guard answer.succeeded else {
            return finish(.failed(answer.failure ?? String(localized: "The audio service couldn’t be restarted.")))
        }
        if let failure = await startFailure(probe) { return finish(.failed(failure)) }
        return finish(.repaired)
    }

    /// Why the probe simulator doesn't start; nil when it does, or when
    /// there's none to try.
    private func startFailure(_ probe: String?) async -> String? {
        guard let simulators, let probe else { return nil }
        state = .checking
        let answer = await simulators.run(["boot-simulator", probe])
        guard !answer.succeeded else { return nil }
        let said = answer.lines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return said.last { SimulatorFault.matching($0) != nil } ?? said.last ?? answer.failure
            ?? String(localized: "The simulator didn’t start.")
    }

    private func finish(_ outcome: SimulatorRepairState) -> SimulatorRepairState {
        state = outcome
        return outcome
    }
}
