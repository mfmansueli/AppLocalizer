//
//  AutopilotScreenSuggestionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's "+ Add a Screen…" and Suggest Screens: the form's screen,
/// the assistant asked through `next_step`, and the suggestions the person
/// adds or dismisses. Nothing is added on its own.
@MainActor
@Suite("Autopilot screen suggestions")
struct AutopilotScreenSuggestionsTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = StudioDebugRuns.appID
    private let client = AutopilotTestFixtures.client

    private var run: AutopilotRun? { center.run(for: appID) }

    private func askAndReceive(ask: String? = nil) throws {
        center.install(StudioDebugRuns.run(.plan))
        center.requestScreenSuggestions(appID: appID, ask: ask)
        try center.receiveScreenSuggestions(StudioDebugAddScreens.suggestions, client: client, appID: appID)
    }

    // MARK: - Add a Screen

    @Test func theFormNeedsANameAndStepsUnlessTheAssistantWorksThemOut() {
        var draft = AutopilotScreenDraft()
        #expect(!draft.canAdd)
        draft.name = "  Insights "
        #expect(draft.canAdd, "Claude Code works out the steps")
        draft.worksOutSteps = false
        #expect(!draft.canAdd)
        draft.steps = "tab “Insights”"
        #expect(draft.canAdd)

        let screen = draft.screen(id: "insights")
        #expect(screen == AutopilotScreen(id: "insights", name: "Insights", steps: "tab “Insights”", origin: .person))
        draft.worksOutSteps = true
        #expect(draft.screen(id: "insights").steps.isEmpty, "Steps typed before ticking the box are left out")
        #expect(draft.screen(id: "insights").worksOutSteps == true)
    }

    @Test func aNewScreensIDIsntTakenAndADevicesOwnScreensArePrefixed() {
        let plan = StudioDebugRuns.plan
        #expect(plan.newScreenID(named: "Insights", on: .iPhone) == "insights")
        #expect(plan.newScreenID(named: "Today", on: .iPhone) == "today-2")
        #expect(plan.newScreenID(named: "Today", on: .watch) == "watch-today")
    }

    @Test func theOriginPersistsAndTagsTheRow() throws {
        let screen = AutopilotScreen(name: "Streak widget", origin: .suggestion(client: client))
        let decoded = try JSONDecoder().decode(AutopilotScreen.self, from: JSONEncoder().encode(screen))
        #expect(decoded.origin == .suggestion(client: client))
        #expect(decoded.origin?.tag == "Suggested by Claude Code")
        #expect(AutopilotScreenOrigin.person.tag == "Added by you")
        #expect(AutopilotScreen(name: "Today").origin == nil)
    }

    // MARK: - Suggest Screens

    @Test func askingWaitsForTheAssistantThroughNextStep() async {
        center.install(StudioDebugRuns.run(.plan))
        #expect(await center.nextStep(appID: appID, client: client) == .noRun)
        #expect(run?.assistantHasWork == false)

        center.requestScreenSuggestions(appID: appID, ask: "  one that shows the streak ")
        let request = AutopilotScreenRequest(ask: "one that shows the streak", askedAt: AutopilotTestFixtures.now)
        #expect(run?.screenRequest == request)
        #expect(run?.assistantHasWork == true)
        #expect(await center.nextStep(appID: appID, client: client) == .suggestScreens(request))

        center.cancelScreenSuggestions(appID: appID)
        #expect(run?.screenRequest == nil)
        #expect(await center.nextStep(appID: appID, client: client) == .noRun)
    }

    @Test func anEmptyAskIsNoAsk() {
        center.install(StudioDebugRuns.run(.plan))
        center.requestScreenSuggestions(appID: appID, ask: "   ")
        #expect(run?.screenRequest?.ask == nil)
    }

    @Test func theSuggestionsAreShownNotAdded() async throws {
        try askAndReceive(ask: "one that shows the streak")
        let run = try #require(run)
        #expect(run.screenRequest == nil)
        #expect(run.screenSuggestions?.ask == "one that shows the streak")
        #expect(run.screenSuggestions?.client == client)
        #expect(run.screenSuggestions?.items.count == 3)
        #expect(run.plan.screens.count == 5, "Nothing is added on its own")
        #expect(await center.nextStep(appID: appID, client: client) == .done)
    }

    @Test func suggestionsNobodyAskedForAreRefused() {
        center.install(StudioDebugRuns.run(.plan))
        #expect(throws: AutopilotError.self) {
            try center.receiveScreenSuggestions(StudioDebugAddScreens.suggestions, client: client, appID: appID)
        }
        center.requestScreenSuggestions(appID: appID, ask: nil)
        #expect(throws: AutopilotError.self) { try center.receiveScreenSuggestions([], client: client, appID: appID) }
    }

    @Test func addToPlanPutsItAfterTheScreensMarkedAsSuggested() throws {
        try askAndReceive()
        center.addSuggestedScreen("sg-insights", appID: appID)
        let run = try #require(run)
        let added = try #require(run.plan.screens.last)
        #expect(run.plan.screens.count == 6)
        #expect(added == AutopilotScreen(
            id: "insights", name: "Insights", steps: "tab “Insights” → wait for the mood chart", caption: "See what lifts your mood",
            origin: .suggestion(client: client)
        ))
        #expect(run.screenSuggestions?.items.first?.status == .added)
        #expect(run.plan.targets.count(where: { $0.screenID == "insights" }) == 3 * 12, "iPhone, iPhone Duo and iPad in every language")

        // Added once.
        center.addSuggestedScreen("sg-insights", appID: appID)
        #expect(self.run?.plan.screens.count == 6)
    }

    @Test func dismissAndDone() throws {
        try askAndReceive()
        center.dismissScreenSuggestion("sg-dark", appID: appID)
        #expect(run?.screenSuggestions?.items.last?.status == .dismissed)
        center.addSuggestedScreen("sg-dark", appID: appID)
        #expect(run?.plan.screens.count == 5, "A dismissed suggestion isn't added")

        center.addSuggestedScreen("sg-widget", appID: appID)
        center.closeScreenSuggestions(appID: appID)
        #expect(run?.screenSuggestions == nil)
        #expect(run?.plan.screens.last?.name == "Streak widget", "The added screens stay")
    }

    @Test func tenScreensIsApplesLimit() throws {
        var full = StudioDebugRuns.run(.plan)
        for index in 6...10 { full.plan.appendScreen(AutopilotScreen(name: "Screen \(index)", steps: "launch"), on: .iPhone) }
        center.install(full)
        center.requestScreenSuggestions(appID: appID, ask: nil)
        #expect(run?.screenRequest == nil, "No room to suggest into")

        var nine = full
        nine.plan.screens.removeLast()
        center.install(nine)
        center.requestScreenSuggestions(appID: appID, ask: nil)
        try center.receiveScreenSuggestions(StudioDebugAddScreens.suggestions, client: client, appID: appID)
        center.addSuggestedScreen("sg-insights", appID: appID)
        center.addSuggestedScreen("sg-widget", appID: appID)
        #expect(run?.plan.screens.count == 10)
        #expect(run?.screenSuggestions?.items[1].status == .open)
    }

    @Test func thePromptAsksForWhatThePersonTyped() {
        let prompt = AutopilotPrompt.suggestScreens(appName: "Lumen Journal", appID: appID, ask: "one that shows the streak")
        #expect(prompt.contains("The person asks for: “one that shows the streak”."))
        #expect(prompt.contains("Call next_step for app \(appID)"))
        #expect(!AutopilotPrompt.suggestScreens(appName: "Lumen Journal", appID: appID, ask: " ").contains("asks for"))
    }
}
#endif
