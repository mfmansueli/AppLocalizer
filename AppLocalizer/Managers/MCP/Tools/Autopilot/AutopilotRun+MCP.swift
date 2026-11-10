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
        let screens = plan.screens.enumerated().map { mcpScreen($0.element, slot: $0.offset + 1) }
        let devices: [JSONValue] = plan.runDisplays.map { display in
            var device: [String: JSONValue] = [
                "displayType": .string(display.mcpValue),
                "simulator": .string(display == .mac ? String(localized: "This Mac (no simulator)") : display.deviceName),
                "pixelSize": .string(Self.capturePixelSize(display)),
                "orientation": .string(Self.orientation(display)),
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
            if display == .iPhoneDuo { device["poses"] = mcpDuoPoses }
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
        var json: [String: JSONValue] = [
            "run": .string(id),
            "app": .string(appName),
            "version": .string(versionString),
            "stage": .string(stage.rawValue),
            "chooseScreens": .bool((plan.choosesScreens || plan.awaitsScreens) && captures.isEmpty),
            "screens": .array(screens),
            "devices": .array(devices),
            "primaryLocale": .string(plan.primaryLocale),
            "locales": .array(locales),
            "capturesEachLanguage": .bool(plan.capturesEachLanguage),
            "simulatorSetup": mcpSimulatorSetup(bundleID: bundleID),
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
        json["choosingScreens"] = mcpChoosingScreens
        json["rehearsal"] = AutopilotPreflight.rehearsalJSON(for: plan)
        json["alsoMake"] = mcpAlsoMake(upload: upload)
        json["noScreenshots"] = mcpNoScreenshots
        return .object(json)
    }

    /// `get_capture_plan`'s `simulatorSetup`: the commands to run (the
    /// fixes' last, also as `addedByFixes`), the fixes' notes, and how to
    /// get the alerts and sample data right.
    private func mcpSimulatorSetup(bundleID: String) -> JSONValue {
        let commands = simulatorCommands(bundleID: bundleID)
        var simulator: [String: JSONValue] = [
            "lightAppearance": .bool(plan.simulator.lightAppearance),
            "commands": .array(commands.map(JSONValue.string)),
        ]
        if !plan.simulator.extraCommands.isEmpty {
            simulator["addedByFixes"] = .array(plan.simulator.extraCommands.map(JSONValue.string))
        }
        if !plan.simulator.fixNotes.isEmpty {
            simulator["notes"] = .array(plan.simulator.fixNotes.map(JSONValue.string))
            simulator["notesAre"] = .string(AutopilotSimulatorSetup.notesNote)
        }
        if plan.simulator.lightAppearance { simulator["alerts"] = .string(AutopilotSimulatorSetup.alertsNote) }
        // With nothing to run there's nothing to run on each simulator.
        if !commands.isEmpty, plan.displayTypes.count(where: { $0 != .mac }) > 1 {
            simulator["eachSimulator"] = .string(AutopilotSimulatorSetup.eachSimulatorNote)
        }
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
        return .object(simulator)
    }

    /// How to choose the screens and write their captions, while the
    /// assistant still chooses them.
    private var mcpChoosingScreens: JSONValue? {
        guard plan.makesScreenshots, plan.choosesScreens || plan.awaitsScreens, captures.isEmpty else { return nil }
        return .string(Self.choosingScreensHow)
    }

    /// How to choose the screens and write their captions, when the
    /// assistant chooses them: the set is a story, and each caption sells
    /// what the screen does for the person.
    static let choosingScreensHow = """
    Choose the screens as a story told in order: the first says what the app is for and shows its core moment \
    filled with life (App Store search results show only the first three, so they carry the promise, the main \
    feature and what sets the app apart), then one feature a screen, each different, ending with what keeps \
    people coming back (or the paid tier). Prefer screens full of believable content over settings, empty \
    states, sign-in or permission screens. Each caption is a short headline in the app's own voice: what the \
    person gets or feels, not the screen's name ("See who's around you", not "Nearby tab"), 2 to 6 words, at \
    most about 30 characters in the primary language, one idea, no ending period, nothing the App Store texts \
    and the project don't support (no prices, ratings, awards or "best"). The captions are translated later for \
    every language, so avoid puns and idioms that only work in the primary language.
    """

    /// Without screenshots, what the run makes and captures instead; nil
    /// when it makes them.
    private var mcpNoScreenshots: JSONValue? {
        guard !plan.makesScreenshots else { return nil }
        return .string("""
        This run makes no screenshots, only \(plan.extrasTitle ?? "its extras"): capture only the targets next_step \
        gives (the screens the header and search artwork show) and record the App Preview; the set stays as it is.
        """)
    }

    /// An iPhone and iPad screen in `get_capture_plan`: who added it, and
    /// `"steps": "auto"` when the assistant works out the steps.
    private func mcpScreen(_ screen: AutopilotScreen, slot: Int) -> JSONValue {
        var item: [String: JSONValue] = [
            "id": .string(screen.id), "slot": .int(slot), "name": .string(screen.name),
            "steps": .string(screen.steps), "caption": .string(screen.caption),
        ]
        // Added by the person, by hand or from a suggestion: kept when the
        // assistant replaces the screens.
        switch screen.origin {
        case .person: item["addedBy"] = "person"
        case .suggestion: item["addedBy"] = "suggestion"
        case nil: break
        }
        // Added with "Let Claude Code work out the steps".
        if screen.worksOutSteps == true, screen.steps.isEmpty {
            item["steps"] = "auto"
            item["how"] = .string("""
            The person added this screen by name: work out how to reach it from the app's code, add it to the UI tests \
            (\(plan.writtenFrom ?? "the screenshot tests")) as a test that captures it, then send the steps with \
            update_capture_plan and capture it like the others.
            """)
        }
        return .object(item)
    }

    /// "1320 × 2868"; iPhone Duo its inner display's, either way up (open,
    /// it's wider than tall), for its open screens and its cover display's
    /// for its closed ones; Apple Watch takes an Ultra's screen; Apple
    /// Vision Pro the app's window as it is; Mac this Mac's whole screen.
    static func capturePixelSize(_ display: ScreenshotDisplayType) -> String {
        switch display {
        case .iPad:
            String(localized: "\(display.portraitPixelSize.rotated.title) (landscape) or \(display.portraitPixelSize.title) (portrait)")
        case .iPhoneDuo:
            String(localized: """
            open: \(display.portraitPixelSize.rotated.title) or \(display.portraitPixelSize.title) (the inner display); \
            closed: \(CaptureSizeRules.duoOuterSize.title) (the cover display)
            """)
        case .watch: "422 × 514 (or 410 × 502)"
        case .visionPro: String(localized: "the app’s window, at least 600 px on its short side")
        case .mac: String(localized: "this Mac’s whole screen, menu bar included: about 16:10, e.g. 2880 × 1800 or a MacBook’s 3024 × 1964")
        default: display.portraitPixelSize.title
        }
    }

    /// iPad prefers landscape but takes portrait (see `howToCapture`).
    static func orientation(_ display: ScreenshotDisplayType) -> String {
        switch display {
        case .iPad: "landscape, or portrait when the UI tests can't rotate"
        case .visionPro, .mac: "landscape"
        default: "portrait"
        }
    }

    /// How a device is captured, when it needs more than the steps.
    static func howToCapture(_ display: ScreenshotDisplayType) -> String? {
        switch display {
        case .watch:
            """
            Pair the watch simulator with the iPhone one (xcrun simctl pair), launch the watch app in each locale and capture each of the \
            watch screens below. No captions: the capture is the screenshot.
            """
        case .iPhoneDuo:
            """
            Use the iPhone Duo simulator (Xcode 27.1 or later). Its set has open and closed screenshots (poses; each iPhone \
            Duo target says which), and next_step gives the closed ones first. Closed: the Duo starts closed, with the app on \
            its 1398 × 2034 cover display, and a UI test's own screenshot (XCUIScreen.main) is that display, so capture the \
            closed ones like iPhone's, from the UI tests' attachments or xcrun simctl io <udid> screenshot of the cover display. \
            Open: once only open ones are left, AppLocalizer opens it itself (it presses Open in the Duo's window in Device \
            Hub), and it closes it again (by restarting it) if a closed one comes back. Don't open Device Hub, press anything \
            there, or shut down, reboot or erase the Duo yourself. Never change its displays with xcrun simctl io … \
            screenConfig, which crashes its SpringBoard on every start. Open, a UI test's screenshot is still the cover \
            display, and the test closes the app right after it, too soon for simctl, so for each UI test run for open \
            screens: call start_display_recording (it records the inner display), run the test on the simulator it names \
            with -resultBundlePath, then call finish_display_recording with that path. It gives each screenshot the test \
            attached as the inner display at that moment (2853 × 2007), with an upload ID for report_capture; the project \
            needs no change. An open screen you reach without a UI test (launch arguments), capture with xcrun simctl io \
            <udid> screenshot --display=<the 2007 × 2853 display's ID from xcrun simctl io <udid> enumerate>. If \
            start_display_recording says the Duo isn't open, or its inner display shows only a spinner, or SpringBoard \
            crashed and xcrun simctl launch hangs (stuck), report one problem with affectsDevice: true saying which, with \
            "AppLocalizer opens iPhone Duo" as proposedFix, and go on with the other devices: next_step gives you its screens \
            again once it's ready.
            """
        case .iPad:
            // MB Admin's UI tests never rotate, and the launched Claude
            // Code can't change them: every iPad capture came out portrait
            // and the run stopped for the person to edit their project.
            """
            Landscape shows the app best: rotate with XCUIDevice.shared.orientation = .landscapeLeft before launching when the \
            UI tests already do, or when you can add it. When they can't rotate without changing the project, capture in \
            portrait: AppLocalizer takes iPad either way up and lays the set out to match the captures, so a portrait \
            capture is not a problem; don't report it. iPad shows a split view's sidebar and detail side by side: \
            select an item before capturing, so the detail shows it and not a "select an item" placeholder.
            """
        case .mac:
            """
            Run the app on this Mac itself, not a simulator: UI tests with -destination 'platform=macOS' (add \
            variant=Mac Catalyst for a Mac Catalyst target, or variant=Designed for iPad for an iPad app made for Mac). \
            Bring its window to the front at a size that shows the screen well on a 16:10 desktop, with other windows \
            out of the way, and capture the whole screen, menu bar included: XCUIScreen.main.screenshot() in a macOS UI \
            test, or screencapture -x <file>.png. Don't crop it to the window: AppLocalizer puts the whole screen on a \
            MacBook in the template's layout. The simulatorSetup commands are for the simulators: on this Mac, don't \
            change the person's appearance, display settings, wallpaper or Dock. The language comes from the locale's \
            testArguments (or launchArguments), as on iPhone.
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
