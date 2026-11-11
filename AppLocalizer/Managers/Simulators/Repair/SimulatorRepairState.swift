//
//  SimulatorRepairState.swift
//  AppLocalizer
//

import Foundation

/// Where AppLocalizer's own repair of this Mac's simulators stands
/// (`SimulatorRepair`).
enum SimulatorRepairState: Hashable, Sendable {
    case idle
    /// Shutting the simulators down and restarting their service.
    case restartingSimulators
    /// Restarting the Mac's audio service: macOS is asking for an
    /// administrator's password.
    case restartingAudio
    /// Starting a simulator to see whether the repair worked.
    case checking
    /// A simulator starts again.
    case repaired
    /// The person closed macOS's password request.
    case declined
    /// The saved helper is from before it could repair, or isn't saved.
    case needsHelper
    /// It still doesn't start: what `simctl` said.
    case failed(String)

    var isWorking: Bool {
        switch self {
        case .restartingSimulators, .restartingAudio, .checking: true
        case .idle, .repaired, .declined, .needsHelper, .failed: false
        }
    }

    /// What the problem's card says under the fault, nil while idle.
    var message: String? {
        switch self {
        case .idle: nil
        case .restartingSimulators: String(localized: "AppLocalizer is restarting this Mac’s simulators…")
        case .restartingAudio:
            String(localized: "AppLocalizer is restarting this Mac’s audio service. macOS asks for your password: it’s the system’s to restart.")
        case .checking: String(localized: "Starting a simulator to see that it works again…")
        case .repaired: String(localized: "The simulators start again. The run goes on by itself.")
        case .declined:
            String(localized: "The password request was closed, so the audio service wasn’t restarted. Fix It asks again; restarting the Mac fixes it too.")
        case .needsHelper:
            String(localized: "AppLocalizer repairs this through its helper, and the saved one is from before it could: save it again and the repair starts.")
        case let .failed(reason):
            String(localized: "AppLocalizer restarted what it could and a simulator still doesn’t start: \(reason) Restarting the Mac usually fixes it.")
        }
    }
}
