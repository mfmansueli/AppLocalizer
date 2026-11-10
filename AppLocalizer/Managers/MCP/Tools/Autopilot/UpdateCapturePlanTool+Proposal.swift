//
//  UpdateCapturePlanTool+Proposal.swift
//  AppLocalizer
//

import Foundation

/// `update_capture_plan` outside a run's capture (Alba's 1.1 steps, sent
/// at Review & Push): one proposal for the app's next plan with the new
/// steps of screens it has, the sample-data switch, the file the steps come
/// from, and the commands and notes fixes added. The person accepts or
/// rejects it when the plan opens.
extension UpdateCapturePlanTool {
    /// What a queued proposal's result tells the assistant.
    static let queuedSay = """
    AppLocalizer keeps it for the app's next plan: the person accepts or rejects it when the plan opens, and it applies \
    from that run on. Nothing else to do now.
    """

    static var nothingSent: String {
        String(localized: "Send screens, writtenFrom, sampleData, setupCommands or setupNotes.")
    }

    /// One screen sent outside a capture.
    private enum ScreenOutcome {
        case change(AutopilotScreenStepsChange)
        /// Its steps are the plan's already.
        case unchanged(String)
        case refused(JSONValue)
    }

    /// Outside a capture: one proposal with everything sent that changes
    /// the plan; a screen the plan doesn't have is refused.
    func propose(_ arguments: MCPToolArguments, app: StoreApp, center: AutopilotCenter, client: String) throws -> MCPToolOutcome {
        let target = MCPAutopilotSession.target(app)
        if try arguments.optionalBool("replace") == true {
            let reason = String(localized: """
            replace works only before a run’s first capture, when get_capture_plan says chooseScreens. Outside a capture, \
            send the new steps of the plan’s screens without it.
            """)
            return .refused(reason, target: target)
        }
        let setup = try Self.setupLists(arguments)
        if let refusal = Self.setupRefusal(commands: setup.commands) { return .refused(refusal, target: target) }
        let plan = center.run(for: app.id)?.plan
        var change = try Self.newChange(arguments, center: center, client: client)
        if let sample = try arguments.optionalString("sampleData"), sample != plan?.simulator.sampleDataSteps { change.sampleData = sample }
        if let file = try arguments.optionalString("writtenFrom"), file != plan?.writtenFrom { change.writtenFrom = file }
        Self.addSetup(setup, to: &change, plan: plan)
        let items = try arguments.optionalArray("screens") ?? []
        var refused: [JSONValue] = []
        var unchanged: [String] = []
        for item in items {
            switch Self.stepsChange(item, in: plan, appName: app.name) {
            case let .change(screen): change.screens.append(screen)
            case let .unchanged(name): unchanged.append(name)
            case let .refused(refusal): refused.append(refusal)
            }
        }
        guard !change.isEmpty else {
            let sentFields = try ["sampleData", "writtenFrom"].contains { try arguments.optionalString($0) != nil }
            let sentAnything = !items.isEmpty || sentFields || setup.commands != nil || setup.notes != nil
            let reason = sentAnything
                ? String(localized: "Nothing changes: the plan already has what you sent, or the screens aren’t in it.")
                : Self.nothingSent
            return .refused(reason, target: target, details: Self.details(refused: refused, unchanged: unchanged))
        }
        center.queuePlanChange(change, appID: app.id)
        return Self.outcome(for: change, refused: refused, unchanged: unchanged, target: target)
    }

