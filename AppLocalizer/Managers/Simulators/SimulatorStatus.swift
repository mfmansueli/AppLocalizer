//
//  SimulatorStatus.swift
//  AppLocalizer
//

import Foundation

/// Whether a device can be captured on this Mac (`SimulatorInventory`).
enum SimulatorStatus: Hashable, Sendable {
    /// A simulator is there: "iPhone 17 Pro Max", "iOS 27.0".
    case ready(simulator: String, runtime: String)
    /// The device type and a runtime that runs it are installed, but no
    /// simulator is made yet.
    case canMake(deviceType: String, deviceTypeID: String, runtime: String, runtimeID: String)
    /// No installed runtime runs the device: "iOS", "27.1", what's
    /// installed for that platform.
    case needsRuntime(platform: String, minimumVersion: String?, installed: [String])
    /// This Xcode doesn't know the device.
    case needsNewerXcode(deviceName: String)

    /// A simulator is there or can be made in a moment.
    var canCapture: Bool {
        switch self {
        case .ready, .canMake: true
        case .needsRuntime, .needsNewerXcode: false
        }
    }

    /// The platform `xcodebuild -downloadPlatform` installs, when that's
    /// what's missing.
    var platformToInstall: String? {
        if case let .needsRuntime(platform, _, _) = self { return platform }
        return nil
    }

    /// "iPhone 17 Pro Max · iOS 27.0"; "Needs the iOS 27.1 simulator or
    /// later. This Mac has iOS 26.5 and iOS 27.0."
    var detail: String {
        switch self {
        case let .ready(simulator, runtime):
            return "\(simulator) · \(runtime)"
        case let .canMake(deviceType, _, runtime, _):
            return String(localized: "No \(deviceType) simulator yet. It can be made on \(runtime) in a few seconds.")
        case let .needsRuntime(platform, minimum, installed):
            let needs = minimum.map { String(localized: "Needs the \(platform) \($0) simulator or later.") }
                ?? String(localized: "Needs the \(platform) simulator.")
            let has = installed.isEmpty
                ? String(localized: "This Mac has no \(platform) simulator.")
                : String(localized: "This Mac has \(installed.formatted(.list(type: .and))).")
            return needs + " " + has
        case let .needsNewerXcode(deviceName):
            return String(localized: "This Xcode doesn’t have the \(deviceName) simulator; it needs a newer Xcode.")
        }
    }
}
