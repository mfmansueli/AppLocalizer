//
//  ScreenshotStudioModel+Simulators.swift
//  AppLocalizer
//

import Foundation

/// This Mac's simulators for Autopilot: the check before Start, its fixes,
/// and a device left out when it can't be captured.
extension ScreenshotStudioModel {
    var simulators: MacSimulators? { launcher?.simulators }

    func checkSimulators() {
        guard let simulators else { return }
        Task { await simulators.check() }
    }

    /// Install Helper… or Save the Helper Again…, then the check.
    func installHelperAndCheck() {
        guard let launcher else { return }
        Task {
            await launcher.installHelper()
            await launcher.simulators.check()
        }
    }

    /// Downloads the platform's simulator and makes one; a run waiting on
    /// the device tries it again.
    func installSimulator(for display: ScreenshotDisplayType) {
        guard let simulators else { return }
        Task {
            await simulators.install(for: display)
            await retryDeviceProblems(on: display)
        }
    }

    func makeSimulator(for display: ScreenshotDisplayType) {
        guard let simulators else { return }
        Task {
            await simulators.make(for: display)
            await retryDeviceProblems(on: display)
        }
    }

    /// Leave a device that can't be captured out of this run.
    func leaveOut(_ display: ScreenshotDisplayType) {
        guard let autopilot else { return }
        let context = context
        let appID = app.id
        Task {
            await autopilot.leaveOut(display, appID: appID, context: context)
            await keepGoing()
        }
    }

    /// While iPhone Duo's card is shown, AppLocalizer starts the Duo when
    /// it isn't running and restarts it when it's stuck, both in the run's
    /// log, and once the person opens it in Device Hub its screens are
    /// tried again, without a Retry.
    func watchDuo() async {
        guard let simulators, let autopilot else { return }
        let appID = app.id
        let opened = await simulators.duo.watch(mayStart: true, untilOpened: true) { event in
            autopilot.update(appID) { $0.appendLog(event.logText, kind: .event, at: autopilot.now()) }
        }
        // Even when the card's task was replaced meanwhile: the opening is
        // seen once, and only the Duo's open problems are retried.
        guard opened, run?.stage == .capture else { return }
        await retryDeviceProblems(on: .iPhoneDuo)
    }

    /// Once the device can be captured, its device-wide problems are
    /// retried.
    private func retryDeviceProblems(on display: ScreenshotDisplayType) async {
        guard simulators?.status(for: display)?.canCapture == true, let run, let autopilot else { return }
        let ids = run.openProblems.filter { $0.isDeviceWide && $0.target.displayType == display }.map(\.id)
        guard !ids.isEmpty else { return }
        await autopilot.resolveProblems(appID: app.id, problemIDs: ids, with: .retryWithFix, context: context)
        await keepGoing()
    }

    /// At Start, a planned device this Mac can't run is one problem
    /// already, so the assistant doesn't try it screen by screen.
    func reportMissingSimulators() {
        guard let autopilot, let simulators else { return }
        autopilot.reportMissingSimulators(appID: app.id, simulators: simulators)
    }

    /// A run that's capturing is checked again when it's looked at: one
    /// started before the check, or before a simulator went away, gets its
    /// device's problem too, and the rest goes on.
    func checkDevicesDuringRun() async {
        guard let run, run.stage == .capture, let autopilot, let simulators else { return }
        if simulators.inventory == nil { await simulators.check() }
        autopilot.reportMissingSimulators(appID: app.id, simulators: simulators)
    }
}
