//
//  DebugSimulators.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation
import ImageIO
import Synchronization
import UniformTypeIdentifiers

/// A pretend Mac's simulators for DEBUG scenes and tests, as the helper
/// answers them: Xcode with iOS 26.5 and 27.0 and watchOS 27.0, an iPhone
/// 17 Pro Max, an iPad Pro 13-inch (M5) and an Apple Watch Ultra 3 made.
/// iPhone Duo needs iOS 27.1, so it can't be captured until "iOS 27.2" is
/// installed (a few progress lines), and then made; Apple Vision Pro has no
/// visionOS simulator. The Duo's scenes have it made and running, and say
/// what its inner display shows (`DuoWatcher`), whether AppLocalizer is
/// allowed in Accessibility to open it, and which helper answers.
enum DebugSimulators {
    struct Mac: Sendable {
        /// The iPad Pro 13-inch (M5) simulator is made.
        var hasIPad = true
        var hasNewRuntime = false
        var hasDuo = false
        /// The every-device scenes' Mac also runs Apple Vision Pro.
        var hasVision = false
        var duoIsBooted = false
        var duoInner: DuoInnerDisplay = .black
        /// Its SpringBoard crashed since it started: it's stuck.
        var duoCrashed = false
        /// The pretend person opens it in Device Hub after this many looks.
        var duoOpensAfterLooks: Int?
        var duoLooks = 0
        /// The saved helper's version: 3 can't look at the Duo, 4 can't
        /// open it.
        var helperVersion = ClaudeCodeHelperScript.version
        /// macOS lets AppLocalizer press Open in Device Hub.
        var isAccessibilityAllowed = true
        /// The pretend person allows it after this many asks.
        var accessibilityAfterAsks: Int?
        var accessibilityAsks = 0
        /// `runDuo` set it up: a scene's view is built more than once, and
        /// must not make a restarted Duo stuck again.
        var duoIsSetUp = false
    }

    /// The pretend Mac, changed by `install-platform` and `create-simulator`.
    static let mac = Mutex(Mac())

    static let modes: Set<String> = [
        "simulators", "install-platform", "create-simulator", "simulator-displays", "simulator-screenshot", "simulator-crashes",
        "boot-simulator", "shutdown-simulator", "open-duo", "accessibility",
    ]

    /// The Duo's modes, by the helper version that has them.
    static let duoModes: [String: Int] = [
        "simulator-displays": 4, "simulator-screenshot": 4, "simulator-crashes": 4, "boot-simulator": 4, "shutdown-simulator": 4,
        "open-duo": 5, "accessibility": 5,
    ]

    /// The pretend Duo's inner display; the cover one is 1398 × 2034.
    static let innerDisplayID = "3B2A1C0D-0000-4000-8000-000000000003"

    /// The every-device scenes' Mac: it runs Apple Vision Pro too.
    static func runEveryDevice() {
        mac.withLock { $0.hasVision = true }
    }

    /// Plan · This Mac: iPhone Duo made and running but closed, and no
    /// iPad simulator yet (Make the Simulator).
    static func runWithoutIPad() {
        mac.withLock { mac in
            mac.hasIPad = false
            mac.hasNewRuntime = true
            mac.hasDuo = true
            mac.duoIsBooted = true
            mac.duoIsSetUp = true
        }
    }

    /// A helper saved before it could list simulators (version 2).
    static func runOldHelper() {
        mac.withLock { $0.helperVersion = 2 }
    }

    /// A Mac with iPhone Duo's simulator made, on iOS 27.2: running or
    /// not, what its inner display shows, whether it's stuck, when the
    /// pretend person opens it, the helper's version, and whether (and
    /// after how many asks) AppLocalizer is allowed in Accessibility.
    static func runDuo(
        booted: Bool = false, inner: DuoInnerDisplay = .black, crashed: Bool = false, opensAfterLooks: Int? = nil,
        helperVersion: Int = ClaudeCodeHelperScript.version, accessibility: Bool = true, accessibilityAfterAsks: Int? = nil
    ) {
        mac.withLock { mac in
            guard !mac.duoIsSetUp else { return }
            mac.duoIsSetUp = true
            mac.hasNewRuntime = true
            mac.hasDuo = true
            mac.duoIsBooted = booted
            mac.duoInner = inner
            mac.duoCrashed = crashed
            mac.duoOpensAfterLooks = opensAfterLooks
            mac.helperVersion = helperVersion
            mac.isAccessibilityAllowed = accessibility
            mac.accessibilityAfterAsks = accessibilityAfterAsks
        }
    }

    static let downloadLines = [
        "Downloading iOS 27.2 Simulator (24C61): 12.4% (1.09 GB of 8.81 GB)",
        "Downloading iOS 27.2 Simulator (24C61): 61.0% (5.37 GB of 8.81 GB)",
        "Installing iOS 27.2 Simulator (24C61)",
        "Done downloading: iOS 27.2 Simulator (24C61).",
    ]

