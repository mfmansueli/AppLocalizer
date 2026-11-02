//
//  StudioDebugRuns.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal's Autopilot run at each of the design's stages, for the
/// Studio scenes: five screens on iPhone and iPad in the sample's
/// languages (or every device and the project's new languages too),
/// captured by Claude Code, designed by Claude Design in Northpier Brand
/// (or AppLocalizer's starters).
@MainActor
enum StudioDebugRuns {
    static let appID = DebugFixtures.AppID.lumen
    static let client = "Claude Code"

    static let steps = [
        "launch -ui-sample-week → Today → wait for the prompt card",
        "tab “Week” → scroll to top",
        "tab “Search” → type “lake” → dismiss keyboard",
        "open “Sunday at the lake” → wait for photos",
        "Settings → Lock with Face ID → background → foreground",
    ]

    static var northpier: DesignProject {
        DesignProject(
            kind: .claudeDesign, link: "Northpier Brand · Claude Design", createsInClaudeDesign: true,
            summary: DesignSourceSummary(
                title: "Northpier Brand · design system",
                colors: [
                    DesignSwatch(name: "Indigo", hex: "#5B5BD6"), DesignSwatch(name: "Dusk", hex: "#2E2A6B"),
                    DesignSwatch(name: "Dawn", hex: "#FFD9C7"), DesignSwatch(name: "Mist", hex: "#F2F1FA"),
                    DesignSwatch(name: "Ink", hex: "#1C1A33"),
                ],
                typefaces: "New York Bold for headlines · SF Pro Text for the rest",
                logo: "Moon mark, light and dark",
                voice: "Calm, short sentences, no exclamation marks",
                updated: date(day: 21, month: 10),
                readBy: client
            )
        )
    }

    /// A Claude Design link nobody has read yet.
    static var unreadLink: DesignProject {
        DesignProject(kind: .claudeDesign, link: "https://claude.ai/artifact/KxcpHYisJkSjAC2sXf7QHN?org=495d75b4-465a-42bc-b378-4fb6c09e5b2d")
    }

    /// The plan with `unreadLink` connected, saved before links were
    /// shortened (its design name is the whole link), picked up before by
    /// an assistant with a long name, and a screen whose name doesn't fit
    /// its column.
    static var linkedPlan: AutopilotRun {
        var run = run(.plan)
        run.designName = unreadLink.link
        run.client = "claude-code-motivator"
        run.plan.updateScreen(id: run.plan.screens[1].id) { $0.name = "Customize the background of every phrase" }
        return run
    }

    static var plan: AutopilotPlan {
        let document = ScreenshotsDebugDocuments.document(for: .standard)
        let locales = document.scope.orderedLocales(in: StoreLocaleCatalog.all.map(\.code))
        let screens = ScreenshotsSampleData.slotNames.enumerated().map { slot, name in
            AutopilotScreen(
                id: AutopilotScreen.identifier(for: name), name: name, steps: steps[slot],
                caption: ScreenshotsSampleData.caption(locale: "en-US", slot: slot) { _, _ in .written }?.headline ?? ""
            )
        }
        var plan = AutopilotPlan(screens: screens, displayTypes: [.iPhone, .iPad], localeCodes: locales, primaryLocale: "en-US")
        plan.writtenFrom = "LumenUITests/ScreenshotTests.swift"
        plan.simulator.sampleDataSteps = "Settings → Debug → Add Sample Week"
        return plan
    }

    /// The plan on iPhone, iPad, Apple Watch and Apple Vision Pro, with the
    /// three languages the project has that the App Store page doesn't.
    static var everyDevicePlan: AutopilotPlan {
        var plan = plan
        plan.setPlans(.watch, true)
        plan.setPlans(.visionPro, true)
        plan.setScreens(DebugEveryDevice.watchScreens.map { AutopilotScreen(id: "watch-\(AutopilotScreen.identifier(for: $0.name))", name: $0.name, steps: $0.steps) }, on: .watch)
        plan.setScreens(DebugEveryDevice.visionWindows.map { window in
            let source = plan.screens[window.slot]
            return AutopilotScreen(id: "vision-\(source.id)", name: source.name, steps: window.steps, caption: source.caption, sourceScreenID: source.id)
        }, on: .visionPro)
        plan.newLocaleCodes = DebugAppSupport.newLanguages.compactMap(\.storeLocale?.code)
        plan.setIncludesNewLanguages(true)
        return plan
    }

    // MARK: - Stages

