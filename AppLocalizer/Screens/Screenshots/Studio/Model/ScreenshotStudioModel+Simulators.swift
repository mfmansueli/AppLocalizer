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
        Task { await autopilot.leaveOut(display, appID: appID, context: context) }
    }

    /// Once the device can be captured, its device-wide problems are
    /// retried.
    private func retryDeviceProblems(on display: ScreenshotDisplayType) async {
        guard simulators?.status(for: display)?.canCapture == true, let run, let autopilot else { return }
        let ids = run.openProblems.filter { $0.isDeviceWide && $0.target.displayType == display }.map(\.id)
        guard !ids.isEmpty else { return }
        await autopilot.resolveProblems(appID: app.id, problemIDs: ids, with: .retryWithFix, context: context)
    }

    /// At Start, a planned device this Mac can't run is one problem
    /// already, so the assistant doesn't try it screen by screen.
    func reportMissingSimulators() {
        guard let run, let autopilot, let simulators else { return }
        for display in simulators.missing(in: run.plan.displayTypes) {
            guard let status = simulators.status(for: display), let target = run.plan.targets.first(where: { $0.displayType == display }) else {
                continue
            }
            _ = try? autopilot.reportProblem(
                appID: app.id, target: target,
                what: String(localized: "This Mac can’t run the \(display.deviceName) simulator. \(status.detail)"),
                proposedFix: status.platformToInstall.map { String(localized: "Install the \($0) simulator (xcodebuild -downloadPlatform \($0)).") },
                affectsDevice: true
            )
        }
    }
}
