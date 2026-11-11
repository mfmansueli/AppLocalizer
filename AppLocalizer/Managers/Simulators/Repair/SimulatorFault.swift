//
//  SimulatorFault.swift
//  AppLocalizer
//

import Foundation

/// Why no simulator starts on this Mac although they're installed, when
/// it's something AppLocalizer can put right itself (`SimulatorRepair`):
/// read from what `xcrun simctl` or the assistant said.
enum SimulatorFault: String, Hashable, Sendable, CaseIterable {
    /// The Mac's audio service (coreaudiod) is stuck: every start fails
    /// with "SimAudioProcessorServices failed to create an audio route
    /// descriptor". Restarting it needs an administrator's password.
    case audioService
    /// CoreSimulator's own service lost track of the simulators: starts
    /// fail or hang until it's restarted.
    case simulatorService

    /// The fault `text` describes, if it's one of these. The audio service
    /// first: its message also reads as a start that failed.
    static func matching(_ text: String) -> SimulatorFault? {
        let text = text.lowercased()
        if audioSigns.contains(where: text.contains) { return .audioService }
        if serviceSigns.contains(where: text.contains) { return .simulatorService }
        return nil
    }

    private static let audioSigns = ["simaudioprocessorservices", "audio route descriptor"]

    private static let serviceSigns = [
        "coresimulatorservice connection", "unable to boot device", "failed to boot", "won't boot", "won’t boot",
        "launchd failed to respond", "unable to lookup in current state",
    ]

    /// "This Mac’s audio service is stuck, so no simulator can start."
    var summary: String {
        switch self {
        case .audioService: String(localized: "This Mac’s audio service is stuck, so no simulator can start.")
        case .simulatorService: String(localized: "This Mac’s simulator service is stuck, so no simulator can start.")
        }
    }
}
