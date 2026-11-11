//
//  ScreenshotStudioModel+SimulatorRepair.swift
//  AppLocalizer
//

import Foundation

/// A run stopped because no simulator starts on this Mac: AppLocalizer
/// repairs what it can itself (`SimulatorRepair`) and tries the devices
/// again, instead of leaving the person a Terminal command.
extension ScreenshotStudioModel {
    /// The run's open device-wide problems a known simulator fault
    /// explains, and the fault: the audio service's when any is about it,
    /// since its repair covers the other too.
    var simulatorFaultProblems: (fault: SimulatorFault, problems: [AutopilotProblem])? {
        guard let run, run.stage == .capture else { return nil }
        return Self.simulatorFaultProblems(in: run.openProblems)
    }

    nonisolated static func simulatorFaultProblems(in open: [AutopilotProblem]) -> (fault: SimulatorFault, problems: [AutopilotProblem])? {
        let found = open.compactMap { problem -> (SimulatorFault, AutopilotProblem)? in
            guard problem.isDeviceWide, problem.changesProject != true, !problem.wasRefused,
                  let fault = SimulatorFault.matching(problem.what + " " + (problem.proposedFix ?? ""))
            else { return nil }
            return (fault, problem)
        }
        guard !found.isEmpty else { return nil }
        let fault: SimulatorFault = found.contains { $0.0 == .audioService } ? .audioService : .simulatorService
        return (fault, found.map(\.1))
    }

    /// Changes when the problems to repair do, for the step's task.
    var simulatorFaultKey: String {
        simulatorFaultProblems?.problems.map(\.id).joined(separator: ",") ?? ""
    }

    /// The fault `group`'s card is about, if AppLocalizer can repair it.
    func simulatorFault(of group: AutopilotProblemGroup) -> SimulatorFault? {
        Self.simulatorFaultProblems(in: group.problems)?.fault
    }

    /// Save the Helper Again…, then the repair it was needed for.
    func saveHelperAndRepair() {
        guard let launcher else { return }
        Task { [screenshots] in
            await launcher.installHelper()
            await repairSimulators(on: launcher.simulators, asked: true)
            withExtendedLifetime(screenshots) {}
        }
    }

    /// Repairs this Mac's simulators for the problems that wait on them,
    /// then tries those devices again and lets the assistant go on. On its
    /// own once per problem; Fix It (`asked`) any time.
    func repairSimulators(on simulators: MacSimulators, asked: Bool = false) async {
        guard let autopilot, let found = simulatorFaultProblems else { return }
        let ids = found.problems.map(\.id)
        let repair = simulators.repair
        if asked {
            guard !repair.state.isWorking else { return }
        } else {
            guard repair.shouldTryOnItsOwn(for: ids) else { return }
        }
        let (appID, context, goOn) = (app.id, context, goingOn())
        let log = { (text: String) in autopilot.update(appID) { $0.appendLog(text, kind: .event, at: autopilot.now()) } }
        log(found.fault.summary + " " + String(localized: "AppLocalizer is repairing it."))
        if simulators.inventory == nil { await simulators.check() }
        // One of the stopped devices' simulators shows whether it worked.
        let probe = found.problems.lazy.compactMap { simulators.inventory?.simulator(for: $0.target.displayType)?.udid }.first
        let outcome = await repair.repair(found.fault, probe: probe)
        guard outcome == .repaired else {
            if let message = outcome.message { log(message) }
            return
        }
        log(String(localized: "The simulators start again. Trying the devices again."))
        await simulators.check()
        await autopilot.resolveProblems(appID: appID, problemIDs: ids, with: .retryWithFix, context: context)
        await goOn()
    }
}
