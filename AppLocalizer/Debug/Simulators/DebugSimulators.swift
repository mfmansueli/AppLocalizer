//
//  DebugSimulators.swift
//  AppLocalizer
//

#if DEBUG
import Foundation
import Synchronization

/// A pretend Mac's simulators for DEBUG scenes and tests, as the helper
/// answers them: Xcode with iOS 26.5 and 27.0 and watchOS 27.0, an iPhone
/// 17 Pro Max, an iPad Pro 13-inch (M5) and an Apple Watch Ultra 3 made.
/// iPhone Duo needs iOS 27.1, so it can't be captured until "iOS 27.2" is
/// installed (a few progress lines), and then made; Apple Vision Pro has no
/// visionOS simulator.
enum DebugSimulators {
    struct Mac: Sendable {
        var hasNewRuntime = false
        var hasDuo = false
        /// The every-device scenes' Mac also runs Apple Vision Pro.
        var hasVision = false
    }

    /// The pretend Mac, changed by `install-platform` and `create-simulator`.
    static let mac = Mutex(Mac())

    static let modes: Set<String> = ["simulators", "install-platform", "create-simulator"]

    /// The every-device scenes' Mac: it runs Apple Vision Pro too.
    static func runEveryDevice() {
        mac.withLock { $0.hasVision = true }
    }

    static let downloadLines = [
        "Downloading iOS 27.2 Simulator (24C61): 12.4% (1.09 GB of 8.81 GB)",
        "Downloading iOS 27.2 Simulator (24C61): 61.0% (5.37 GB of 8.81 GB)",
        "Installing iOS 27.2 Simulator (24C61)",
        "Done downloading: iOS 27.2 Simulator (24C61).",
    ]

    /// The helper's answer to one of `modes`.
    static func answer(_ arguments: [String], delay: Duration = .milliseconds(300), onLine: @Sendable (String) -> Void) async -> UnixScriptExit {
        switch arguments.first {
        case "install-platform":
            for line in downloadLines {
                try? await Task.sleep(for: delay)
                onLine(line)
            }
            mac.withLock { $0.hasNewRuntime = true }
        case "create-simulator":
            mac.withLock { $0.hasDuo = $0.hasNewRuntime }
            onLine("6F0D2C5E-0A3B-4C1D-9E8F-1A2B3C4D5E6F")
        default:
            onLine(json(mac.withLock { $0 }))
        }
        onLine("\(ClaudeCodeHelperScript.exitMarker) 0")
        return UnixScriptExit()
    }

    /// `simctl list -j runtimes devicetypes devices` for `mac`.
    static func json(_ mac: Mac) -> String {
        let iPhone = type("iPhone 17 Pro Max", "iPhone-17-Pro-Max", min: "26.0.0")
        let iPad = type("iPad Pro 13-inch (M5)", "iPad-Pro-13-inch-M5", min: "26.0.0")
        let duo = type("iPhone Duo", "iPhone-Duo", min: "27.1.0")
        let watch = type("Apple Watch Ultra 3 (49mm)", "Apple-Watch-Ultra-3-49mm", min: "26.0.0")
        let vision = type("Apple Vision Pro", "Apple-Vision-Pro", min: "3.0.0")
        var runtimes = [
            runtime("iOS", "26.5", runs: [iPhone, iPad]),
            runtime("iOS", "27.0", runs: [iPhone, iPad]),
            runtime("watchOS", "27.0", runs: [watch]),
        ]
        var devices: [String: Any] = [
            runtimeID("iOS", "27.0"): [device("iPhone 17 Pro Max", iPhone, 1), device("iPad Pro 13-inch (M5)", iPad, 2)],
            runtimeID("watchOS", "27.0"): [device("Apple Watch Ultra 3 (49mm)", watch, 3)],
        ]
        if mac.hasNewRuntime { runtimes.append(runtime("iOS", "27.2", runs: [iPhone, iPad, duo])) }
        if mac.hasDuo { devices[runtimeID("iOS", "27.2")] = [device("iPhone Duo", duo, 4)] }
        if mac.hasVision {
            runtimes.append(runtime("xrOS", "3.0", runs: [vision]))
            devices[runtimeID("xrOS", "3.0")] = [device("Apple Vision Pro", vision, 5)]
        }
        let list: [String: Any] = ["runtimes": runtimes, "devicetypes": [iPhone, iPad, duo, watch, vision], "devices": devices]
        let data = (try? JSONSerialization.data(withJSONObject: list, options: [.sortedKeys])) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func type(_ name: String, _ id: String, min: String) -> [String: Any] {
        ["name": name, "identifier": "com.apple.CoreSimulator.SimDeviceType.\(id)", "minRuntimeVersionString": min]
    }

    private static func runtimeID(_ platform: String, _ version: String) -> String {
        "com.apple.CoreSimulator.SimRuntime.\(platform)-\(version.replacingOccurrences(of: ".", with: "-"))"
    }

    private static func runtime(_ platform: String, _ version: String, runs types: [[String: Any]]) -> [String: Any] {
        [
            "identifier": runtimeID(platform, version), "name": "\(platform) \(version)", "version": version, "platform": platform,
            "isAvailable": true, "supportedDeviceTypes": types.map { ["identifier": $0["identifier"] ?? "", "name": $0["name"] ?? ""] },
        ]
    }

    private static func device(_ name: String, _ type: [String: Any], _ number: Int) -> [String: Any] {
        [
            "name": name, "udid": String(format: "00000000-0000-0000-0000-%012d", number),
            "deviceTypeIdentifier": type["identifier"] ?? "", "isAvailable": true, "state": "Shutdown",
        ]
    }
}
#endif
