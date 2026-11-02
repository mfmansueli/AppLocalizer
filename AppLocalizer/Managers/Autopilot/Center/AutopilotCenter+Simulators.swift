//
//  AutopilotCenter+Simulators.swift
//  AppLocalizer
//

import Foundation

/// A planned device this Mac can't run, as one problem for the device.
extension AutopilotCenter {
    /// Reports each planned device this Mac can't run as one problem for
    /// the whole device, so the assistant doesn't try it screen by screen
    /// and the other devices go on. At Start, and again whenever a run
    /// that's capturing is looked at or continued, so a run started before
    /// the check, or before a simulator went away, gets it too. A device
    /// that already has its problem open is left as it is. Returns the
    /// devices reported.
    @discardableResult
    func reportMissingSimulators(appID: StoreApp.ID, simulators: MacSimulators) -> [ScreenshotDisplayType] {
        guard let run = runs[appID], run.stage == .capture || run.stage == .waiting else { return [] }
        var reported: [ScreenshotDisplayType] = []
        for display in simulators.missing(in: run.plan.displayTypes) {
            let current = runs[appID] ?? run
            guard !current.openProblems.contains(where: { $0.isDeviceWide && $0.target.displayType == display }),
                  let status = simulators.status(for: display),
                  let target = current.plan.targets.first(where: { $0.displayType == display })
            else { continue }
            let problem = try? reportProblem(
                appID: appID, target: target,
                what: String(localized: "This Mac can’t run the \(display.deviceName) simulator. \(status.detail)"),
                proposedFix: status.platformToInstall.map { String(localized: "Install the \($0) simulator (xcodebuild -downloadPlatform \($0)).") },
                affectsDevice: true
            )
            if problem != nil { reported.append(display) }
        }
        return reported
    }
}
