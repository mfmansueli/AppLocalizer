//
//  AutopilotRun+MCP.swift
//  AppLocalizer
//

import Foundation

extension AutopilotRun {
    /// `get_capture_plan`'s result. `bundleID` is the app's, for granting
    /// its permissions.
    func mcpPlan(appName: String, bundleID: String, port: UInt16) -> JSONValue {
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
        // Each locale's own language (`zh-Hant` and `pt-PT` aren't `zh`
        // and `pt`) and its App Store country's formats.
        let newCodes = Set(plan.addedLocaleCodes)
        let locales: [JSONValue] = plan.capturedLocales.map { code in
            var locale: [String: JSONValue] = [
                "locale": .string(code),
                "launchArguments": .string(StoreLocale.simulatorLaunchArguments(for: code)),
                "testArguments": .string(StoreLocale.xcodebuildTestArguments(for: code)),
            ]
            if newCodes.contains(code) { locale["notOnAppStoreYet"] = true }
            return .object(locale)
        }
        var simulator: [String: JSONValue] = [
            "lightAppearance": .bool(plan.simulator.lightAppearance),
            "commands": .array(simulatorCommands(bundleID: bundleID).map(JSONValue.string)),
        ]
        if plan.simulator.lightAppearance { simulator["alerts"] = .string(AutopilotSimulatorSetup.alertsNote) }
        if plan.simulator.usesSampleData {
            simulator["sampleData"] = .string(
                plan.simulator.sampleDataSteps.isEmpty
                    ? "Find the app's sample-data switch (a debug menu, launch argument or UI test helper) and use it."
                    : plan.simulator.sampleDataSteps
            )
            if plan.capturesEachLanguage, plan.simulator.sampleDataInEachLanguage {
                simulator["sampleDataLanguage"] = .string(AutopilotSimulatorSetup.sampleDataLanguageNote)
            }
        }
        var json: [String: JSONValue] = [
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
            "preflight": AutopilotPreflight.json,
        ]
        if let rehearsal = AutopilotPreflight.rehearsalJSON(for: plan) { json["rehearsal"] = rehearsal }
        return .object(json)
    }

    /// "1320 × 2868"; iPhone Duo its inner display's, either way up (open,
    /// it's wider than tall); Apple Watch takes an Ultra's screen; Apple
    /// Vision Pro the app's window as it is.
    static func capturePixelSize(_ display: ScreenshotDisplayType) -> String {
        switch display {
        case .iPad: display.portraitPixelSize.rotated.title
        case .iPhoneDuo:
            String(localized: "\(display.portraitPixelSize.rotated.title) or \(display.portraitPixelSize.title) (the inner display, open)")
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
        case .iPhoneDuo:
            """
            Use the iPhone Duo simulator (Xcode 27.1 or later), open, so the app runs on the inner display. It starts closed \
            (the app on the 1398 × 2034 cover display, the inner one black), and no command opens it: AppLocalizer opens it \
            itself (it presses Open in the Duo's window in Device Hub) and restarts a stuck one. Don't open Device Hub, press \
            anything there, or shut down, reboot or erase the Duo yourself, which closes it again. Never change its displays \
            with xcrun simctl io … screenConfig, which crashes its SpringBoard on every start. A UI test's screenshot \
            (XCUIScreen.main) is the cover display, and the test closes the app right after it, too soon for simctl, so for \
            each UI test run on iPhone Duo: call start_display_recording (it opens the Duo and records the inner display), run \
            the test on the simulator it names with -resultBundlePath, then call finish_display_recording with that path. It \
            gives each screenshot the test attached as the inner display at that moment (2853 × 2007), with an upload ID for \
            report_capture; the project needs no change. A screen you open without a UI test (launch arguments), capture with \
            xcrun simctl io <udid> screenshot --display=<the 2007 × 2853 display's ID from xcrun simctl io <udid> enumerate>. \
            If start_display_recording says the Duo isn't open, or its inner display shows only a spinner, or SpringBoard \
            crashed and xcrun simctl launch hangs (stuck), report one problem with affectsDevice: true saying which, with \
            "AppLocalizer opens iPhone Duo" as proposedFix, and go on with the other devices: next_step gives you its screens \
            again once it's open. App Store Connect also takes the outer display's 1398 × 2034, but the template renders at \
            the inner display's size.
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

    /// The status bar, appearance, permissions and fix commands to run
    /// before capturing.
    func simulatorCommands(bundleID: String) -> [String] {
        var commands: [String] = []
        if plan.simulator.overridesStatusBar { commands.append(AutopilotSimulatorSetup.statusBarCommand) }
        if plan.simulator.lightAppearance { commands.append("xcrun simctl ui booted appearance light") }
        if plan.simulator.grantsPermissions, !bundleID.isEmpty {
            commands.append(AutopilotSimulatorSetup.permissionsCommand(bundleID: bundleID))
        }
        return commands + plan.simulator.extraCommands
    }
}