    static func run(_ stage: AutopilotStage, design: Bool = true, everyDevice: Bool = false) -> AutopilotRun {
        var run = AutopilotRun(
            id: "run-debug", appID: appID, versionString: "1.4", stage: stage, plan: everyDevice ? everyDevicePlan : plan,
            designKind: design ? .claudeDesign : .none, designName: design ? "Northpier Brand" : nil,
            client: stage == .plan ? nil : client, uploadToken: "debug-token", createdAt: date(day: 31, month: 10, hour: 14)
        )
        // A new plan has iPhone Duo, as Autopilot plans it now; the runs
        // past it stay iPhone and iPad, like the sample data.
        if stage == .plan { run.plan.setPlans(.iPhoneDuo, true) }
        if stage != .plan { run.startedAt = date(day: 31, month: 10, hour: 14) }
        if stage.number > AutopilotStage.capture.number || stage == .capture {
            run.environment = everyDevice
                ? AutopilotEnvironment(xcode: "26.1", simulators: ["iPhone", "iPad", "Apple Watch", "Apple Vision Pro"])
                : AutopilotEnvironment(xcode: "26.1", simulators: ["iPhone 17 Pro Max", "iPad Pro 13″"])
        }
        switch stage {
        case .plan, .waiting:
            break
        case .capture:
            run.captures = captures(of: run.plan, count: 76)
            run.log = captureLog
        default:
            run.captures = captures(of: run.plan, count: run.plan.targets.count)
            run.pickBest()
            run.log = captureLog
        }
        if stage.number > AutopilotStage.design.number || stage == .design {
            run.directions = Array(directions(design: design, of: run).prefix(stage == .design ? 1 : AutopilotRun.directionCount))
        }
        if stage == .localize || stage == .ready {
            run.chosenDirectionID = run.directions.first?.id
            run.shortenings = [AutopilotShortening(
                locale: "de-DE", slot: 2, before: "Durchsuche jahrelange Tagebucheinträge in Sekunden",
                after: "Einträge aus Jahren in Sekunden finden", client: client
            )]
            run.localeStatus = localeStatus(of: run.plan, done: stage == .ready ? run.plan.localeCodes.count : 6)
        }
        if stage == .ready {
            run.templateVersion = (ScreenshotsDebugDocuments.document(for: .standard).history?.currentNumber ?? 4)
            run.finishedAt = date(day: 31, month: 10, hour: 14, minute: 31)
        }
        return run
    }

    /// Capturing every device, the latest capture `target`'s.
    static func capturing(upTo target: AutopilotCaptureTarget) -> AutopilotRun {
        var run = run(.capture, everyDevice: true)
        let count = (run.plan.targets.firstIndex(of: target) ?? 0) + 1
        run.captures = captures(of: run.plan, count: count)
        return run
    }

    /// Capturing with the German photo entry blocked.
    static var failing: AutopilotRun {
        var run = run(.capture)
        run.problems = [AutopilotProblem(
            id: "pr-photos", target: AutopilotCaptureTarget(screenID: "photos", displayType: .iPhone, locale: "de-DE"),
            what: "The photo picker asked for access and covered the entry.",
            proposedFix: "xcrun simctl privacy booted grant photos dev.northpier.lumen",
            reportedAt: date(day: 31, month: 10, hour: 14, minute: 6, second: 52)
        )]
        run.appendLog(
            "Photos (de-DE): photo picker permission sheet covered the screen", kind: .problem,
            at: date(day: 31, month: 10, hour: 14, minute: 6, second: 52)
        )
        return run
    }

    /// Capturing with the German Week screen stopped by a command the
    /// session wasn't allowed to run.
    static var refused: AutopilotRun {
        var run = run(.capture)
        let reported = date(day: 31, month: 10, hour: 14, minute: 8, second: 4)
        run.problems = [AutopilotProblem(
            id: "pr-refused", target: AutopilotCaptureTarget(screenID: "week", displayType: .iPhone, locale: "de-DE"),
            what: "The screenshot UI tests need an environment variable in front of xcodebuild, which this session may not run.",
            proposedFix: "Add a LumenScreenshots scheme whose Test action sets LUMEN_SCREENSHOTS=1, and take the language from -testLanguage.",
            refusedCommand: "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test -scheme Lumen -only-testing:LumenUITests/ScreenshotTests",
            reportedAt: reported
        )]
        run.appendLog("Week (de-DE): xcodebuild with an environment variable in front was refused", kind: .problem, at: reported)
        return run
    }