    /// The helper's answer to one of `modes`.
    static func answer(_ arguments: [String], delay: Duration = .milliseconds(300), onLine: @Sendable (String) -> Void) async -> UnixScriptExit {
        if arguments.first == "simulators", mac.withLock({ $0.helperVersion }) < 3 {
            return UnixScriptExit(errorOutput: "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…>")
        }
        if let mode = arguments.first, let version = duoModes[mode] {
            if mac.withLock({ $0.helperVersion }) < version {
                return UnixScriptExit(errorOutput: "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…> | simulators | …")
            }
            let status = await answerDuo(mode, delay: delay, onLine: onLine)
            onLine("\(ClaudeCodeHelperScript.exitMarker) \(status)")
            return status == 0 ? UnixScriptExit() : UnixScriptExit(errorOutput: status == 77 ? "" : "Unable to lookup in current state: Shutdown")
        }
        switch arguments.first {
        case "install-platform":
            for line in downloadLines {
                try? await Task.sleep(for: delay)
                onLine(line)
            }
            mac.withLock { $0.hasNewRuntime = true }
        case "create-simulator":
            if arguments.contains(where: { $0.contains("iPad") }) {
                mac.withLock { $0.hasIPad = true }
            } else {
                mac.withLock { $0.hasDuo = $0.hasNewRuntime }
            }
            onLine("6F0D2C5E-0A3B-4C1D-9E8F-1A2B3C4D5E6F")
        default:
            onLine(json(mac.withLock { $0 }))
        }
        onLine("\(ClaudeCodeHelperScript.exitMarker) 0")
        return UnixScriptExit()
    }

    /// The Duo modes' lines; returns the status.
    private static func answerDuo(_ mode: String, delay: Duration, onLine: @Sendable (String) -> Void) async -> Int32 {
        switch mode {
        case "simulator-displays":
            guard mac.withLock({ $0.duoIsBooted }) else { return 149 }
            displayLines.forEach(onLine)
        case "simulator-screenshot":
            guard mac.withLock({ $0.duoIsBooted }) else { return 149 }
            let inner = mac.withLock { mac in
                mac.duoLooks += 1
                if let after = mac.duoOpensAfterLooks, mac.duoLooks >= after { mac.duoInner = .showing }
                return mac.duoInner
            }
            onLine(png(inner).base64EncodedString())
        case "simulator-crashes":
            if mac.withLock({ $0.duoCrashed }) { onLine("1730383600 SpringBoard-2026-10-31-140640.ips") }
        case "boot-simulator":
            try? await Task.sleep(for: delay)
            mac.withLock { mac in
                mac.duoIsBooted = true
                mac.duoInner = .black
            }
            onLine("Monitoring boot status for iPhone Duo (00000000-0000-0000-0000-000000000004).")
        case "shutdown-simulator":
            mac.withLock { mac in
                mac.duoIsBooted = false
                mac.duoCrashed = false
                mac.duoInner = .black
            }
        default:
            return await answerOpening(mode, delay: delay, onLine: onLine)
        }
        return 0
    }

    /// Opening the Duo in Device Hub (`open-duo`), and whether macOS
    /// allows it (`accessibility`).
    private static func answerOpening(_ mode: String, delay: Duration, onLine: @Sendable (String) -> Void) async -> Int32 {
        guard mode == "open-duo" || mode == "accessibility" else { return 0 }
        let isAllowed = isAccessibilityAllowed()
        guard mode == "open-duo" else {
            onLine(isAllowed ? "trusted" : "not-trusted")
            return 0
        }
        guard isAllowed else {
            onLine("accessibility-needed")
            return 77
        }
        try? await Task.sleep(for: delay)
        mac.withLock { $0.duoInner = .showing }
        onLine("pressed")
        return 0
    }

    /// Whether AppLocalizer may press Open; each ask counts toward the
    /// pretend person allowing it.
    private static func isAccessibilityAllowed() -> Bool {
        mac.withLock { mac in
            mac.accessibilityAsks += 1
            if let after = mac.accessibilityAfterAsks, mac.accessibilityAsks >= after { mac.isAccessibilityAllowed = true }
            return mac.isAccessibilityAllowed
        }
    }

    /// `simctl io enumerate`'s displays for the Duo: the cover, the inner.
    static let displayLines = [
        "Port:", "    UUID: 3B2A1C0D-0000-4000-8000-000000000001", "    Class: Display", "    Display class: 0",
        "    Default width: 1398", "    Default height: 2034",
        "Port:", "    UUID: \(innerDisplayID)", "    Class: Display", "    Display class: 0",
        "    Default width: 2007", "    Default height: 2853",
    ]

    /// A small screenshot of the inner display, as the helper sends it:
    /// black, a faint spinner in the middle, or an app.
    static func png(_ inner: DuoInnerDisplay, width: Int = 180, height: Int = 256) -> Data {
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return Data() }
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(bounds)
        switch inner {
        case .black:
            break
        case .spinner:
            context.setFillColor(CGColor(gray: 0.3, alpha: 1))
            context.fillEllipse(in: CGRect(x: width / 2 - 3, y: height / 2 - 3, width: 6, height: 6))
        case .showing:
            context.setFillColor(CGColor(red: 0.2, green: 0.17, blue: 0.36, alpha: 1))
            context.fill(bounds)
        }
        let data = NSMutableData()
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { return Data() }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
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
            runtimeID("iOS", "27.0"): [device("iPhone 17 Pro Max", iPhone, 1)] + (mac.hasIPad ? [device("iPad Pro 13-inch (M5)", iPad, 2)] : []),
            runtimeID("watchOS", "27.0"): [device("Apple Watch Ultra 3 (49mm)", watch, 3)],
        ]
        if mac.hasNewRuntime { runtimes.append(runtime("iOS", "27.2", runs: [iPhone, iPad, duo])) }
        if mac.hasDuo { devices[runtimeID("iOS", "27.2")] = [device("iPhone Duo", duo, 4, booted: mac.duoIsBooted)] }
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

    private static func device(_ name: String, _ type: [String: Any], _ number: Int, booted: Bool = false) -> [String: Any] {
        [
            "name": name, "udid": String(format: "00000000-0000-0000-0000-%012d", number),
            "deviceTypeIdentifier": type["identifier"] ?? "", "isAvailable": true, "state": booted ? "Booted" : "Shutdown",
        ]
    }
}
#endif
