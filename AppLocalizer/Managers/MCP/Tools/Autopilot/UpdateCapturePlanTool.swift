//
//  UpdateCapturePlanTool.swift
//  AppLocalizer
//

import Foundation

/// `update_capture_plan`: the screens the assistant found in the code, with
/// the steps to reach each, before it captures. Existing screens keep
/// their IDs; new ones join while nothing has been captured yet. With
/// `replace`, the screens it chose take the place of the plan's.
struct UpdateCapturePlanTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "update_capture_plan",
        title: "Write the capture plan's steps",
        description: """
        Writes the screens of the Autopilot run's plan from the project: for each, its name, the steps to reach \
        it (e.g. tab "Week" → scroll to top) and, if the plan has none, the caption it goes with. Screens without \
        a device are iPhone's, iPad's and Mac's; device "watch" lists the watch app's own screens (no captions), and \
        device "vision" the Apple Vision Pro windows, each with sameMomentAs: the iPhone screen id whose moment \
        and caption it shows. Match existing screens by id or name; new screens can be added only before the \
        first capture. When the plan says chooseScreens, decide which screens show the app best and send them \
        with replace: true: on each device you send screens for, they become the plan's screens in that order \
        (strongest first, each with a caption as get_capture_plan's choosingScreens says: App Store search results \
        show the first three), and the others there are dropped, \
        except the screens the person added (addedBy in get_capture_plan): they stay, after yours, unless you send them. \
        iPhone Duo uses the same screens as iPhone (get_capture_plan's poses say which it shows open or closed). Also takes the file the steps \
        came from (writtenFrom, e.g. LumenUITests/ScreenshotTests.swift) and the app's sample-data switch.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "screens": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "id": ["type": "string"], "name": ["type": "string"], "steps": ["type": "string"], "caption": ["type": "string"],
                            "device": ["type": "string", "description": "watch or vision for those devices' own screens; omit for iPhone, iPad and Mac."],
                            "sameMomentAs": ["type": "string", "description": "On vision: the iPhone screen's id."],
                        ],
                        "required": ["name", "steps"],
                    ],
                ],
                "replace": [
                    "type": "boolean",
                    "description": """
                    true: the screens sent replace the plan's on each device they're for. Only before the first \
                    capture, when chooseScreens is true.
                    """,
                ],
                "writtenFrom": MCPToolDefinition.string("The file or files the steps come from."),
                "sampleData": MCPToolDefinition.string("How the app loads sample data, e.g. launch argument -ui-sample-week."),
            ],
            required: ["appId", "run", "screens"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        guard [.waiting, .capture].contains(session.run.stage) else {
            return .refused(String(localized: "The plan can’t change now: the run is at \(session.run.stage.title)."), target: session.target)
        }
        let canAdd = session.run.captures.isEmpty
        let items = try arguments.array("screens")
        let replaces = try arguments.optionalBool("replace") ?? false
        if replaces, let refusal = Self.replaceRefusal(canAdd: canAdd, plan: session.run.plan) {
            return .refused(refusal, target: session.target)
        }
        var plan = session.run.plan
        let sent = Set(items.map(Self.display(of:)))
        let refused = Self.write(items, to: &plan, replaces: replaces, canAdd: canAdd)
        // Apple Vision Pro's windows follow iPhone's screens when the
        // moments theirs showed are gone and none were sent.
        let phoneIDs = Set(plan.screens.map(\.id))
        let vision = plan.screens(on: .visionPro)
        let orphaned = vision.contains { $0.sourceScreenID.map { !phoneIDs.contains($0) } ?? false }
        if plan.displayTypes.contains(.visionPro), vision.isEmpty || (orphaned && !sent.contains(.visionPro)) {
            plan.setScreens(AutopilotPlanner.visionScreens(from: plan.screens), on: .visionPro)
        }
        if let file = try arguments.optionalString("writtenFrom") { plan.writtenFrom = file }
        if let sample = try arguments.optionalString("sampleData") { plan.simulator.sampleDataSteps = sample }
        let count = plan.screens.count + (plan.deviceScreens ?? []).reduce(0) { $0 + $1.screens.count }
        let log = replaces
            ? String(localized: "\(context.clientName) chose \(count) screens and wrote their steps")
            : String(localized: "\(context.clientName) wrote the steps for \(count) screens")
        session.center.update(session.app.id) { run in
            run.plan = plan
            run.appendLog(log, kind: .event, at: session.center.now())
        }
        session.refresh()
        var result = session.run.mcpPlan(appName: session.app.name, bundleID: session.app.bundleID, port: context.port).objectValue ?? [:]
        result["status"] = refused.isEmpty ? "updated" : "partial"
        if !refused.isEmpty { result["refused"] = .array(refused) }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: session.target, outcome: .proposed)])
    }

    /// Why the screens can't be replaced, if they can't.
    private static func replaceRefusal(canAdd: Bool, plan: AutopilotPlan) -> String? {
        if !canAdd { return String(localized: "Screens can only be replaced before the first capture.") }
        if !plan.choosesScreens, !plan.awaitsScreens {
            return String(localized: "The person keeps these screens: send their steps without replace.")
        }
        return nil
    }

    /// The device a screen is for: watch or vision, else iPhone (and iPad).
    private static func display(of item: JSONValue) -> ScreenshotDisplayType {
        let device = item["device"]?.stringValue.flatMap(ScreenshotDisplayType.init(mcpValue:))
        return device?.hasOwnScreens == true ? device ?? .iPhone : .iPhone
    }

    /// Writes one screen's steps (and caption, if it has none) into the
    /// plan, or adds it before the first capture; the refusal otherwise. A
    /// screen added back after `replace` keeps its ID and caption from
    /// `previous`.
    private static func apply(_ item: JSONValue, to plan: inout AutopilotPlan, canAdd: Bool, previous: AutopilotPlan) -> JSONValue? {
        let name = item["name"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let steps = item["steps"]?.stringValue ?? ""
        let id = item["id"]?.stringValue
        let display = display(of: item)
        if display.hasOwnScreens, !plan.displayTypes.contains(display) {
            return ["name": .string(name), "reason": .string(String(localized: "\(display.title) isn’t in this plan."))]
        }
        let phoneScreens = plan.screens
        let source = item["sameMomentAs"]?.stringValue.flatMap { source in phoneScreens.contains { $0.id == source } ? source : nil }
        let caption = display.hasCaptions ? item["caption"]?.stringValue : nil
        var screens = plan.screens(on: display)
        defer { plan.setScreens(screens, on: display) }
        if let index = screens.firstIndex(where: { $0.id == id || $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            screens[index].steps = steps
            if screens[index].caption.isEmpty, let caption { screens[index].caption = caption }
            if let source { screens[index].sourceScreenID = source }
            return nil
        }
        guard canAdd, !name.isEmpty, screens.count < ScreenshotTemplate.maximumSlots else {
            return ["name": .string(name), "reason": .string(refusal(name: name, canAdd: canAdd))]
        }
        let prefix = display.hasOwnScreens ? "\(display.mcpValue)-" : ""
        let sameName = phoneScreens.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }?.id
        let kept = previous.screens(on: display).first { $0.id == id || $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
        let newID = kept?.id ?? prefix + AutopilotScreen.identifier(for: name)
        guard !screens.contains(where: { $0.id == newID }) else {
            return ["name": .string(name), "reason": .string(String(localized: "Another screen already has the id \(newID)."))]
        }
        screens.append(AutopilotScreen(
            id: newID, name: name, steps: steps, caption: caption ?? (display.hasCaptions ? kept?.caption ?? "" : ""),
            sourceScreenID: display == .visionPro ? source ?? kept?.sourceScreenID ?? sameName : nil, origin: kept?.origin
        ))
        return nil
    }

    /// Writes the screens sent into `plan`; with `replace` they take the
    /// place of each sent device's screens, and the ones the person added
    /// stay after them. Returns the refusals.
    private static func write(_ items: [JSONValue], to plan: inout AutopilotPlan, replaces: Bool, canAdd: Bool) -> [JSONValue] {
        let previous = plan
        let sent = Set(items.map(display(of:)))
        if replaces {
            for display in sent where !display.hasOwnScreens || plan.displayTypes.contains(display) { plan.setScreens([], on: display) }
        }
        var refused: [JSONValue] = []
        for item in items {
            if let refusal = apply(item, to: &plan, canAdd: canAdd, previous: previous) { refused.append(refusal) }
        }
        if replaces, sent.contains(.iPhone) { keepAddedScreens(of: previous, in: &plan) }
        return refused
    }

    /// After `replace`: the screens the person added by hand or from a
    /// suggestion stay, after the chosen ones, unless they were sent.
    static func keepAddedScreens(of previous: AutopilotPlan, in plan: inout AutopilotPlan) {
        var screens = plan.screens
        for screen in previous.screens where screen.origin != nil && screens.count < ScreenshotTemplate.maximumSlots {
            let sent = screens.contains { $0.id == screen.id || $0.name.localizedCaseInsensitiveCompare(screen.name) == .orderedSame }
            if !sent { screens.append(screen) }
        }
        plan.screens = screens
    }

    /// Why a screen wasn't added.
    private static func refusal(name: String, canAdd: Bool) -> String {
        if !canAdd { return String(localized: "Screens can only be added before the first capture.") }
        if name.isEmpty { return String(localized: "A new screen needs a name.") }
        return String(localized: "A set has at most \(ScreenshotTemplate.maximumSlots) screenshots.")
    }
}