    /// Capturing, with the Week screen's UI test failing the same way in the
    /// rehearsal's language and in German, on iPhone and iPad: it finds a
    /// segment by its English title. One card for the three.
    static var grouped: AutopilotRun {
        var run = run(.capture)
        let reported = date(day: 31, month: 10, hour: 14, minute: 9, second: 30)
        let rehearsal = run.plan.rehearsalLocale ?? "ja"
        let places: [(ScreenshotDisplayType, String)] = [(.iPhone, rehearsal), (.iPad, rehearsal), (.iPhone, "de-DE")]
        let targets = places.map { AutopilotCaptureTarget(screenID: "week", displayType: $0.0, locale: $0.1) }
        run.captures.removeAll { $0.target.screenID == "week" && $0.target.locale != run.plan.primaryLocale }
        run.problems = targets.enumerated().map { index, target in
            AutopilotProblem(
                id: "pr-group-\(index + 1)", target: target,
                what: "testWeek taps app.buttons[\"Week\"], the segment’s English title, so it doesn’t find it in this language.",
                proposedFix: """
                In LumenUITests/ScreenshotTests.swift:64, tap app.buttons["journal.week"], and give the Week segment \
                that accessibilityIdentifier.
                """,
                changesProject: true, reportedAt: reported.addingTimeInterval(Double(index))
            )
        }
        run.appendLog("Week (\(rehearsal)): testWeek didn’t find the Week segment", kind: .problem, at: reported)
        return run
    }

    /// Capturing with iPhone Duo planned on a Mac without its simulator:
    /// one problem for the whole device, which offers to install it.
    static var noDuoSimulator: AutopilotRun {
        var run = run(.capture)
        run.plan.setPlans(.iPhoneDuo, true)
        // After the base run's last log line, so the log reads in order.
        let reported = date(day: 31, month: 10, hour: 14, minute: 6, second: 40)
        let target = AutopilotCaptureTarget(screenID: run.plan.screens[0].id, displayType: .iPhoneDuo, locale: run.plan.primaryLocale)
        run.problems = [AutopilotProblem(
            id: "pr-duo", target: target,
            what: "This Mac can’t run the iPhone Duo simulator. Needs the iOS 27.1 simulator or later. This Mac has iOS 26.5 and iOS 27.0.",
            proposedFix: "Install the iOS simulator (xcodebuild -downloadPlatform iOS).", affectsDevice: true, reportedAt: reported
        )]
        run.appendLog("iPhone Duo: no simulator for it on this Mac", kind: .problem, at: reported)
        return run
    }

    /// Capturing, with the last capture over an hour before the scenes'
    /// clock (14:32): nobody is working on it, so it says so with Continue.
    static var stalled: AutopilotRun {
        var run = run(.capture)
        let hour: TimeInterval = 3600
        for index in run.captures.indices { run.captures[index].receivedAt -= hour }
        for index in run.log.indices { run.log[index].date -= hour }
        run.startedAt = run.startedAt?.addingTimeInterval(-hour)
        return run
    }

    /// Choosing, after Ask for changes revised Quiet Indigo.
    static var revised: AutopilotRun {
        var run = run(.choose)
        run.directions[0].isRevised = true
        run.directions[0].rationale = "Bigger headline and a lighter indigo, as you asked."
        return run
    }

    // MARK: - Pieces

    private static func captures(of plan: AutopilotPlan, count: Int) -> [AutopilotCapture] {
        var captures: [AutopilotCapture] = []
        let notes = [
            ["Prompt card and three moods; no keyboard", "Keyboard covers the prompt", "No entries yet"],
            ["A full week, entries every day", "Only two days of data", "Notifications alert"],
            ["Results across three years; keyboard hidden", "Keyboard covers results", "No results yet"],
            ["Entry with two photos, fully loaded", "Photo access alert", "Photos still loading"],
            ["Locked; nothing private on screen", "Face ID prompt", "Passcode keyboard"],
        ]
        let watchNotes = [
            ["Six moods, Calm selected", "Mood list still loading", "Dictation sheet open"],
            ["Today’s prompt with Dictate", "Prompt cut off", "Always On dimmed"],
            ["A full week of moods", "Only two days of data", "Scrolled past the chart"],
            ["Streak of 3 on the Modular face", "Complication still loading", "Notification banner"],
        ]
        for (index, target) in plan.targets.prefix(count).enumerated() {
            let slot = plan.slot(of: target.screenID) ?? 0
            let isPicked = target.displayType == .iPhone || target.displayType == .watch
            let isPrimary = target.locale == plan.primaryLocale && isPicked
            for attempt in 1...(isPrimary ? 3 : 1) {
                let size = switch target.displayType {
                case .iPad: target.displayType.portraitPixelSize.rotated
                case .visionPro: DebugEveryDevice.visionCaptureSize
                default: target.displayType.portraitPixelSize
                }
                let note = target.displayType == .watch ? watchNotes[slot % watchNotes.count] : notes[slot % notes.count]
                captures.append(AutopilotCapture(
                    id: "cap-\(target.locale)-\(target.displayType.rawValue)-\(target.screenID)-\(attempt)",
                    target: target, attempt: attempt, score: [0.94, 0.61, 0.42][attempt - 1],
                    notes: note[attempt - 1],
                    captureID: "autopilot-\(target.locale)-\(target.displayType.rawValue)-\(slot)-\(attempt)",
                    pixelSize: size, receivedAt: date(day: 31, month: 10, hour: 14, minute: 3, second: index * 3 + attempt),
                    text: text(of: target, slot: slot, attempt: attempt)
                ))
            }
        }
        return captures
    }

