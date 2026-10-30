//
//  SuggestionsDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Board 17 of the design: field suggestions and the assistant setup.
/// - `ov-first`, `ov-connected`: Overview before and after an assistant
///   connects; `asst-pop`: the Assistant button's popover.
/// - `setup-1` … `setup-4`, `setup-done`: the setup sheet's steps.
/// - `sp-builtin` … `sp-ja`: Store Page with built-in suggestions only,
///   Claude Code's too, Ask, suggestions arriving, accepted and dismissed,
///   Use and Edit, German, and Japanese with none.
/// - `in-general`, `in-review`: App Information's General and App Review.
enum SuggestionsDebugScenes {
    static let ids = [
        "ov-first", "ov-connected", "asst-pop",
        "setup-1", "setup-2", "setup-3", "setup-4", "setup-done",
        "sp-builtin", "sp-cc", "sp-ask", "sp-streaming", "sp-accepted", "sp-edit", "sp-de", "sp-ja",
        "in-general", "in-review",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        if id.hasPrefix("setup-") { return setupScene(id) }
        if id.hasPrefix("sp-") { return storePageScene(id) }
        switch id {
        case "ov-first":
            return AnyView(DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store(includesAssistant: false)))
        case "ov-connected":
            return with(.connected, DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store()))
        case "asst-pop":
            AssistantToolbarIndicator.debugShowsPopover = true
            return with(.connected, DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store()))
        case "in-general", "in-review":
            return appInformationScene(page: id == "in-general" ? .general : .appReview)
        default:
            return nil
        }
    }

    // MARK: - Setup

    @MainActor
    private static func setupScene(_ id: String) -> AnyView? {
        let (step, state): (AssistantSetupStep, AssistantState)
        switch id {
        case "setup-1": (step, state) = (.assistant, .off)
        case "setup-2": (step, state) = (.server, .off)
        case "setup-3": (step, state) = (.snippet, .pairing)
        case "setup-4": (step, state) = (.test, .waiting)
        case "setup-done": (step, state) = (.test, .pairedNow)
        default: return nil
        }
        AssistantSetupSheet.debugStep = step
        let scene = DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store(includesAssistant: false), presentedSheet: .assistantSetup)
        return with(state, scene)
    }

    // MARK: - Store Page

    @MainActor
    private static func storePageScene(_ id: String) -> AnyView? {
        switch id {
        case "sp-builtin": storePage(.off, store: SuggestionsDebugData.store(includesAssistant: false)) { $0.openEditor(.englishUS) }
        case "sp-cc": storePage(.connected) { $0.openEditor(.englishUS) }
        case "sp-ask":
            storePage(.connected) { model in
                model.openEditor(.englishUS)
                model.requestsAsk = true
            }
        case "sp-streaming": storePage(.working, store: SuggestionsDebugData.streamingStore()) { $0.openEditor(.englishUS) }
        case "sp-de": storePage(.connected) { $0.openEditor(.german) }
        case "sp-ja": storePage(.connected) { $0.openEditor(.japanese) }
        default: decidedScene(id)
        }
    }

    /// After deciding: What's New accepted and the subtitle dismissed, or
    /// the promotional text taken with Use and Edit.
    @MainActor
    private static func decidedScene(_ id: String) -> AnyView? {
        switch id {
        case "sp-accepted":
            storePage(.connected) { model in
                model.openEditor(.englishUS)
                if let whatsNew = model.shownSuggestion(.whatsNew, in: .englishUS) { model.acceptSuggestion(whatsNew) }
                if let subtitle = model.shownSuggestion(.subtitle, in: .englishUS) { model.dismissSuggestion(subtitle) }
            }
        case "sp-edit":
            storePage(.connected) { model in
                model.openEditor(.englishUS)
                if let promotional = model.shownSuggestion(.promotionalText, in: .englishUS) { model.useAndEditSuggestion(promotional) }
            }
        default:
            nil
        }
    }

    @MainActor
    static func storePage(
        _ state: AssistantState,
        store: FieldSuggestionStore = SuggestionsDebugData.store(),
        opening: @escaping @MainActor (StorePageViewModel) async -> Void
    ) -> AnyView {
        var storePage = DebugStorePageServices()
        storePage.opening = DebugStorePageServices.Opening(opening)
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return with(state, DebugMainScene(services: services, section: .storePage, suggestions: store))
    }

    // MARK: - App Information

    @MainActor
    static func appInformationScene(
        page: AppInformationPage,
        state: AssistantState = .connected,
        store: FieldSuggestionStore = SuggestionsDebugData.store(),
        opening: @escaping @MainActor (AppInformationViewModel) async -> Void = { _ in }
    ) -> AnyView {
        var appInformation = DebugAppInformationServices()
        appInformation.hasOutdatedDetails = true
        appInformation.opening = DebugAppInformationServices.Opening { model in
            model.page = page
            await opening(model)
        }
        var services = WorkspaceServices.debug
        services.appInformation = appInformation
        return with(state, DebugMainScene(services: services, section: .appInformation, suggestions: store))
    }

    // MARK: - Assistants

    /// How far the person's own assistant is set up in a scene.
    enum AssistantState {
        case off
        /// The server is on and Claude Code chosen; the command isn't
        /// copied yet.
        case pairing
        /// The command was copied; no call yet.
        case waiting
        /// Claude Code just made its first call.
        case pairedNow
        /// Claude Code has called before.
        case connected
        /// Connected, and sending suggestions now.
        case working
    }

    @MainActor
    static func with(_ state: AssistantState, _ content: some View) -> AnyView {
        AnyView(content.modifier(Assistants(state: state)))
    }

    /// Puts the MCP server in `state` once the scene appears.
    private struct Assistants: ViewModifier {
        let state: AssistantState
        @Environment(MCPServerController.self) private var assistants

        func body(content: Content) -> some View {
            content.task { apply() }
        }

        private func apply() {
            switch state {
            case .off:
                break
            case .pairing:
                assistants.setEnabled(true)
                assistants.beginPairing(kind: .claudeCode)
            case .waiting:
                AssistantsDebugState.pairing.apply(to: assistants)
            case .pairedNow:
                AssistantsDebugState.pairing.apply(to: assistants)
                var client = AssistantsDebugState.claudeCode
                client.id = assistants.pendingPairing?.clientID ?? client.id
                client.lastSeenAt = .now
                assistants.pendingPairing?.connectedClient = client
            case .connected, .working:
                AssistantsDebugState.paired.apply(to: assistants)
                if state == .working { assistants.noteWorking(client: SuggestionsDebugData.client, for: .seconds(24 * 60 * 60)) }
            }
        }
    }
}
#endif