    /// The result of a queued proposal: what waits, and what was refused
    /// or already in the plan.
    static func outcome(for change: AutopilotPlanChange, refused: [JSONValue], unchanged: [String], target: String) -> MCPToolOutcome {
        var result = details(refused: refused, unchanged: unchanged)
        result["status"] = refused.isEmpty ? "queued" : "partial"
        result["proposalId"] = .string(change.id)
        result["waiting"] = change.mcpSummary
        result["say"] = .string(queuedSay)
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    // MARK: - Commands and notes

    /// setupCommands and setupNotes as sent, trimmed, without empty or
    /// repeated lines; nil when not sent.
    static func setupLists(_ arguments: MCPToolArguments) throws -> (commands: [String]?, notes: [String]?) {
        try (arguments.optionalStrings("setupCommands").map(cleaned), arguments.optionalStrings("setupNotes").map(cleaned))
    }

    /// Why setupCommands can't be taken: one of them isn't a command the
    /// setup runs as it is.
    static func setupRefusal(commands: [String]?) -> String? {
        guard let line = commands?.first(where: { !AutopilotSimulatorSetup.isSetupCommand($0) }) else { return nil }
        return String(localized: """
        Each of setupCommands is run as it is, so it’s one line starting with xcrun or xcodebuild, and “\(line)” isn’t. \
        A switch like TEST_RUNNER_X=1 belongs in the scheme’s Test action or test plan, and an instruction goes in setupNotes.
        """)
    }

    /// While a run captures, the commands and notes still wait for the
    /// person: a proposal of their own, when they change anything.
    static func proposeSetup(
        _ setup: (commands: [String]?, notes: [String]?), arguments: MCPToolArguments, plan: AutopilotPlan,
        center: AutopilotCenter, client: String, appID: StoreApp.ID
    ) throws -> AutopilotPlanChange? {
        var change = try newChange(arguments, center: center, client: client)
        addSetup(setup, to: &change, plan: plan)
        return change.isEmpty ? nil : center.queuePlanChange(change, appID: appID)
    }

    private static func addSetup(_ setup: (commands: [String]?, notes: [String]?), to change: inout AutopilotPlanChange, plan: AutopilotPlan?) {
        if let commands = setup.commands, commands != plan?.simulator.extraCommands { change.setupCommands = commands }
        if let notes = setup.notes, notes != plan?.simulator.fixNotes { change.setupNotes = notes }
    }

    private static func cleaned(_ lines: [String]) -> [String] {
        var seen: Set<String> = []
        return lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    // MARK: - Pieces

    /// An empty proposal from `client`, with the reason and evidence sent.
    private static func newChange(_ arguments: MCPToolArguments, center: AutopilotCenter, client: String) throws -> AutopilotPlanChange {
        try AutopilotPlanChange(
            id: "pc-" + center.makeID().prefix(8), client: client, receivedAt: center.now(),
            reason: arguments.optionalString("reason"), evidence: arguments.optionalString("evidence")
        )
    }

    /// New steps for one of the plan's screens, matched by id or name on
    /// its device.
    private static func stepsChange(_ item: JSONValue, in plan: AutopilotPlan?, appName: String) -> ScreenOutcome {
        let name = item["name"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let steps = item["steps"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let id = item["id"]?.stringValue
        let display = display(of: item)
        let label = name.isEmpty ? id ?? "" : name
        guard let plan else {
            let reason = String(localized: "\(appName) has no plan yet: suggest its screens with propose_screens.")
            return .refused(["name": .string(label), "reason": .string(reason)])
        }
        let screens = plan.screens(on: display)
        let named = screens.first { !name.isEmpty && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
        guard let screen = screens.first(where: { $0.id == id }) ?? named else {
            let reason = String(localized: "The plan has no screen “\(label)”: suggest new screens with propose_screens.")
            return .refused(["name": .string(label), "reason": .string(reason)])
        }
        guard !steps.isEmpty else {
            return .refused(["name": .string(screen.name), "reason": .string(String(localized: "Send the steps to reach it."))])
        }
        guard steps != screen.steps else { return .unchanged(screen.name) }
        return .change(AutopilotScreenStepsChange(
            screenID: screen.id, name: screen.name, displayType: display.hasOwnScreens ? display : nil, steps: steps
        ))
    }

    private static func details(refused: [JSONValue], unchanged: [String]) -> [String: JSONValue] {
        var details: [String: JSONValue] = [:]
        if !refused.isEmpty { details["refused"] = .array(refused) }
        if !unchanged.isEmpty { details["unchanged"] = .array(unchanged.map(JSONValue.string)) }
        return details
    }
}