    /// What reading the text found: the Japanese Week screen with English
    /// sample entries, a German search label cut off, and the
    /// notifications prompt on the Week screen's third attempt.
    private static func text(of target: AutopilotCaptureTarget, slot: Int, attempt: Int) -> CaptureTextFacts? {
        guard target.displayType == .iPhone else { return nil }
        switch (target.locale, slot, attempt) {
        case ("ja", 1, 1): return CaptureTextFacts(language: "en")
        case ("de-DE", 2, 1): return CaptureTextFacts(language: "de", truncatedLines: ["Einträge durchsu…"])
        case ("en-US", 1, 3): return CaptureTextFacts(language: "en", promptLine: "“Lumen” Would Like to Send You Notifications")
        default: return nil
        }
    }

    private static var captureLog: [AutopilotLogEntry] {
        [
            ("xcodebuild -scheme Lumen -destination “iPhone 17 Pro Max” build · 1 m 12 s", AutopilotLogEntry.Kind.command, 2, 11),
            ("simctl status_bar override --time 9:41 --batteryLevel 100 --cellularBars 4", .command, 3, 24),
            ("launch dev.northpier.lumen -AppleLanguages (nl) -ui-sample-week", .command, 3, 26),
            ("navigate: scroll to top", .command, 6, 36),
            ("screenshot → nl-NL/iPad-01.png · Today · attempt 1", .event, 6, 39),
        ].map { text, kind, minute, second in
            AutopilotLogEntry(date: date(day: 31, month: 10, hour: 14, minute: minute, second: second), text: text, kind: kind)
        }
    }

    static func directions(design: Bool, of run: AutopilotRun) -> [AutopilotDirection] {
        let names = design
            ? [
                ("Quiet Indigo", "Your indigo, with a New York headline over the device. Closest to Lumen’s app icon.", TemplateStarter.above),
                ("Full Bleed", "The capture fills the frame and a dusk band carries the caption. Shows the most of the app.", .band),
                ("Dawn Panorama", "One dawn gradient runs across all five, so the set reads as one scene when people swipe.", .panorama),
            ]
            : TemplateStarter.simple.map { ($0.title, "AppLocalizer’s starter, in the colors of Lumen’s app icon.", $0) }
        let palette = IconPalette(light: "#7C86FF", dark: "#3A2FB8")
        let document = ScreenshotsDebugDocuments.document(for: .standard)
        let fonts = DebugScreenshotsServices().fonts
        return names.enumerated().map { index, item in
            var template = ScreenshotTemplate.starter(item.2, id: appID, title: "Lumen Journal", slotCount: run.plan.screens.count)
            StarterDirectionMaker.color(&template, as: item.2, with: palette)
            let checker = AutopilotCaptionChecker(
                template: template, captions: document.captions, displayTypes: run.plan.displayTypes,
                slotCount: run.plan.screens.count, primaryLocale: run.plan.primaryLocale, catalog: fonts
            )
            return AutopilotDirection(
                id: design ? "d-\(index + 1)" : "starter-\(item.2.rawValue)", name: item.0, rationale: item.1,
                source: design ? .claudeDesign : .none, client: design ? client : nil, template: template,
                link: design ? "https://claude.ai/design/northpier-brand/lumen-\(index + 1)" : nil,
                checks: checker.directionChecks(locales: run.plan.localeCodes),
                receivedAt: date(day: 31, month: 10, hour: 14, minute: 20 + index)
            )
        }
    }

    private static func localeStatus(of plan: AutopilotPlan, done: Int) -> [String: AutopilotLocaleStatus] {
        var status: [String: AutopilotLocaleStatus] = [:]
        for (index, code) in plan.localeCodes.enumerated() {
            if index < done {
                let isRTL = StoreLocaleCatalog.locale(code: code)?.isRTL == true
                let note: String? = code == "ja" ? "Hiragino Sans for Japanese" : isRTL ? "mirrored for right-to-left" : nil
                status[code] = .fits(note: note)
            } else {
                status[code] = index == done ? .checking : .waiting
            }
        }
        return status
    }

    static func date(day: Int, month: Int, hour: Int = 9, minute: Int = 0, second: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute, second: second)) ?? .now
    }
}
#endif
