//
//  AutopilotRun+MCP.swift
//  AppLocalizer
//

import Foundation

extension AutopilotRun {
    /// `get_capture_plan`'s result.
    func mcpPlan(appName: String, port: UInt16) -> JSONValue {
        let upload = MCPEndpoint.autopilotUploadURL(port: port, token: uploadToken)
        let screens: [JSONValue] = plan.screens.enumerated().map { index, screen in
            [
                "id": .string(screen.id), "slot": .int(index + 1), "name": .string(screen.name),
                "steps": .string(screen.steps), "caption": .string(screen.caption),
            ]
        }
        let devices: [JSONValue] = plan.displayTypes.map { display in
            var device: [String: JSONValue] = [
                "displayType": .string(display.mcpValue),
                "simulator": .string(display.deviceName),
                "pixelSize": .string(Self.capturePixelSize(display)),
                "orientation": .string(display == .iPad || display == .visionPro ? "landscape" : "portrait"),
            ]
            if display.hasOwnScreens {
                device["screens"] = .array(plan.screens(on: display).enumerated().map { index, screen in
                    var item: [String: JSONValue] = [
                        "id": .string(screen.id), "slot": .int(index + 1), "name": .string(screen.name), "steps": .string(screen.steps),
                    ]
                    if let source = screen.sourceScreenID { item["sameMomentAs"] = .string(source) }
                    return .object(item)
                })
            }
            if let how = Self.howToCapture(display) { device["how"] = .string(how) }
            return .object(device)
        }
        // The whole code: `zh-Hant` and `pt-PT` aren't `zh` and `pt`, and
        // `de-DE` still finds `de.lproj`.
        let newCodes = Set(plan.addedLocaleCodes)
        let locales: [JSONValue] = plan.capturedLocales.map { code in
            var locale: [String: JSONValue] = [
                "locale": .string(code),
                "launchArguments": .string("-AppleLanguages (\(code)) -AppleLocale \(code.replacingOccurrences(of: "-", with: "_"))"),
            ]
            if newCodes.contains(code) { locale["notOnAppStoreYet"] = true }
            return .object(locale)
        }
        var simulator: [String: JSONValue] = [
            "lightAppearance": .bool(plan.simulator.lightAppearance),
            "commands": .array(simulatorCommands.map(JSONValue.string)),
        ]
        if plan.simulator.usesSampleData {
            simulator["sampleData"] = .string(
                plan.simulator.sampleDataSteps.isEmpty
                    ? "Find the app's sample-data switch (a debug menu, launch argument or UI test helper) and use it."
                    : plan.simulator.sampleDataSteps
            )
        }
        return [
            "run": .string(id),
            "app": .string(appName),
            "version": .string(versionString),
            "stage": .string(stage.rawValue),
            "chooseScreens": .bool(plan.choosesScreens && captures.isEmpty),
            "screens": .array(screens),
            "devices": .array(devices),
            "primaryLocale": .string(plan.primaryLocale),
            "locales": .array(locales),
            "capturesEachLanguage": .bool(plan.capturesEachLanguage),
            "simulatorSetup": .object(simulator),
            "attemptsPerScreen": 3,
            "captured": .int(capturedCount),
            "total": .int(totalCaptures),
            "upload": [
                "url": .string(upload),
                "how": .string("curl -s --data-binary @capture.png -H 'Content-Type: image/png' \(upload)"),
                "then": "report_capture with the returned upload ID",
            ],
        ]
    }

    /// "1320 × 2868"; Apple Watch takes an Ultra's screen; Apple Vision Pro
    /// the app's window as it is.
    static func capturePixelSize(_ display: ScreenshotDisplayType) -> String {
        switch display {
        case .iPad: display.portraitPixelSize.rotated.title
        case .watch: "422 × 514 (or 410 × 502)"
        case .visionPro: String(localized: "the app’s window, at least 600 px on its short side")
        default: display.portraitPixelSize.title
        }
    }

    /// How a device with screens of its own is captured.
    static func howToCapture(_ display: ScreenshotDisplayType) -> String? {
        switch display {
        case .watch:
            """
            Pair the watch simulator with the iPhone one (xcrun simctl pair), launch the watch app in each locale and capture each of the \
            watch screens below. No captions: the capture is the screenshot.
            """
        case .visionPro:
            """
            Launch the app on the Apple Vision Pro simulator in each locale and capture each window below at its default size, cropped to \
            the window. Each is the same moment as its iPhone screen (sameMomentAs); AppLocalizer puts it in a window under that screen's caption.
            """
        default:
            nil
        }
    }

    /// The status bar, appearance and fix commands to run before capturing.
    var simulatorCommands: [String] {
        var commands: [String] = []
        if plan.simulator.overridesStatusBar { commands.append(AutopilotSimulatorSetup.statusBarCommand) }
        if plan.simulator.lightAppearance { commands.append("xcrun simctl ui booted appearance light") }
        return commands + plan.simulator.extraCommands
    }
}
