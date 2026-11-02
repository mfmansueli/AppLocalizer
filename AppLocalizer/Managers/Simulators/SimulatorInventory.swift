//
//  SimulatorInventory.swift
//  AppLocalizer
//

import Foundation

/// This Mac's simulators as `xcrun simctl list -j runtimes devicetypes
/// devices` lists them: the installed runtimes (each with the device types
/// it runs), the device types Xcode knows, and the simulators made.
struct SimulatorInventory: Decodable, Hashable, Sendable {
    struct Runtime: Decodable, Hashable, Sendable {
        var identifier: String
        /// "iOS 27.0".
        var name: String
        /// "27.0".
        var version: String
        /// "iOS", "watchOS", "xrOS".
        var platform: String?
        var isAvailable: Bool
        var supportedDeviceTypes: [DeviceTypeReference]?

        func supports(_ type: DeviceType) -> Bool {
            supportedDeviceTypes?.contains { $0.identifier == type.identifier } == true
        }
    }

    struct DeviceTypeReference: Decodable, Hashable, Sendable {
        var identifier: String
    }

    struct DeviceType: Decodable, Hashable, Sendable {
        var identifier: String
        /// "iPhone Duo".
        var name: String
        /// "27.1.0": the oldest runtime it runs on.
        var minRuntimeVersionString: String?
    }

    struct Device: Decodable, Hashable, Sendable {
        var udid: String
        var name: String
        var deviceTypeIdentifier: String?
        var isAvailable: Bool?
        /// "Booted", "Shutdown", "Booting".
        var state: String?

        var isBooted: Bool { state == "Booted" }
    }

    var runtimes: [Runtime]
    var deviceTypes: [DeviceType]
    /// Runtime identifier → the simulators made with it.
    var devices: [String: [Device]]

    private enum CodingKeys: String, CodingKey {
        case runtimes
        case deviceTypes = "devicetypes"
        case devices
    }

    /// Reads `simctl`'s JSON.
    static func parse(_ json: String) throws -> SimulatorInventory {
        try JSONDecoder().decode(SimulatorInventory.self, from: Data(json.utf8))
    }

    /// Whether `display` can be captured on this Mac, and if not, what's
    /// missing. A simulator already made comes first, then one that can be
    /// made, each on the newest runtime that runs its device type.
    func status(for display: ScreenshotDisplayType) -> SimulatorStatus {
        let types = display.simulatorDeviceTypes.compactMap { name in deviceTypes.first { $0.name == name } }
        guard let preferred = types.first else { return .needsNewerXcode(deviceName: display.deviceName) }
        let runtimes = runtimes.filter(\.isAvailable).sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
        for type in types {
            for runtime in runtimes where runtime.supports(type) {
                let made = devices[runtime.identifier]?.first { $0.deviceTypeIdentifier == type.identifier && $0.isAvailable != false }
                if let made { return .ready(simulator: made.name, runtime: runtime.name) }
            }
        }
        for type in types {
            if let runtime = runtimes.first(where: { $0.supports(type) }) {
                return .canMake(deviceType: type.name, deviceTypeID: type.identifier, runtime: runtime.name, runtimeID: runtime.identifier)
            }
        }
        let installed = runtimes.filter { display.simulatorRuntimePlatforms.contains($0.platform ?? "") }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
            .map(\.name)
        return .needsRuntime(
            platform: display.simulatorPlatform,
            minimumVersion: preferred.minRuntimeVersionString.map(Self.shortVersion),
            installed: installed
        )
    }

    /// The simulator `display`'s captures come from: one that's running
    /// first, else the newest runtime's, as `status(for:)` picks it. Nil
    /// when none is made.
    func simulator(for display: ScreenshotDisplayType) -> Device? {
        let types = Set(display.simulatorDeviceTypes.compactMap { name in deviceTypes.first { $0.name == name }?.identifier })
        let made = runtimes.filter(\.isAvailable)
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
            .flatMap { devices[$0.identifier] ?? [] }
            .filter { types.contains($0.deviceTypeIdentifier ?? "") && $0.isAvailable != false }
        return made.first(where: \.isBooted) ?? made.first
    }

    /// "27.1.0" → "27.1"; "27.0.0" → "27.0".
    static func shortVersion(_ version: String) -> String {
        let parts = version.split(separator: ".")
        guard parts.count > 2, parts.dropFirst(2).allSatisfy({ $0 == "0" }) else { return version }
        return parts.prefix(2).joined(separator: ".")
    }
}
